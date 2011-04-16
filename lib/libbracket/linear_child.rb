require 'is_summable'
require 'has_scalars'

module LibBracket
  module LinearChild
    def treat_linear_child(key)
      child = @children[key]
      return @domain::ZERO if child.zero?
      if child.is_a? Sum
        summands = child.children.collect do |term|
          cdren = @children.clone
          cdren[key] = term
          clone_with_children cdren
        end
        return Sum.new *summands
      end
      if child.is_a? ScalarMultiple
        cdren = @children.clone
        cdren[key] = child.other
        return ScalarMultiple.from_scalar_and_other child.scalar, clone_with_children(cdren)
      end
      return nil
    end
  end
end