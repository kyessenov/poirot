require 'arby/ast/expr'
require 'arby/ast/sig'
require 'slang/dsl/operation_dsl_api'
require 'slang/model/nondet_helper'

module Slang
  module Model

    module OperationStatic
      include NondetHelper
    end

    class Operation < Arby::Ast::Sig
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
        # Arby::Ast::Expr.as_atom(self, name)
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
        Arby::Ast::Expr.as_atom(self, "o")
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
      include Arby::Ast::Expr::MExpr
    end

    module TrigExpr
      include Arby::Ast::Expr::MExpr
    end

    class ArgOfExpr < Arby::Ast::Expr::UnaryExpr
      def initialize(sub) 
        super("arg", sub) 
        set_type(sub.__type)
      end
    end

    module ArgExpr
      include Arby::Ast::Expr::MExpr
      def apply_join(other)
        ArgOfExpr.new(other)
      end
    end

  end
end
