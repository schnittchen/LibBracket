require 'libbracket/linear_child'

module LibBracket
  module InnerProduct
    include PrimitiveWithChildren
    include LinearChild
    
    def self.from_domain_and_children(domain, cdren)
      return Term.construct InnerProduct, domain, cdren
    end
    
    def self.from_domain_and_terms(domain, left, right)
      cdren = ChildrenHash.new.replace({ :left => left, :right => right })
      return from_domain_and_children domain, cdren
    end
    
    CFRAGMENT = CanonicalizationFragment.new
    CFRAGMENT.declare_step :ctreat_left
    CFRAGMENT.declare_step :ctreat_right
    CFRAGMENT.declare_step :corder
    
    def init_primitive
      @cstack << CFRAGMENT
    end
    
    def ctreat_left
      return treat_linear_child :left
    end
    
    def ctreat_right
      return treat_linear_child :right
    end
    
    def corder
      cdren = [:left, :right].zip @children.values.sort
      cdren = ChildrenHash.new.replace Hash[*cdren.reduce(:+)]
      return nil if cdren == @children
      return InnerProduct.from_domain_and_children @domain, cdren
    end

    def render(rctxt)
      inner = [:left, :right].collect { |key| @children[key].render IN_BRACKETS }
      return "<#{inner.join ", "}>"
    end
  end
  
  module HasInnerProduct
    def inner_product_with(term)
      #call domain_of_inner_product inside your domain module to have INNER_PRODUCT_DOMAIN defined
      return InnerProduct.from_domain_and_terms @domain::INNER_PRODUCT_DOMAIN, self, term
    end
    
    module DomainMethods
      def domain_of_inner_product(mod)
        const_set :INNER_PRODUCT_DOMAIN, mod
      end
    end
    
    def self.included(mod)
      mod.extend DomainMethods
    end
  end
end