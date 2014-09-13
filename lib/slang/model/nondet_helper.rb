require 'arby/ast/expr'
require 'arby/ast/fun'

module Slang
  module Model

    module NondetHelper
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
        inst = Arby::Ast::Fun.dummy_instance(self)
        inst_expr = inst.make_me_sym_expr
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
          fld_join_expr = inst_expr.apply_join(fld.to_arby_expr)
          if OpConstr === fld_val
            conjs += fld_val.replace_inst(fld_join_expr)
          else
            conjs << (fld_join_expr == fld_val)
          end
        end
        conjs
      end

      def get_appended_facts(inst_expr, &blk)
        return [] if blk.nil?
        msg = "appended block arity must be 1"
        raise ArgumentError, msg unless blk.arity == 1
        ans = blk.call inst_expr
        [ans]
      end
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~ custom expressions ~~~~~~~~~~~~~~~~~~~~~~ #

    #TODO: rename
    class OpConstr
      include Arby::Ast::Expr::MExpr

      attr_reader :inst, :constr

      def initialize(inst, constr)
        @inst, @constr = inst, constr
      end

      #TODO: rename
      def target_op
        @inst.class
      end

      def replace_inst(replacement_expr)
        constr.map { |e|
          Arby::Ast::Expr.replace_subexpressions(e, @inst, replacement_expr)
        }
      end
    end

  end
end
