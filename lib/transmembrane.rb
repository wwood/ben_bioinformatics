# a simple class to represent a TMD

module Transmembrane

  class TransmembraneProtein
    attr_accessor :transmembrane_domains, :name
  
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