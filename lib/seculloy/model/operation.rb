require 'alloy/ast/expr'
require 'alloy/ast/fun'
require 'alloy/ast/sig'
require 'seculloy/dsl/operation_dsl_api'

module Seculloy
  module Model

    module OperationStatic
      def [](*args)
        hash =
          if args.size == 1 && Hash === args.first
            args.first
          else
            msg = "too many arguments for operation #{self}: " +
                  "#{meta.fields.size} expected, #{args.size} given"
            raise ArgumentError, msg if args.size > meta.fields.size
            args.each_with_index.reduce({}) do |acc, arg_idx|
              acc[meta.fields[arg_idx.last].name] = arg_idx.first
              acc
            end
          end
        constr = get_field_values_constraint(hash)
        OpConstr.new self, constr
      end

      protected

      def get_field_values_constraint(hash)
        target = Alloy::Ast::Fun.dummy_instance_expr(self, "o")
        conjs = []
        hash.each do |fld_name, fld_val|
          fld = meta.field(fld_name)
          msg = "field #{fld_name} not found in #{self.class.name}"
          raise ArgumentError, msg unless fld
          conjs << (target.apply_join(fld.to_alloy_expr) == fld_val)
        end
        conjs
      end
    end

    class Operation < Alloy::Ast::Sig
      extend Seculloy::Dsl::OperationDslApi
      extend OperationStatic

      meta.set_placeholder

      def make_me_sym_expr(name="self")
        p = __parent()
        if Alloy::Ast::ASig === p
          expr = p.make_me_sym_expr("_")
          if Seculloy::Model::Module === p
            expr.singleton_class.send :include, ParentModExpr
          end
          expr
        end
        Alloy::Ast::Expr.as_atom(self, name)
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

    class OpConstr
      include Alloy::Ast::Expr::MExpr

      attr_reader :target_op, :constr

      def initialize(target_op, constr)
        @target_op, @constr = target_op, constr
      end
    end

    module TrigExpr
    end

    module ArgExpr
    end

    module ParentModExpr
      def apply_join(other)
        other
      end
    end

  end
end
