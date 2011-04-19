module LibBracket  
  class KnowledgeBase < Hash
    #introduce a replacement rule
    def replacing(term, repterm)
      cterm = KnowledgeBase.without_any { term.canonicalize_and_replace }
      raise "Term to replace must be canonical!" unless term == cterm
      store cterm, repterm
      return self
    end
    
    alias_method :replacement_for, :[]
    
    EMPTY = new.freeze
    
    @stack = []
    @replacement_override = nil
    
    def self.replacement_for(term)
      raise "Term to be replaced must be canonical!" unless term.canonical?
      
      effective_bases.each do |base|
        rep = base.replacement_for term
        return rep if rep #XXX ensure other bases would replace to the same!
      end
      return nil
    end
    
    def self.with(base)
      base.freeze #needed for cookie's meaning to persist
      begin
        @stack.push base
        yield #pass return value through
      ensure
        @stack.pop
      end
    end
    
    def self.without_any
      begin
        previous_override, @replacement_override = @replacement_override, EMPTY
        yield #pass return value through
      ensure
        @replacement_override = previous_override
      end
    end
    
    def self.replacing(term, repterm)
      base = new
      base.replacing term, repterm
      begin
        previous_override, @replacement_override = @replacement_override, base
        yield #pass return value through
      ensure
        @replacement_override = previous_override
      end
    end
    
    #cookie interface
    
    def self.superseeds_cookie(cookie)
      effective_bases.collect do |base|
        base.object_id
      end.all? { |id| cookie.include? id }
    end
    
    #(mark term as canonicalized w.r.t. current effective bases)
    #Merge current effective knowledgebases cookie with cookie (changes cookie)
    def self.merge_cookie(cookie)
      cookie.replace cookie | effective_bases.collect { |base| base.object_id }
    end
    
    def self.effective_bases
      if @replacement_override
        return [] if @replacement_override.empty? #avoid overhead, especially marking with merge_cookie
        return [@replacement_override]
      end
      return @stack
    end
    
    def self.virgin_cookie
      return []
    end
  end
end