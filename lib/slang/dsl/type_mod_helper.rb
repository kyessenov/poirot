require 'arby/ast/types'

module Slang
  module Dsl

    # ================================================================
    # == Module +Mult+
    #
    # Methods for constructing expressions.
    # ================================================================
    module TypeModHelper
      extend self
      def updatable(type)  
        Arby::Ast::AType.get(type).apply_modifier(:dynamic) 
      end
    end
  end
end
