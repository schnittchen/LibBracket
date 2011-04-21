module LibBracket
  
  class Term
    include Virtual
    
    attr_reader :domain, :chash, :replacement_cookie
    
    def self.ancestors_after_term
      ancestors.take_while do |mod|
        mod != Term
      end.reverse
    end
    
    def initialize(domain)
      @domain = domain #sometimes needed for chash calculation
      @chash = CHash.new *chash_ctor_args
      @replacement_cookie = KnowledgeBase.virgin_cookie
      
      extend domain if domain
      
      self.class.ancestors_after_term.each do |mod|
        extend mod.const_get "SpecificMethods" if mod.const_defined? "SpecificMethods"
      end
    end
    
    #effective term value changed: reset some internal state
    def value_changed
      @replacement_cookie = KnowledgeBase.virgin_cookie #reset cookie
      @chash = CHash.new *chash_ctor_args
    end
    
    virtual :chash_ctor_args
    
    include Comparable
    alias_method :eql?, :== #used by hash lookup!
    
    def <=>(other)
      return @chash <=> other.chash
    end
    
    def hash
      return @chash.hash
    end
    
    virtual :canonical?
    virtual :canonicalization_advance #will only be called on term if not canonical?
    
    def canonicalize_and_replace
      term, replaced = to_canonical_replaced?
      return term
    end
    
    #returns [newterm, replaced flag].
    #This is the base implementation for the case of absence of children.
    def send_tcr_to_children
      return [nil, false]
    end
    
    @@must_not_replace = false #global flag to abort if logic error:
    #steps on a canonicalization stack must never call to_canonical_replaced
    
    #return values: [term, true or false]
    def to_canonical_replaced?
      #reason for this: to_canonical_replaced? might do KnowledgeBase replacements somewhere deep inside,
      #but this breaks with an optimization: we save terms produced by a canonicalization step on the
      #term-wise canonicalization stack. Terms saved there must not have gone through a KnowledgeBase
      #replacement.
      raise "A canonicalization step of a term must never call :to_canonical_replaced" if @@must_not_replace
      
      #do not traverse tree if not necessary
      return [self, false] if canonical? and KnowledgeBase.superseeds_cookie @replacement_cookie

      replaced = false
      current = self
      while true
        term, rep = current.send_tcr_to_children
        if term
          replaced |= rep
          current = term
        end
        
        if !current.canonical?
          begin
            @@must_not_replace = true #see beginning of method
            term = current.canonicalization_stack.work do |msym|
              current.__send__ msym
              #work will record a term result. this is now safe because we can be sure t_c_r? will
              #never be called inside, no replacement can have happened!
            end
          ensure
            @@must_not_replace = false
          end
          
          if term
            current = term
            next
          end
        end
        
        
        cookie = current.replacement_cookie
        return [current, replaced]  if KnowledgeBase.superseeds_cookie cookie
        term = KnowledgeBase.replacement_for current
        if term
          replaced = true
          current = term
        else
          KnowledgeBase.merge_cookie cookie #mark term as having survived replacements
          return [current, replaced]
        end
      end
    end
    
    include OperatorBinding::ContextEnumerations
    
    virtual :render
    
    def to_s
      render IN_BRACKETS
    end
  end
end