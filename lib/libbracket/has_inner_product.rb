module LibBracket
  class InnerProduct < CompositeTerm
    include LinearChild
    
    def self.from_domain_and_terms(domain, left, right)
      cdren = ChildrenHash.new.replace({ :left => left, :right => right })
      new domain, cdren
    end
    
    STATE_LEFT_TREATED = :state_left_treated
    STATE_RIGHT_TREATED = :state_right_treated
    STATE_ORDERED = :state_ordered
    
    canonicalize_children_first
    next_cstep :ctreat_left, STATE_LEFT_TREATED
    next_cstep :ctreat_right, STATE_RIGHT_TREATED
    next_cstep :corder, STATE_ORDERED
    canonical_at STATE_ORDERED
    
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
      return clone_with_children cdren
    end
    
    def render(rctxt)
      left, right = @children[:left], @children[:right]
      return "<#{left.render IN_BRACKETS}, #{right.render IN_BRACKETS}>"
    end
  end
  
  module HasInnerProduct
    def inner_product_with(term)
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