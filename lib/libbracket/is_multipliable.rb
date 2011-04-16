module LibBracket
  class One < NonCompositeTerm
    CHash.register_realm self
    
    def chash_realm
      One
    end
    
    def chash_attributes
      return [@domain]
    end
    
    module SpecificMethods
      def one?
        true
      end
    end
    
    def render(ctxt)
      return "1"
    end
  end
  
  class Product < CompositeTerm
    def initialize(*factors)
      raise "Need at least one factor" if factors.empty?
      super factors[0].domain, ChildrenArray.new.replace(factors)
    end
    
    STATE_DISTRIBUTED = :state_distributed
    STATE_PRODUCTS_MERGED = :state_products_merged
    STATE_FILTERED_AND_SORTED = :state_filtered_and_sorted
    
    canonicalize_children_first
    next_cstep :cdistribute, STATE_DISTRIBUTED
    next_cstep :cmerge_products, STATE_PRODUCTS_MERGED
    next_cstep :cfilter_and_sort, STATE_FILTERED_AND_SORTED
    canonical_at STATE_FILTERED_AND_SORTED
    
    def cdistribute
      @children.each_with_index do |child, idx|
        if child.is_a? Sum
          summands = child.children.collect do |summand|
            factors = @children[0...idx] << summand
            factors += @children[idx+1..-1]
            clone_with_children ChildrenArray.new.replace(factors)
          end
          return Sum.new *summands
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
      return clone_with_children new_children
    end
    
    def cfilter_and_sort
      return @domain::ZERO if @children.any? { |child| child.zero? }
      new_children = @children.reject { |term| term.one? }
      case new_children.length
      when 0
        return @domain::ONE
      when 1
        return new_children[0]
      else
        new_children.sort! if @domain.multiplication_commutes?
        return nil if new_children == @children
        return clone_with_children ChildrenArray.new.replace(new_children)
      end
    end
    
    def render(rctxt)
      inner = @children.collect { |child| child.render MUL }
      return OperatorBinding.bracket_if_needed inner.join("*"), rctxt, MUL
    end
  end
  
  module IsMultipliable
    def one?
      false
    end
    
    def *(other)
      return Product.new self, other
    end
    
    module DomainMethods
      def multiplication_commutes?
        false
      end
      
      def const_missing(sym)
        return super unless sym == :ONE
        const_set :ONE, One.new(self)
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