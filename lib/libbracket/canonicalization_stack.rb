module LibBracket
  class CanonicalizationFragment < Array
    alias_method :declare_step, :<<
    
    def method_list
      freeze #avoid bugs: do you really want to modify
      #a fragment after it has been used for the first time?
      return self
    end
  end
  
  class CanonicalizationStack < Array
    #item types on this stack:
    # * CanonicalizationFragment objects
    # * term objects (== STOP canonicalizing _this_ term, take object instead)
    # * symbol (method)
    #no more item on the stack: canonical!
    
    alias_method :canonical?, :empty?
    
    #process stack, yielding method symbols to block, until
    #block returns a term or the stack is exhausted.
    #If block returns a term, prepare stack for bahaving exactly the same in the future,
    #and return that term.
    #Return nil if stack is exhausted.
    def work # { |msym| term.__send__ msym }
      until empty?
        while first.is_a? CanonicalizationFragment
          f = shift
          replace f.method_list + self
        end
        
        case nxt = first
        when Term
          return nxt
        when Symbol
          shift
          newterm = yield nxt
          if newterm
            unshift newterm
            return newterm
          end
        when NilClass
          #drop out
        else
          raise "bam!" #you found a bug.
        end
      end
      return nil
    end
  end
end