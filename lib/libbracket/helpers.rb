module LibBracket
  
  module Virtual
    module ClassMethods
      def virtual(sym)
        self.send(:define_method, sym) do
          raise "virtual method called!"
        end
      end
    end
    
    def self.included(cls)
      cls.extend ClassMethods
    end
  end
  
  module OperatorBinding
    module ContextEnumerations
      IN_BRACKETS = :in_brackets
      PLUS = (:+)
      MUL = (:*)
    end
    
    include ContextEnumerations
    
    def self.bracket_if_needed(str, operator_context, operator)
      return str if operator_context == IN_BRACKETS
      return "(#{str})" if operator_context == operator or stronger?(operator_context, operator)
      return str
    end
    
    @strength = Hash.new { |h, k| h[k] = [] }
    
    def self.stronger?(op1, op2)
      @strength[op1].include? op2
    end
    
    def self.binds_stronger_than(op1, op2)
      @strength[op1] << op2
    end
    
    binds_stronger_than MUL, PLUS
  end
end