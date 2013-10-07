require 'alloy/ast/expr'
require 'alloy/ast/sig'
require 'slang/dsl/operation_dsl_api'
require 'slang/model/nondet_helper'

module Slang
  module Model

    module OperationStatic
      include NondetHelper
    end

    class Operation < Alloy::Ast::Sig
      extend Slang::Dsl::OperationDslApi
      extend OperationStatic

      _define_meta

      meta.set_placeholder

      def make_me_sym_expr(name="self")
        # p = __parent()
        # if Slang::Model::Module === p
        #   p.make_me_parent_mod_expr
        # else
        #   fail "Didn't expect operation to have a parent that is not Module " +
        #        "(it's #{p}:#{p.class} instead)"
        # end
        # Alloy::Ast::Expr.as_atom(self, name)
        # self
        make_me_op_expr
      end

      def make_me_op_expr
        p = __parent()
        if Slang::Model::Module === p
          p.make_me_parent_mod_expr
        else
          fail "Didn't expect operation to have a parent that is not Module " +
               "(it's #{p}:#{p.class} instead)"
        end
        Alloy::Ast::Expr.as_atom(self, "o")
        # make_me_sym_expr("o")
        self.singleton_class.send :include, OpExpr
        self
      end

      def make_me_trig_expr
        make_me_sym_expr("trig")
        self.singleton_class.send :include, TrigExpr
        self
      end

      def make_me_arg_expr
        make_me_sym_expr("arg")
        self.singleton_class.send :include, ArgExpr
        self
      end
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~ custom expressions ~~~~~~~~~~~~~~~~~~~~~~ #

    module OpExpr
      include Alloy::Ast::Expr::MExpr
    end

    module TrigExpr
      include Alloy::Ast::Expr::MExpr
    end

    class ArgOfExpr < Alloy::Ast::Expr::UnaryExpr
      def initialize(sub) super("arg", sub) end
    end

    module ArgExpr
      include Alloy::Ast::Expr::MExpr
      def apply_join(other)
        ArgOfExpr.new(other)
      end
    end

  end
end
