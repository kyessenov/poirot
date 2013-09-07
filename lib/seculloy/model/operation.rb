require 'alloy/ast/expr'
require 'alloy/ast/fun'
require 'alloy/ast/sig'
require 'seculloy/dsl/operation_dsl_api'

module Seculloy
  module Model

    module OperationStatic
      def [](*args)
        some(*args)
      end

      def some(*args, &block)
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
        inst = Alloy::Ast::Fun.dummy_instance(self)
        inst_expr = inst.make_me_op_expr
        constrs = get_field_values_constraint(inst_expr, hash)
        constrs += get_appended_facts(inst_expr, &block)
        OpConstr.new inst_expr, constrs
      end

      protected

      def get_field_values_constraint(inst_expr, hash)
        conjs = []
        hash.each do |fld_name, fld_val|
          fld = meta.field(fld_name)
          msg = "field #{fld_name} not found in #{self.class.name}"
          raise ArgumentError, msg unless fld
          conjs << (inst_expr.apply_join(fld.to_alloy_expr) == fld_val)
        end
        conjs
      end

      def get_appended_facts(inst_expr, &blk)
        return [] if blk.nil?
        msg = "appended block arity is #{blk.arity} but only " +
              "#{meta.fields.size} args found in #{self}"
        raise ArgumentError, msg if blk.arity > meta.fields.size
        flds = meta.fields[0...blk.arity].map{|f| inst_expr.apply_join(f.to_alloy_expr)}
        ans = blk.call *flds
        [ans]
      end
    end

    class Operation < Alloy::Ast::Sig
      extend Seculloy::Dsl::OperationDslApi
      extend OperationStatic

      meta.set_placeholder

      def make_me_sym_expr(name="self")
        p = __parent()
        if Seculloy::Model::Module === p
          p.make_me_parent_mod_expr
        else
          fail "Didn't expect operation to have a parent that is not Module " +
               "(it's #{p}:#{p.class} instead)"
        end
        Alloy::Ast::Expr.as_atom(self, name)
        self
      end

      def make_me_op_expr
        make_me_sym_expr("o")
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

    class OpConstr
      include Alloy::Ast::Expr::MExpr

      attr_reader :op_inst, :constr

      def initialize(op_inst, constr)
        @op_inst, @constr = op_inst, constr
      end

      def target_op
        @op_inst.class
      end
    end

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
