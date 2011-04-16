require 'term'
require 'chash'

module LibBracket
  class NonCompositeTerm < Term
    virtual :chash_realm
    virtual :chash_attributes
    
    def chash_ctor_args
      return [chash_realm, chash_attributes, nil]
    end
    
    def canonical?
      true
    end
  end
  
  class Atom < NonCompositeTerm
    CHash.register_realm self #in accordance with chash_realm base definition
    
    attr_reader :name
    
    def initialize(domain, name)
      @name = name #need to set this first!
      super domain
    end
    
    def chash_realm
      Atom
    end
    
    def chash_attributes
      return [@name]
    end
    
    @registry = []
    
    class << self
      def from_domain_and_name(domain, name)
        #XXX move this check into initialize!
        raise "Already have an atom by that name" if @registry.include? name
        @registry << name
        new domain, name
      end
    end
    
    def render(rctxt)
      return @name
    end
  end
end