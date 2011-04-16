module LibBracket
  
  class Term
    include Virtual
    
    attr_reader :domain, :chash, :replacement_cookie
    
    def initialize(domain)
      @domain = domain #sometimes needed for chash calculation
      @chash = CHash.new *chash_ctor_args
      @replacement_cookie = KnowledgeBase.virgin_cookie
      
      extend domain if domain
      
      self.class.ancestors.take_while do |mod|
        mod != Term
      end.reverse.each do |mod|
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
    
    def <=>(other)
      return @chash <=> other.chash
    end
    
    def hash
      return @chash.hash
    end
    
    virtual :canonical?
    virtual :canonicalization_advance #will only be called on term if not canonical?
    
    def canonicalize_and_replace
      term = self
      loop do
        if term.canonical?
          cookie = term.replacement_cookie
          return term if KnowledgeBase.superseeds_cookie cookie
          replaced = KnowledgeBase.replacement_for term
          if replaced
            term = replaced
          else
            KnowledgeBase.merge_cookie cookie #mark term as having survived replacements
            return term
          end
        else
          term = term.canonicalization_advance
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