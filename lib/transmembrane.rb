# a simple class to represent a TMD

require 'array_pair'

module Transmembrane

  class TransmembraneProtein
    attr_accessor :transmembrane_domains, :name
    include Enumerable #so each, each_with_index, etc. work
  
    def initialize
      # default no domains to empty array not nil
      @transmembrane_domains = []
    end
  
    def push(transmembrane_domain)
      @transmembrane_domains.push transmembrane_domain
    end
  
    def average_length
      @transmembrane_domains.inject(0){|sum,cur| sum+cur.length}.to_f/@transmembrane_domains.length.to_f
    end
  
    def minimum_length
      @transmembrane_domains.min.length
    end
  
    def maximum_length
      @transmembrane_domains.max.length
    end
  
    def has_domain?
      !@transmembrane_domains.empty?
    end

    def multiple_transmembrane_domains?
      @transmembrane_domains.length > 1
    end

    def overlaps(another_transmembrane_protein)
      @transmembrane_domains.pairs(another_transmembrane_protein.transmembrane_domains).collect {|t1,t2|
        t1.intersection(t2) == () ? nil : [t1,t2]
      }.reject {|a| a.nil?}
    end

    # return the pair of transmembrane domains that overlaps the best (ie for the longest period)
    def best_overlap(another_transmembrane_protein)
      max = @transmembrane_domains.pairs(another_transmembrane_protein.transmembrane_domains).collect {|t1,t2|
        [t1.overlap_length(t2), [t1,t2]]
      }.max {|a,b| a[0] <=> b[0]}
      max[0] == 0 ? nil : max[1]
    end

    def each
      @transmembrane_domains.each{|t| yield t}
    end
  end
  
  class OrientedTransmembraneDomainProtein<TransmembraneProtein
    def transmembrane_type_1?
      @transmembrane_domains and @transmembrane_domains.length == 1 and @transmembrane_domains[0].orientation == OrientedTransmembraneDomain::OUTSIDE_IN
    end
    
    def transmembrane_type_2?
      @transmembrane_domains and @transmembrane_domains.length == 1 and @transmembrane_domains[0].orientation == OrientedTransmembraneDomain::INSIDE_OUT
    end
    
    def transmembrane_type
      if transmembrane_type_1?
        return 'I'
      elsif transmembrane_type_2?
        return 'II'
      else
        return 'Unknown'
      end
    end
  end

  class TransmembraneDomainDefinition
    attr_accessor :start, :stop
  
    # A new TMD. The length is stop-start+1, so start and stop are
    # 'inclusive'
    def initialize(start=nil, stop=nil)
      @start = start
      @stop = stop
    end

    def length
      @stop-@start+1
    end
  
    def <=>(other)
      length <=> other.length
    end
    
    def ==(other)
      start == other.start and
        stop == other.stop
    end
    
    def sequence(protein_sequence_string, nterm_offset=0, cterm_offset=0)
      one = start+nterm_offset-1
      one = 0 if one < 0
      two = stop+cterm_offset-1
      two = 0 if two < 0
      
      protein_sequence_string[(one)..(two)]
    end

    # Return the number of amino acids that overlap with another
    # transmembrane domain, or 0 if none are found
    def overlap_length(another_transmembrane_domain_defintion)
      intersection(another_transmembrane_domain_defintion).to_a.length
    end

    # Return a range representing the overlap of this transmembrane domain
    # with another
    #
    # Code inspired by http://billsiggelkow.com/2008/8/29/ruby-range-intersection
    def intersection(another_transmembrane_domain_defintion)
      res = (@start..@stop).to_a & (another_transmembrane_domain_defintion.start..another_transmembrane_domain_defintion.stop).to_a
      res.empty? ? nil : (res.first..res.last)
    end
    alias_method(:overlap, :intersection)
  end
  
  class ConfidencedTransmembraneDomain<TransmembraneDomainDefinition
    attr_accessor :confidence
    
    def <=>(other)
      return start<=>other.start if start<=>other.start
      return stop<=>other.start if stop<=>other.stop
      return confidence <=> other.confidence
    end
    
    def ==(other)
      start == other.start and
        stop == other.stop and
        confidence == other.confidence
    end
  end
  
  class OrientedTransmembraneDomain<TransmembraneDomainDefinition
    # The orientation can either be inside out (like a type II transmembrane domain protein)
    INSIDE_OUT = 'inside_out'
    # Or outside in, like a type I transmembrane domain protein)
    OUTSIDE_IN = 'outside_in'
    # or the whole protein is TMD, so orientation is unknown
    UNKNOWN = 'unknown'
    
    attr_accessor :orientation

    def initialize(start=nil, stop=nil, orientation=nil)
      @start = start.to_i unless start.nil?
      @stop = stop.to_i unless stop.nil?
      @orientation = orientation unless orientation.nil?
    end
  end

  # A class to represent a protein with a signal peptide and a transmembrane
  # domain
  class SignalPeptideTransmembraneDomainProtein<OrientedTransmembraneDomainProtein
    attr_accessor :signal_peptide

    def signal?
      !@signal_peptide.nil?
    end
  end

  class SignalPeptide
    attr_accessor :start, :stop
  end
end