#!/usr/bin/env ruby

require 'transmembrane'
include Transmembrane
require 'tempfile'
require 'rubygems'
gem 'rio'
require 'rio'

module Bio
  class Spoctopus
    class Wrapper
      DEFAULT_BLASTDB_PATH = '/blastdb/UniProt15/uniprot_sprot.fasta'

      TMP_SEQUENCE_NAME = 'wrapperSeq'

      def calculate(sequence)
        # Remove stop codons, as these mess things up for the predictor
        sequence.gsub!('*','')


        rio(:tempdir) do |d| # Do all the work in a temporary directory
          FileUtils.cd(d.to_s) do
          
            # Create the input files
            # * the names file (in base directory)
            # * the fasta file with the sequence in it (in fasta directory)
            # * output file directory

            names = File.open('names','w')
            names.puts TMP_SEQUENCE_NAME
            names.close

            Dir.mkdir 'fasta'
            fastafile = File.open("fasta/#{TMP_SEQUENCE_NAME}.fa", 'w')
            fastafile.puts '>wrapperSeq'
            fastafile.puts "#{sequence}"
            fastafile.close

            Dir.mkdir 'tmd'

            # First, run BLOCTOPUS to create the profiles
            #
            # ben@ben:~/bioinfo/spoctopus$ ./BLOCTOPUS.sh /tmp/spoctopus/names /tmp/spoctopus/fa
            # /tmp/spoctopus/tmd blastall blastpgp`
            # /blastdb/UniProt15/uniprot_sprot.fasta makemat -P
            Tempfile.open('octopuserr') do |err|
              result = system [
                'BLOCTOPUS.sh',
                "#{Dir.pwd}/names",
                "#{Dir.pwd}/fasta",
                "#{Dir.pwd}/tmd",
                'blastall',
                'blastpgp',
                DEFAULT_BLASTDB_PATH,
                'makemat',
                '-P',
                '>/dev/null' # SPOCTOPUS doesn't understand the concept of STDERR
                #                "2>#{err.path}"
              ].join(' ')

              if !result
                raise Exception, "Running BLOCTOPUS program failed. $? was #{$?.inspect}. STDERR was #{err.read}"
              end
            end

            # Now run SPOCTOPUS to do the actual prediction of SP and TMD,
            # given the profile.
            # ./SPOCTOPUS.sh /tmp/spoctopus/names
            # /tmp/spoctopus/tmd/PSSM_PRF_FILES/
            # /tmp/spoctopus/tmd/RAW_PRF_FILES/
            # /tmp/spoctopus/tmd/
            Tempfile.open('octopuserr') do |err|
              result = system [
                'SPOCTOPUS.sh',
                "#{Dir.pwd}/names",
                "#{Dir.pwd}/tmd/PSSM_PRF_FILES/",
                "#{Dir.pwd}/tmd/RAW_PRF_FILES/",
                "#{Dir.pwd}/tmd/",
                '>/dev/null' # SPOCTOPUS doesn't understand the concept of STDERR
                #                "2>#{err.path}"
              ].join(' ')

              if !result
                raise Exception, "Running SPOCTOPUS program failed. $? was #{$?.inspect}. STDERR was #{err.read}"
              end
            end
            
            return Result.create_from_output(File.open("tmd/#{TMP_SEQUENCE_NAME}.top").read)
          end
        end
      end
    end
    
    class Result
      # Given the fasta-ish file output from spoctopus, parse it into
      # a SignalPeptideTransmembraneDomainProtein.
      #
      # Example without TMD:
      # >wrapperSeq
      # gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
      # ggggggggggggggggggggggggggggggggggggg
      #
      # Example with 2 TMD
      # >wrapperSeq
      # iiiiiiiiiiMMMMMMMMMMMMMMMMMMMMMooooooooooooooooooooooooooooo
      # ooooMMMMMMMMMMMMMMMMMMMMMiiiiiMMMMMMMMMMMMMMMMMMMMMo
      #
      # Example with SP and TMD
      # >wrapperSeq
      # nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnSSSSSSSSSSSSSSSooooooooooooooo
      # ooooooooooooooooooooooooooooooooooooo
      def self.create_from_output(spoctopus_output)
        # split the fasta into the real parts
        lines = spoctopus_output.split("\n")
        
        # Error checking
        unless lines[0].match(/^\>/) and lines.length > 1
          raise Exception, "Unexpected SPOCTOPUS output file: #{spoctopus_output.inspect}"
        end

        seq = lines[1..(lines.length-1)].join('')

        unless seq.match(/^[ioMgnS]+$/)
          raise Exception, "Unexpected characters in SPOCTOPUS output sequence: #{seq}"
        end

        tmd = SignalPeptideTransmembraneDomainProtein.new

        # deal with nothing proteins
        return tmd if seq.match(/^g*$/)
        $stderr.puts spoctopus_output

        seq.scan(/S+/) do
          if tmd.signal?
            raise Exception, "Only 1 Signal Peptide is expected!. SPOCTOPUS output was #{seq}"
          end

          s = SignalPeptide.new
          s.start = $~.offset(0)[0]+1
          s.stop = $~.offset(0)[1]
          tmd.signal_peptide = s
        end

        seq.scan(/M+/) do # for each transmembrane domain
          t = OrientedTransmembraneDomain.new
          t.start = $~.offset(0)[0]+1
          t.stop = $~.offset(0)[1]

          # set orientation
          # if at the start of the protein it is harder
          if t.start == 1
            if t.stop == seq.length #all TMD, so we don't know
              t.orientation = OrientedTransmembraneDomain::UNKNOWN
            else
              char = seq[t.stop-2..t.stop-2]
              if char == 'o'
                t.orientation = OrientedTransmembraneDomain::INSIDE_OUT
              else
                t.orientation = OrientedTransmembraneDomain::OUTSIDE_IN
              end
            end

          else # usual - TMD does not start at exactly the beginning
            char = seq[t.start-2..t.start-2]
            if char == 'i'
              t.orientation = OrientedTransmembraneDomain::INSIDE_OUT
            else
              t.orientation = OrientedTransmembraneDomain::OUTSIDE_IN
            end
          end

          tmd.transmembrane_domains.push t
        end

        return tmd
      end
    end
  end
end


# If being run directly instead of being require'd,
# output one transmembrane per line, and
# indicate that a particular protein has no transmembrane domain
if $0 == __FILE__
  require 'bio'

  runner = Bio::Spoctopus::Wrapper.new

  Bio::FlatFile.auto(ARGF).each do |seq|
    result = runner.calculate(seq.seq)
    name = seq.definition

    if result.has_domain?
      # At least one TMD found. Output each on a separate line
      result.transmembrane_domains.each do |tmd|
        puts [
          name,
          result.transmembrane_type,
          tmd.start,
          tmd.stop,
          tmd.orientation
        ].join("\t")
      end
    else
      puts [
        name,
        'No Transmembrane Domain Found'
      ].join("\t")
    end
  end
end