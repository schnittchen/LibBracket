require 'atom'
require 'compositeterm'

module LibBracket
  class Zero < NonCompositeTerm
    CHash.register_realm self #in accordance with chash_realm base definition
    
    def chash_realm
      Zero
    end
    
    def chash_attributes
      return [@domain]
    end
    
    module SpecificMethods
      def zero?
        true
      end
    end
    
    def render(ctxt)
      return "0"
    end
  end
  
  class Sum < CompositeTerm
    def initialize(*summands)
      raise "Need at least one summand!" if summands.empty?
      super summands[0].domain, ChildrenArray.new.replace(summands)
    end
    
    STATE_SUMS_MERGED = :state_sums_merged
    STATE_FILTERED_AND_SORTED = :state_filtered_and_sorted
    
    canonicalize_children_first
    next_cstep :cmerge_sums, STATE_SUMS_MERGED
    next_cstep :cfilter_and_sort, STATE_FILTERED_AND_SORTED
    canonical_at STATE_FILTERED_AND_SORTED
    
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
      return clone_with_children new_children
    end
    
    def cfilter_and_sort
      new_children = @children.sort.reject { |term| term.zero? }
      return nil if new_children.length >= 2 && new_children == @children
      
      case new_children.length
      when 0
        return @domain::ZERO 
      when 1
        return new_children[0]
      else
        return clone_with_children ChildrenArray.new.replace(new_children)
      end
    end
    
    def render(rctxt)
      inner = @children.collect { |child| child.render PLUS }
      return OperatorBinding.bracket_if_needed inner.join(" + "), rctxt, PLUS
    end
  end
  
  module IsSummable
    def zero?
      false
    end
    
    def +(other)
      return Sum.new self, other
    end
    
    module DomainMethods
      #define ZERO as late as possible:
      #domain might include more modules which zero object wants as well
      def const_missing(sym)
        return super unless sym == :ZERO
        const_set :ZERO, Zero.new(self)
      end
    end
    
    def self.included(mod)
      mod.extend DomainMethods
    end
  end
end