require 'alloy/ast/sig'
require 'seculloy/dsl/module_dsl_api'

module Seculloy
  module Model

    class Module < Alloy::Ast::Sig
      extend Seculloy::Dsl::ModuleDslApi

      meta.set_placeholder

    end

  end
end
