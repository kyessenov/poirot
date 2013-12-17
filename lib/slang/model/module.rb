require 'arby/ast/sig'
require 'slang/dsl/module_dsl_api'

module Slang
  module Model

    class Module < Arby::Ast::Sig
      extend Slang::Dsl::ModuleDslApi

      _define_meta

      meta.set_placeholder

      def self.trusted?() meta.trusted? end
      def self.unique?()  !meta.common? end
      def self.many?()    meta.many? end

      def self.set_trusted() meta.set_trusted end
      def self.set_many() meta.set_many end

      def make_me_parent_mod_expr
        make_me_sym_expr("_")
        self.singleton_class.send :include, ParentModExpr
        self
      end

    end

    module ParentModExpr
      include Arby::Ast::Expr::MExpr
      def apply_join(other)
        join_expr = super(other)
        ParentModJoinExpr.new(join_expr)
      end
    end

    class ParentModJoinExpr
      include Arby::Ast::Expr::MExpr
      attr_reader :join_expr
      def initialize(join_expr)
        super(join_expr.__type)
        @join_expr = join_expr 
      end
    end

  end
end
