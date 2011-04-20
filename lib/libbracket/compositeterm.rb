require 'libbracket/state_machine_stack'

module LibBracket
  class ChildrenArray < Array
    alias_method :ordered_values, :clone
    
    #XXX this is probably very incomplete.
    
    def +(*args)
      result = super
      return clone.replace result
    end
  end
  
  class ChildrenHash < Hash
    def ordered_values
      keys.sort_by do |obj|
        obj.to_s
      end.collect { |ky| fetch ky }
    end
    
    def map!
      keys.each do |ky|
        store ky, yield(fetch(ky))
      end
    end
  end
  
  #A term with children nodes and a canonicalization state machine
  class CompositeTerm < Term
    CHash.register_realm self
    
    attr_reader :children
    
    STATE_GENERAL = :state_general #initial state
    STATE_CANONICAL_CHILDREN = STATE_GENERAL #XXX quickfix
#    STATE_CANONICAL_CHILDREN = :state_canonical_children
    STATE_CANONICAL = :state_canonical
    
    attr_reader :canonicalization_stack
    
    def initialize(domain, children)
      @children = children #need to set this first!
      super domain
      @canonicalization_stack = compute_cstack
    end
    
    def primitive
      return self.class #reasonable default
    end
    
    def chash_ctor_args
      return [CompositeTerm, [primitive.to_s], @children]
    end
    
    def send_tcr_to_children
      cdren = @children.clone
      unchanged, replaced = true, false
      cdren.map! do |child|
        newchild, rep = child.to_canonical_replaced?
        if !newchild.equal? child
          unchanged = false
          replaced |= rep
        end
        newchild
      end
      return [nil, false] if unchanged
      return [clone_with_children(cdren), replaced]
    end
    
    def children=(cdren)
      @children = cdren
      value_changed
    end
    
    def value_changed
      super
      @canonicalization_stack = compute_cstack
    end
    
    def clone_with_children(children)
      result = clone
      result.children = children
      return result
    end
    
    def canonical?
      @canonicalization_stack.canonical?
    end
    
    def compute_cstack #XXX for now
      result = CanonicalizationStack.new
      result << compute_cfragment
    end
    
    def compute_cfragment #XXX for now
      #machine[machine[:__last_state]] = [msym, to_state]
      result = CanonicalizationFragment.new
      state = STATE_GENERAL
      machine = self.class._machine
      while (msym, to_state = machine[state]) and msym
        result.declare_step msym if msym
        state = to_state
      end
      return result
    end
    
    class << self
      #Usually, we begin with canonicalization.
      #Same as next_cstep :cchildren, STATE_CANONICAL_CHILDREN
      def canonicalize_children_first
        # next_cstep :cchildren, STATE_CANONICAL_CHILDREN #XXX disabled
      end
      
      def next_cstep(msym, to_state)
        machine = _machine
        machine[machine[:__last_state]] = [msym, to_state]
        machine[:__last_state] = to_state
      end
      
      def canonical_at(state)
        raise "Error in state machine declaration!" unless
        _machine.delete(:__last_state) == state
      end
      
      def _machine
        @machine ||= { :__last_state => STATE_GENERAL }
      end
    end
    
    def cchildren
      cdren = @children.clone
      unchanged = true
      cdren.map! do |child|
        newchild = child.canonicalize_and_replace
        unchanged = false unless newchild.equal? child
        newchild
      end
      return nil if unchanged
      return clone_with_children cdren
    end
  end
  
#   class ExampleCompositeTerm < CompositeTerm
#     def initialize(arg)
#       cdren = ChildrenArray.new.replace [child]
#       super SomeDomain, cdren
#     end
#
#     def primitive #if the default is not good enough for you
#       :some_primitive
#     end
#     
#     STATE_CANONICALIZED_FURTHER = :state_canonicalized_further
#     
#     canonicalize_children_first
#     next_cstep :ccanonicalize_further, STATE_CANONICALIZED_FURTHER
#     canonical_at STATE_CANONICALIZED_FURTHER
#     
#     def ccanonicalize_further
#       #either
#       return some_new_term
#       #or
#       return nil
#     end
#
#     def render(rctxt)
#       #return string
#     end
#   end
end
