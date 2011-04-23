module LibBracket
  module LinearChild
    def treat_linear_child(key)
      child = @children[key]
      return @domain::ZERO if child.zero?
      if child.is_a? Sum
        summands = child.children.collect do |term|
          cdren = @children.clone
          cdren[key] = term
          Term.construct @primitive, @domain, cdren
        end
        return Sum.from_summands *summands
      end
      if child.is_a? ScalarMultiple
        cdren = @children.clone
        cdren[key] = child.other
        inner = Term.construct @primitive, @domain, cdren
        return inner.scalar_multiple(child.scalar) if inner.is_a? HasScalars
        return inner * child.scalar if inner.is_a? IsMultipliable
        raise "bam!"
      end
      return nil
    end
  end
end