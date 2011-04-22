module LibBracket
  module Zero
    include PrimitiveWithoutChildren
    
    CHash.register_realm self
    
    def chash_realm
      Zero
    end
    
    def chash_attributes
      return [@domain.to_s]
    end
    
    def self.for_domain(dom)
      Term.construct Zero, dom
    end
    
    def init_value
      super
      extend ValueMethods
    end
    
    module ValueMethods
      def zero?
        true
      end
    end
    
    def render(ctxt)
      return "0"
    end
  end
  
  module Sum
    include PrimitiveWithChildren
    
    #cdren must not be empty
    def self.from_children(cdren)
      raise "Sum needs at least one summand!" if cdren.empty?
      return Term.construct Sum, cdren[0].domain, cdren
    end
    
    def self.from_summands(*summands)
      return from_children ChildrenArray.new.replace(summands)
    end
    
    CFRAGMENT = CanonicalizationFragment.new
    CFRAGMENT.declare_step :cmerge_sums
    CFRAGMENT.declare_step :cfilter_and_sort
    
    def init_primitive
      @cstack << CFRAGMENT
    end
    
    def cmerge_sums
      new_children = ChildrenArray.new
      unchanged = true
      @children.each do |child|
        if child.is_a? Sum
          unchanged = false
          new_children += child.children
        else
          new_children << child
        end
      end
      return nil if unchanged
      return Sum.from_children new_children
    end
    
    def cfilter_and_sort
      new_children = @children.sort.reject &:zero?
      return nil if new_children.length >= 2 && new_children == @children
      
      case new_children.length
      when 0
        return @domain::ZERO 
      when 1
        return new_children[0]
      else
        return Sum.from_children ChildrenArray.new.replace(new_children)
      end
    end
    
    def render(rctxt)
      return super unless @children.length >= 2
      inner = @children.collect { |child| child.render PLUS }
      return OperatorBinding.bracket_if_needed inner.join(" + "), rctxt, PLUS
    end
  end
  
  module IsSummable
    include Domain
    
    def zero?
      false
    end
    
    def +(other)
      return Sum.from_summands self, other
    end
    
    module DomainMethods
      #construct Zero term as late as possible:
      #domain module might include more modules after IsSummable, these would not be available
      #for Zero.for_domain at IsSummable.included run time
      def const_missing(sym)
        return super unless sym == :ZERO
        const_set :ZERO, Zero.for_domain(self)
      end
    end
    
    def self.included(mod)
      mod.extend DomainMethods
    end
  end
end