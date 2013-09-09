require 'sdg_utils/visitors/visitor'

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

        @pera = 1

        # set critical datatypes
        vb.critical *view.critical.map(&method(:convert_data))

        # set trusted modules
        vb.trusted *view.modules.select(&:trusted?).map(&method(:convert_module))

        vb.build(view.name)
      end

      # @param data [Class(? < Seculloy::Model::Data)]
      # @return [Datatype]
      def convert_data(data)
        cache_or("data", data) do
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
      end

      # @param mod [Class(? < Seculloy::Model::Module)]
      # @return [Mod]
      def convert_module(mod)
        cache_or("module", mod) do
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
          mb.invokes_ops *ops.map(&method(:convert_op_to_invokes)).flatten,
          *meta.triggers.map(&method(:convert_trigger))

          # set unque
          mb.setUniq(!meta.common?)

          mb.build mod.relative_name
        end
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
          convert_trigger(fun, op)
        end
      end

      # @param op [Alloy::Ast::Fun]
      # @return [Op]
      def convert_trigger(fun, op=nil)
        body = fun.sym_exe_invoke
        trig_constr =
          case
          when Seculloy::Model::OpConstr === body
            body
          when ::Class === body && body < Seculloy::Model::Operation
            body.some()
          else
            fail "unexpected trigger body; expected OpConstr, got #{body}:#{body.class}"
          end
        when_constr = []
        when_constr << triggeredBy(op.relative_name.to_sym) if op
        when_constr += trig_constr.constr.map(&method(:convert_expr))
        Op.new trig_constr.target_op.relative_name, :when => when_constr
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

      # @param expr [Alloy::Ast::Expr::MExpr]
      # @return [Expr]
      def convert_expr(expr)
        evis.visit(expr)
      end

      def convert_parenexpr(pe)
        evis.visit(pe.sub)
      end

      def convert_callexpr(ce)
        case ce.fun
        when :key?
          fail "expected 1 arg for :key?, got #{ce.args.size}" unless ce.args.size == 1
          target = evis.visit(ce.target)
          arg = evis.visit(ce.args.first)
          hasKey(target, arg)
        when :in?, :has?, :include?, :member?
          msg = "expected 1 arg for #{ce.fun.inspect}, got #{ce.args.size}"
          fail msg unless ce.args.size == 1
          target = evis.visit(ce.target)
          arg = evis.visit(ce.args.first)
          if [:in?].member? ce.fun
            arg.contains(target)
          else
            target.contains(arg)
          end
        else
          fail "unknown method call: #{ce.fun}"
        end
      end

      # @param be [Alloy::Ast::Expr::BinaryExpression]
      def convert_binaryexpr(be)
        lhs = evis.visit(be.lhs)
        rhs = evis.visit(be.rhs)
        meth = be.op.name.to_sym
        if lhs.respond_to? meth
          lhs.send meth, rhs
        else
          fail "cannot convert\n #{be}\n" +
               "`#{lhs}:#{lhs.class}' does not respond to #{meth}"
        end
      end

      def convert_mvarexpr(v)
        e(v.name.to_sym)
      end

      def convert_opexpr(op)
        o()
      end

      def convert_trigexpr(tr)
        trig()
      end

      def convert_argofexpr(ar)
        arg(evis.visit(ar.sub()))
      end

      def convert_argexpr(ar)
        fail "ArgExpr should not exist on its own"
      end

      protected

      def evis()
        @evis ||= SDGUtils::Visitors::TypeDelegatingVisitor.new(self,
          :top_class        => Alloy::Ast::Expr::MExpr,
          :visit_meth_namer => proc{|cls, kind| "convert_#{kind}"},
          :default_return   => proc{|node| fail "no handler for #{node}:#{node.class}"}
        )
      end

      def caches() @caches ||= {} end

      def cache_or(name, key, &block)
        msg = "#{key} not found in #{name} cache"
        cache = caches()[name] ||= {}
        cache[key] ||= (@must_find_in_cache ? fail(msg) : block.call)
      end

    end

  end
end
