module Seculloy
  module Dsl

    # ================================================================
    # == Module +Mult+
    #
    # Methods for constructing expressions.
    # ================================================================
    module TypeModHelper
      extend self
      def dynamic(type)  type.apply_modifier(:dynamic) end
    end

  end
end
