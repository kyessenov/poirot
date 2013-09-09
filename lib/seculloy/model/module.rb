require 'alloy/ast/sig'
require 'seculloy/dsl/module_dsl_api'

module Seculloy
  module Model

    class Module < Alloy::Ast::Sig
      extend Seculloy::Dsl::ModuleDslApi

      meta.set_placeholder

      def self.trusted?() meta.trusted? end
      def self.unique?()  !meta.common? end
      def self.common?()  meta.common? end

      def self.set_trusted() meta.set_trusted end
      def self.set_common() meta.set_common end

      def make_me_parent_mod_expr
        make_me_sym_expr("_")
        self.singleton_class.send :include, ParentModExpr
        self
      end

    end

    module ParentModExpr
      include Alloy::Ast::Expr::MExpr
      def apply_join(other)
        other
      end
    end

  end
end
