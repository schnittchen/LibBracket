module LibBracket  
  class KnowledgeBase < Hash
    #introduce a replacement rule
    def replacing(term, repterm)
      raise "Term to replace must be canonical!" unless term.canonical?
      store can, repterm
    end
    
    alias_method :replacement_for, :fetch
    
    @current_bases = []
    
    def self.replacement_for(term)
      raise "Term to be replaced must be canonical!" unless term.canonical?
      @current_bases.each do |base|
        rep = base.replacement_for term
        return rep if rep
      end
      return nil
    end
    
    def self.with(base)
      base.freeze #needed for cookie's meaning to persist
      begin
        @current_bases.push base
        yield #we pass return value through
      ensure
        @current_bases.pop
      end
    end
    
    #cookie interface
    
    def self.superseeds_cookie(cookie)
      @current_bases.collect do |base|
        base.object_id
      end.all? { |id| cookie.include? id }
    end
    
    def self.merge_cookie(cookie)
      cookie.replace cookie | collect { |base| base.object_id }
    end
    
    def self.virgin_cookie
      return []
    end
  end
end