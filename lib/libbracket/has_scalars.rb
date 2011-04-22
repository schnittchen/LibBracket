require 'libbracket/is_summable'

module LibBracket
  module ScalarMultiple
    include PrimitiveWithChildren
    
    def self.from_scalar_and_other(scalar, other)
      h = { :scalar => scalar, :other => other }
      return Term.construct ScalarMultiple, other.domain, ChildrenHash.new.replace(h)
    end
    
    def scalar
      @children[:scalar]
    end
    
    def other
      @children[:other]
    end
    
    CFRAGMENT = CanonicalizationFragment.new
    CFRAGMENT.declare_step :cdistribute_scalar
    CFRAGMENT.declare_step :cdistribute_other
    CFRAGMENT.declare_step :cmerge_multiples
    CFRAGMENT.declare_step :ccheck_one_and_zero
    
    def cdistribute_scalar
      s, o = scalar, other
      return nil unless s.is_a? Sum
      summands = s.children.collect { |term| ScalarMultiple.from_scalar_and_other term, o }
      return Sum.from_summands *summands
    end
    
    def cdistribute_other
      s, o = scalar, other
      return nil unless o.is_a? Sum
      summands = o.children.collect { |term| ScalarMultiple.from_scalar_and_other s, term }
      return Sum.from_summands *summands
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
      inner = [other.render MUL, scalar.render MUL]
      inner.reverse! if @domain.include? HasScalarsFromRight
      return OperatorBinding.bracket_if_needed inner.join("*"), rctxt, MUL
    end
  end
    
  module HasScalars
    
    
    def scalar_multiple(scalar)
      return ScalarMultiple.from_scalar_and_other scalar, self
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
      return ScalarMultiple.from_scalar_and_other scalar, self
    end
  end
end