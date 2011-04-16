module LibBracket
  AUTOLOAD_CLASSES = { "is_summable" => [:Zero, :Sum, :IsSummable],
                       "is_multipliable" => [:One, :Product, :IsMultipliable, :MultiplicationCommutes],
                       "has_scalars" => [:ScalarMultiple, :HasScalars, :HasScalarsFromLeft, :HasScalarsFromRight, :ScalarMultipleOperator],
                       "linear_child" => [:LinearChild],
                       "has_inner_product" => [:InnerProduct, :HasInnerProduct]
                     }
  
  def self.const_missing(sym)
    @autoload_modules ||= AUTOLOAD_CLASSES.to_a.collect do |fname, modules|
      Hash[*modules.product([fname]).reduce(:+)]
    end.reduce(:merge)
    fname = @autoload_modules[sym]
    return super unless fname
    require "libbracket/#{fname}"
    raise "autoload of #{sym.to_s} failed!" unless const_defined? sym
    return const_get sym
  end
end
