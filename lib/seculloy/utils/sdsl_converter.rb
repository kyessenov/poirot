require 'sdsl/datatype'
require 'sdsl/view'
require 'sdsl/myutils'

require 'seculloy/model/operation'

module Seculloy
  module Utils

    class SdslConverter

      # @param view [Module(? < Seculloy::Model::View)]
      # @return [View]
      def convert_view(view)
        vb = ViewBuilder.new

        # add all datatypes
        vb.data *view.data.map(&method(:convert_data))

        # add all modules
        vb.modules *view.modules.map(&method(:convert_module))

        vb.build(view.name)
      end

      # @param data [Class(? < Seculloy::Model::Data)]
      # @return [Datatype]
      def convert_data(data)
        meta = data.meta
        db = DatatypeBuilder.new

        # abstract
        db.setAbstract if meta.abstract?

        # super
        db.extends meta.parent_sig.relative_name

        # fields
        db.fields *meta.fields.map(&method(:convert_arg))

        db.build(data.relative_name)
      end

      # @param mod [Class(? < Seculloy::Model::Module)]
      # @return [Mod]
      def convert_module(mod)
        meta = mod.meta
        mb = ModuleBuilder.new

        # extends
        mb.extends(meta.parent_sig.relative_name) unless meta.oldest_ancestor.nil?

        # creates
        mb.creates *meta.creates.map(&:relative_name)

        # stores
        meta.fields.each{|fld| mb.stores convert_arg(fld)}

        ops = meta.operations

        # exports
        mb.exports_ops *ops.map(&method(:convert_op_to_exports))

        # invokes
        mb.invokes_ops *ops.map(&method(:convert_op_to_invokes)).flatten

        mb.build mod.relative_name
      end

      # @param op [Class(? < Seculloy::Model::Operation)]
      # @return [Op]
      def convert_op_to_exports(op)
        Op.new op.relative_name,
          :args => op.meta.fields.map(&method(:convert_arg)),
          :when => op.meta.guards.map(&:sym_exe_export).map(&method(:convert_expr))
      end

      # @param op [Class(? < Seculloy::Model::Operation)]
      # @return [Op]
      def convert_op_to_invokes(op)
        op.meta.triggers.map do |fun|
          body = fun.sym_exe_invoke
          msg = "unexpected trigger body; expected OpConstr, got #{body.class}"
          fail msg unless Seculloy::Model::OpConstr === body
          when_constr = [triggeredBy(op.relative_name.to_sym)] +
                        body.constr.map(&method(:convert_expr))
          Op.new body.target_op.relative_name, :when => when_constr
        end
      end

      # @param expr [Alloy::Ast::MExpr]
      # @return [Expr]
      def convert_expr(expr)
        expr.to_s
      end

      # @param arg [Alloy::Ast::Arg]
      # @return [Item, Bag]
      def convert_arg(arg)
        name = arg.name
        col_types = arg.type.map(&:short_name)
        if arg.type.unary?
          if arg.type.scalar?
            item name, *col_types
          else
            set name, *col_types
          end
        else
          rel name, *col_types
        end
      end
    end

  end
end
