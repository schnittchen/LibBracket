module LibBracket
  def self.copy_constants_in_module(mod)
    LibBracket.constants.each do |sym|
      mod.const_set sym, LibBracket.const_get(sym)
    end
  end
end
