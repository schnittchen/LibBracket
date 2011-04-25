module LibBracket
  module Atom
    include PrimitiveWithoutChildren
    
    CHash.register_realm self
    
    def chash_realm
      Atom
    end
    
    def chash_attributes
      return [@name]
    end
    
    def provide_contents(cdren, params)
      @name = params[:name]
      super
    end
    
    #Construct an atom with domain and name, but also giving a primitive (which
    #should include Atom). Thus it is possible to construct atoms with some
    #special behaviour.
    def self.from_primitive_and_domain_and_name(prim, dom, name)
      #XXX registry as a safety feature
      Term.construct prim, dom, nil, { :name => name }
    end
    
    def self.from_domain_and_name(domain, name)
      return from_primitive_and_domain_and_name Atom, domain, name
    end
    
    def render(rctxt)
      return @name
    end
  end
end