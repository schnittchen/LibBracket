require 'libbracket/is_summable'

module LibBracket
  module One
    include PrimitiveWithoutChildren
    
    CHash.register_realm self

    def chash_realm
      One
    end
    
    def chash_attributes
      return [@domain.to_s]
    end
    
    def self.for_domain(dom)
      Term.construct One, dom
    end
    
    def init_after_domain
      super
      extend MethodsAfterDomain
    end
    
    module MethodsAfterDomain
      def one?
        true
      end
    end
    
    def render(ctxt)
      return "1"
    end
  end
  
  module Product
    include PrimitiveWithChildren
    
    def self.from_children(cdren)
      raise "Product needs at least one factor!" if cdren.empty?
      return Term.construct Product, cdren[0].domain, cdren
    end
    
    def self.from_factors(*factors)
      raise "Need at least one factor" if factors.empty?
      return from_children ChildrenArray.new.replace(factors)
    end
    
    CFRAGMENT = CanonicalizationFragment.new
    CFRAGMENT.declare_step :cdistribute
    CFRAGMENT.declare_step :cmerge_products
    CFRAGMENT.declare_step :cfilter_and_sort
    
    def init_primitive
      @cstack << CFRAGMENT
    end
    
    def cdistribute
      @children.each_with_index do |child, idx|
        if child.is_a? Sum
          summands = child.children.collect do |summand|
            factors = @children[0...idx] << summand
            factors += @children[idx+1..-1]
            Product.from_children ChildrenArray.new.replace(factors)
          end
          return Sum.from_summands *summands
        end
      end
      return nil
    end
    
    def cmerge_products
      new_children = ChildrenArray.new
      unchanged = true
      @children.each do |child|
        if child.is_a? Product
          unchanged = false
          new_children += child.children
        else
          new_children << child
        end
      end
      return nil if unchanged
      return Product.from_children new_children
    end
    
    def cfilter_and_sort
      return @domain::ZERO if @children.any? &:zero?
      new_children = @children.reject &:one?
      case new_children.length
      when 0
        return @domain::ONE
      when 1
        return new_children[0]
      else
        new_children.sort! if @domain.multiplication_commutes?
        return nil if new_children == @children
        return Product.from_children ChildrenArray.new.replace(new_children)
      end
    end
    
    include OperatorBinding::ContextEnumerations
    
    def render(rctxt)
      return super unless @children.length >= 2
      inner = @children.collect { |child| child.render MUL }
      return OperatorBinding.bracket_if_needed inner.join("*"), rctxt, MUL
    end
  end
  
  module IsMultipliable
    def one?
      false
    end
    
    def *(other)
      return Product.from_factors self, other
    end
    
    module DomainMethods
      #return false as the default,
      #include MultiplicationCommutes after IsMultipliable if not desired
      def multiplication_commutes?
        false
      end
      
      #construct One term as late as possible:
      #domain module might include more modules after IsMultipliable, these would not be available
      #for One.for_domain at IsMultipliable.included run time
      def const_missing(sym)
        return super unless sym == :ONE
        const_set :ONE, One.for_domain(self)
      end
    end
    
    def self.included(mod)
      mod.extend DomainMethods
    end
  end
  
  #include into IsMultipliable domain if multiplication is supposed to commute
  module MultiplicationCommutes
    def self.included(mod)
      def mod.multiplication_commutes?
        true
      end
    end
  end
end