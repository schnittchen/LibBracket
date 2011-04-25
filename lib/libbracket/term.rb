module LibBracket
  
  class Term
    include Virtual
    
    attr_reader :domain, :primitive, :chash, :replacement_cookie, :cstack
    
    class << self
      private :new
      
      CACHE_ = Hash.new do |hsh, ky|
        prim, dom = ky
        hsh[ky] = Term.__send__ :new, prim, dom
      end
      
      def construct(prim, dom, cdren = nil, params = {})
        bp = CACHE_[[prim, dom]]
        result = bp.clone
        result.provide_contents cdren, params
        return result
      end
    end
    
    def initialize(prim, dom)
      @primitive, @domain = prim, dom
      extend dom
      extend prim
      
      @cstack = CanonicalizationStack.new
      init_primitive
      init_domain
      init_after_domain
    end
    
    def initialize_copy(other)
      @cstack = other.cstack.clone
    end
    
    def init_primitive
    end
    
    def init_domain
    end
    
    def init_after_domain
    end

    #override this method and set @chash!
    def provide_contents(cdren, params)
      @replacement_cookie = KnowledgeBase.virgin_cookie
      @children = cdren if cdren
    end
    
    include Comparable
    alias_method :eql?, :== #used by hash lookup!
    
    def <=>(other)
      return @chash <=> other.chash
    end
    
    def hash
      return @chash.hash
    end
    
    virtual :canonical?
    #returns [newterm, replaced flag].
    virtual :send_tcr_to_children
    
    def canonicalize_and_replace
      term, replaced = to_canonical_replaced?
      return term
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
            term = current.cstack.work do |msym|
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
    
    virtual :render
    
    def to_s
      render IN_BRACKETS
    end
  end
  
  module PrimitiveWithoutChildren
    include Virtual
    
    virtual :chash_realm
    virtual :chash_attributes
    
    def canonical?
      true
    end
    
    def send_tcr_to_children
      return [nil, false]
    end
    
    #when overriding, provide all data needed for chash_attributes
    #_before_ invoking this with super!
    def provide_contents(cdren, params)
      super
      @chash = CHash.new chash_realm, chash_attributes, nil
    end
  end
  
  module PrimitiveWithChildren
    CHash.register_realm self
    
    attr_reader :children
    
    def canonical?
      @cstack.canonical?
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
      return [Term.construct(@primitive, @domain, cdren), replaced]
    end
    
    def provide_contents(cdren, params)
      super
      @chash = CHash.new PrimitiveWithChildren, [primitive.to_s], cdren
    end
    
    #default implementation
    def render(rctxt)
      return "{#{@primitive}}" if @children.empty?
      inner = @children.clone.map! { |child| child.render IN_BRACKETS }
      inner = inner.to_a.collect { |k, v| "#{k} => #{v}" } if inner.is_a? ChildrenHash
      return "{#{@primitive} #{inner.join ", "}}"
    end
  end
end