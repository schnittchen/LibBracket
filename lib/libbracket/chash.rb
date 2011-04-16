module LibBracket
  
  class CHash
    
    @@realms = []
    
    def self.register_realm(realm)
      raise "I already have that realm!" if @@realms.include? realm
      @@realms << realm
    end
    
    attr_reader :realmidx, :attributes, :children
    
    #Term object variants are organized into different realms.
    #Inside one realm, the attribute_ary must always be homogeneous and consist of
    #comparable and hashable objects. attribute_ary is owned by new object.
    #children can be nil, if not nil, it must return a new array of term objects
    #in response to :ordered_values
    def initialize(realm, attribute_ary, children)
      realm = @@realms.index realm
      raise "Using unregistered realm!" unless realm
      @realmidx, @attributes = realm, attribute_ary
      @children = children ? children.ordered_values : []
      freeze
    end
    
    def <=>(other)
      cmp = @realmidx <=> other.realmidx
      return cmp unless cmp.zero?
      
      @attributes.zip(other.attributes).each do |mine, others|
        cmp = mine <=> others
        return cmp unless cmp.zero?
      end
      
      otherchildren = other.children
      len = [@children.length, otherchildren.length].min
      @children[0...len].zip(otherchildren[0...len]).each do |mine, others|
        cmp = mine <=> others
        return cmp unless cmp.zero?
      end
      
      return @children.length <=> otherchildren.length
    end
    
    def hash
      @hash ||= compute_hash
    end
    
    private
    
    def compute_hash
      all = [@realmidx] + @attributes + @children.collect { |c| c.hash }
      return all.hash
    end
  end
  
end