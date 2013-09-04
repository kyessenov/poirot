require 'alloy/ast/sig'
require 'seculloy/dsl/operation_dsl_api'

module Seculloy
  module Model

    class Operation < Alloy::Ast::Sig
      extend Seculloy::Dsl::OperationDslApi

      meta.set_placeholder
    end

  end
end
