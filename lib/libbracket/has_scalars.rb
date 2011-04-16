require 'is_summable'
require 'is_multipliable'

module LibBracket
  class ScalarMultiple < CompositeTerm
    def initialize(scalar, other)
      h = { :scalar => scalar, :other => other }
      super other.domain, ChildrenHash.new.replace(h)
    end
    
    def self.from_scalar_and_other(scalar, other)
      new scalar, other
    end
    
    def scalar
      @children[:scalar]
    end
    
    def other
      @children[:other]
    end
    
    STATE_SCALAR_DISTRIBUTED = :state_scalar_distributed
    STATE_OTHER_DISTRIBUTED = :state_other_distributed
    STATE_MULTIPLES_MERGED = :state_multiples_merged
    STATE_ONE_AND_ZERO_CHECKED = :state_one_and_zero_checked
    
    canonicalize_children_first
    next_cstep :cdistribute_scalar, STATE_SCALAR_DISTRIBUTED
    next_cstep :cdistribute_other, STATE_OTHER_DISTRIBUTED
    next_cstep :cmerge_multiples, STATE_MULTIPLES_MERGED
    next_cstep :ccheck_one_and_zero, STATE_ONE_AND_ZERO_CHECKED
    canonical_at STATE_ONE_AND_ZERO_CHECKED
    
    def cdistribute_scalar
      s, o = scalar, other
      return nil unless s.is_a? Sum
      summands = s.children.collect { |term| ScalarMultiple.new term, o }
      return Sum.new *summands
    end
    
    def cdistribute_other
      s, o = scalar, other
      return nil unless o.is_a? Sum
      summands = o.children.collect { |term| ScalarMultiple.new s, term }
      return Sum.new *summands
    end
    
    def cmerge_multiples
      s, o = scalar, other
      return nil unless o.is_a? ScalarMultiple

      if @domain.include? HasScalarsFromRight
        return ScalarMultiple.from_scalar_and_other(o.scalar * s, o.other)
      else
        return ScalarMultiple.from_scalar_and_other(s * o.scalar, o.other)
      end
    end
    
    def ccheck_one_and_zero
      s, o = scalar, other
      return o.domain::ZERO if s.zero?
      return o if s.one?
      return o if o.zero?
      return nil
    end
    
    def render(rctxt)
      str = if @domain.include? HasScalarsFromRight
        "#{other.render MUL}*#{scalar.render MUL}"
      else
        "#{scalar.render MUL}*#{other.render MUL}"
      end
      return OperatorBinding.bracket_if_needed str, rctxt, MUL
    end
  end
  
  module HasScalars
    def scalar_multiple(scalar)
      return ScalarMultiple.new scalar, self
    end
  end
  
  module HasScalarsFromLeft
    include HasScalars
  end
  
  module HasScalarsFromRight
    include HasScalars
  end
  
  module ScalarMultipleOperator
    def *(scalar)
      return ScalarMultiple.new scalar, self
    end
  end
end