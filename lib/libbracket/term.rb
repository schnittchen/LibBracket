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
      
      #Term objects are instantiated into a cache. Term#construct clones (see initialize_copy) from this cache
      #and uses provide_contents to fill the missing data from cdren and params.
      def construct(prim, dom, cdren = nil, params = {})
        bp = CACHE_[[prim, dom]]
        result = bp.clone
        result.provide_contents cdren, params
        return result
      end
    end
    
    #Term objects are initialized with primitive and domain. Both are modules which are
    #extended into the new term object, in that order. After that, init_primitive, init_domain
    #and init_after_domain (in that order) have the chance for modifications before the term object is cached
    #(see construct). They may push CanonicalizationFragment objects onto @cstack, the CanonicalizationStack
    #object for the term.
    def initialize(prim, dom)
      @primitive, @domain = prim, dom
      extend dom
      extend prim
      
      @cstack = CanonicalizationStack.new
      init_primitive
      init_domain
      init_after_domain
    end
    
    #clones the CanonicalizationStack @cstack from other
    def initialize_copy(other)
      @cstack = other.cstack.clone
    end
    
    #Primitives may push CanonicalizationFragment objects onto @cstack in here (override this in your primitive module).
    def init_primitive
    end
    
    #Domains may push CanonicalizationFragment objects onto @cstack in here (override this in your domain module).
    def init_domain
    end
    
    #Primitives may push CanonicalizationFragment objects onto @cstack in here (override this in your primitive module).
    #This would refine canonicalization of the term on top of the domain level.
    def init_after_domain
    end

    #Called by Term.construct after cloning a term object from the cache. Initializes
    #@children and other cached data. Override this method in your primitive module
    #to set @chash (don't forget to call super!).
    def provide_contents(cdren, params)
      @replacement_cookie = KnowledgeBase.virgin_cookie
      @children = cdren if cdren
    end
    
    ##make term objects comparable and good hash keys
    
    include Comparable
    alias_method :eql?, :== #used by hash lookup!
    
    def <=>(other)
      return @chash <=> other.chash
    end
    
    def hash
      return @chash.hash
    end
    
    #Used inside to_canonical_replaced? to determine if a term with canonical children
    #is at a canonical state. Both PrimitiveWithChildren and PrimitiveWithoutChildren provide this.
    virtual :canonical?
    #Construct a new term like the current, but with all children replaced with the result
    #of to_canonical_replaced?.
    #returns [newterm, replaced] where replaced is true iff any to_canonical_replaced? call
    #signaled that replacement happened.
    virtual :send_tcr_to_children
    
    def canonicalize_and_replace
      term, replaced = to_canonical_replaced?
      return term
    end
    
    #Canonicalization steps must not themselves call to_canonical_replaced?, otherwise the logic
    #breaks. This global flag is used to detect this and report the problem.
    @@must_not_replace = false
    
    #Apply the canonicalization and replacement algorithm to term. Returns [either self or a new term, flag] where
    #flag signals whether replacement has happened anywhere inside. This information is needed by the recursive algorith itself.
    def to_canonical_replaced?
      #detailed reason: to_canonical_replaced? might do KnowledgeBase replacements somewhere deep inside,
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
    
    include OperatorBinding::ContextEnumerations
    
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