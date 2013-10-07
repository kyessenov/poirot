require 'alloy/ast/types'

module Slang
  module Dsl

    # ================================================================
    # == Module +Mult+
    #
    # Methods for constructing expressions.
    # ================================================================
    module TypeModHelper
      extend self
      def dynamic(type)  Alloy::Ast::AType.get(type).apply_modifier(:dynamic) end
    end

  end
end
