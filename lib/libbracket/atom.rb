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
      super
      @name = params[:name]
    end
    
    def self.from_name_and_domain(name, domain)
      #XXX registry as a safety feature
      Term.construct Atom, domain, nil, { :name => name }
    end
    
    def render(rctxt)
      return @name
    end
  end
end