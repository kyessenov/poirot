require 'alloy/utils/alloy_printer'

require 'sdg_utils/visitors/visitor'

require 'sdsl/datatype'
require 'sdsl/view'
require 'sdsl/myutils'

require 'slang/model/operation'

module Slang
  module Utils

    class SdslConverter

      def initialize
        @assignlhs = false
        @must_find_in_cache = nil
      end

      # @param view [Module(? < Slang::Model::View)]
      # @return [View]
      def convert_view(view)
        @assignlhs = false
        @must_find_in_cache = nil

        vb = ViewBuilder.new

        # add all datatypes
        vb.data *view.data.map(&method(:convert_data))

        # add all modules
        vb.modules *view.modules.map(&method(:convert_module))

        @must_find_in_cache = 1

        # set critical datatypes
        vb.critical *view.critical.map(&method(:convert_data))

        # set trusted modules
        vb.trusted *view.modules.select(&:trusted?).map(&method(:convert_module))

        # build
        ans = vb.build(view.name)

        # add alloy funs
        all_sigs = view.data
        all_funs = all_sigs.map{|s| s.meta.all_funs}.flatten
        ans.appendFun all_funs.map(&method(:to_als)).join("\n ")

        ans
      ensure
        @must_find_in_cache = nil
      end

      # @param data [Class(? < Slang::Model::Data)]
      # @return [Datatype]
      def convert_data(data)
        cache_or("data", data) do
          meta = data.meta
          db = DatatypeBuilder.new

          # abstract
          db.setAbstract if meta.abstract?

          # super
          db.extends _data_name(meta.parent_sig)

          # fields
          db.fields *meta.fields.map(&method(:convert_arg))

          db.build(_data_name(data))
        end
      end

      # @param mod [Class(? < Slang::Model::Module)]
      # @return [Mod]
      def convert_module(mod)
        cache_or("module", mod) do
          meta = mod.meta
          mb = ModuleBuilder.new

          # extends
          mb.extends(_mod_name(meta.parent_sig)) unless meta.oldest_ancestor.nil?

          # creates
          mb.creates *meta.creates.map(&method(:_mod_name))

          # stores
          meta.fields.each{|fld| mb.stores convert_arg(fld)}

          ops = meta.operations

          # exports
          mb.exports_ops *ops.map(&method(:convert_op_to_exports))

          # invokes
          trigger_ops = ops.map(&method(:convert_op_to_invokes)).flatten +
                        meta.triggers.map(&method(:convert_trigger)).flatten
          mb.invokes_ops *group_by_op_name(trigger_ops)

          # assumes
          mb.assumes *meta.guards.map(&method(:convert_guard))

          # set unque
          mb.setUniq(!meta.many?)

          # set dynamic fields
          mb.dynamics *meta.fields.select{|fld|
            fld.type.has_modifier?(:dynamic)
          }.map(&:name)

          mb.build _mod_name(mod)
        end
      end

      # @param trigger_ops [Array(Op)]
      # @return [Array(Op)]
      def group_by_op_name(trigger_ops)
        # this is only for invokes, so no args
        trigger_ops.group_by(&:name).map { |op_name, ops|
          if ops.size == 1
            ops.first
          else
            non_empty_whens = ops.map{|o| o.constraints[:when]}.reject(&:empty?)
            Op.new op_name,
              :args => [],
              :when => [disjs(non_empty_whens.map{|cstrs| conjs(cstrs)})]
          end
        }
      end

      # @param op [Class(? < Slang::Model::Operation)]
      # @return [Op]
      def convert_op_to_exports(op)
        Op.new "#{_op_name op}",
          :args => op.meta.fields.map(&method(:convert_arg)),
          :when => (op.meta.guards.map(&method(:convert_guard)) +
                    op.meta.effects.map(&method(:convert_effect)))
      end

      # @param op [Class(? < Slang::Model::Operation)]
      # @return [Array(Op)]
      def convert_op_to_invokes(op)
        op.meta.triggers.map { |fun|
          convert_trigger(fun, op)
        }.flatten
      end

      # @param guard_fun [Alloy::Ast::Fun]
      # @return [Expr]
      def convert_guard(guard_fun)
        convert_expr(guard_fun.sym_exe_export)
      end

      # def rebuild_dynamic_fields(e, prepost)
      #   Alloy::Utils::ExprRebuilder.new do |expr|
      #     if Alloy::Ast::Expr::FieldExpr === expr &&
      #         expr.__field.type.has_modifier?(:dynamic)
      #       varname = "#{_arg_name(expr.__field)}.(o.#{prepost})"
      #       Alloy::Ast::Expr::Var.new(varname, expr.__field.type)
      #     else
      #       nil
      #     end
      #   end.rebuild(e)
      # end

      # @param effect_fun [Alloy::Ast::Fun]
      # @return [Expr]
      def convert_effect(effect_fun)
        Alloy.boss.clear_side_effects
        res = effect_fun.sym_exe_export
        seffects = Alloy.boss.clear_side_effects
        if seffects.empty? || (seffects.last.rhs.__neq res rescue true)
          seffects << res
        end
        seffects.map(&method(:convert_expr))
      end

      # @param trigger_fun [Alloy::Ast::Fun]
      # @param op [Class(? < Slang::Model::Operation)]
      # @return [Array(Op)]
      def convert_trigger(trigger_fun, op=nil)
        body = trigger_fun.sym_exe_invoke
        case
        when ::Class === body && body < Slang::Model::Operation
          convert_trigger_expr(body.some(), op)
        when ::Array === body
          body.map{|e| convert_trigger_expr(e, op)}.flatten
        else
          convert_trigger_expr(body, op)
        end
      end

      # @param trig_constr [Alloy::Ast::MExpr]
      # @param op [Class(? < Slang::Model::Operation)]
      # @return [Op]
      def convert_trigger_expr(trig_expr, op=nil)
        case
        when Slang::Model::OpConstr === trig_expr
          when_constr = []
          when_constr << triggeredBy(_op_name(op).to_sym) if op
          when_constr += trig_expr.constr.map(&method(:convert_expr))
          op = Op.new _op_name(trig_expr.target_op), :when => when_constr
          [op]
        when trig_expr.is_disjunction
          trig_expr.children.reduce([]){|acc, e| acc += convert_trigger_expr(e, op)}
        else
          fail "unexpected trigger expr: " +
               "expected OpConstr, got #{trig_expr}:#{trig_expr.class}"
         end
      end

      # @param arg [Alloy::Ast::Arg]
      # @return [Item, Bag]
      def convert_arg(arg)
        name = _arg_name(arg)
        col_types = arg.type.map(&:klass).map(&method(:_sig_name))
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

      def convert_intexpr(ie)
        ae(ie.__value)
      end

      def convert_callexpr(ce)
        case ce.fun
        when :key?
          fail "expected 1 arg for :key?, got #{ce.args.size}" unless ce.args.size == 1
          target = evis.visit(ce.target)
          arg = evis.visit(ce.args.first)
          hasKey(target, arg)
        when :in?, :has?, :include?, :member?, :contains?
          msg = "expected 1 arg for #{ce.fun.inspect}, got #{ce.args.size}"
          fail msg unless ce.args.size == 1
          target = evis.visit(ce.target)
          arg = evis.visit(ce.args.first)
          if [:in?].member? ce.fun
            arg.contains(target)
          else
            target.contains(arg)
          end
        when Alloy::Ast::Fun
          target = convert_expr(ce.target)
          lhs = target.join(ae _fun_name ce.fun)
          FuncApp.new(lhs, *ce.args.map(&method(:convert_expr)))
        else
          fail "unknown method call: #{ce.fun}"
        end
      end

      def convert_iteexpr(ite)
        cond = convert_expr(ite.cond)
        ans = []
        if ite.then_expr && !Alloy::Ast::Expr::BoolConst.True?(ite.then_expr)
          then_expr = convert_expr(ite.then_expr)
          ans << implies(cond, then_expr)
        end
        if ite.else_expr && !Alloy::Ast::Expr::BoolConst.True?(ite.else_expr)
          else_expr = convert_expr(ite.else_expr)
          ans << implies(neg(cond), else_expr)
        end
        case ans.size
        when 0; raise "ITEExpr with neither then nor else branch"
        when 1; ans.first
        when 2; conj(*ans)
        end
      end

      # @param be [Alloy::Ast::Expr::UnaryExpression]
      def convert_unaryexpr(ue)
        sub = convert_expr(ue.sub)
        meth = ue.op.name
        if sub.respond_to? meth
          sub.send meth
        else
          fail "cannot convert\n #{ue}\n" +
               "`#{sub}:#{sub.class}' does not respond to #{meth}"
        end
      end

      # @param be [Slang::Model::ParentModExpr]
      def convert_parentmodexpr(pme)
        fail "didn't expect to see a ParentModExpr on its own"
      end

      # @param be [Slang::Model::ParentModJoinExpr]
      def convert_parentmodjoinexpr(pmje)
        convert_expr(pmje.join_expr.rhs)
      end
      
      # @param be [Alloy::Ast::Expr::BinaryExpression]
      def convert_binaryexpr(be)
        is_assign_expr = be.__op == Alloy::Ast::Ops::ASSIGN
        lhs = set_assignlhs_while(is_assign_expr) do
          evis.visit(be.lhs)
        end
        rhs = evis.visit(be.rhs)
        meth = is_assign_expr ? "equals" : be.__op.name
        if lhs.respond_to? meth
          lhs.send meth, rhs
        else
          fail "cannot convert\n #{be}\n" +
               "`#{lhs}:#{lhs.class}' does not respond to #{meth}"
        end
      end

      def convert_fieldexpr(f)
        fldname = _arg_name(f.__field)
        if f.__field.type.has_modifier?(:dynamic)
          prepost = @assignlhs ? "post" : "pre"
          fldname = "#{fldname}.(o.#{prepost})"
        end
        e(fldname)
      end

      def convert_mvarexpr(v)
        e(v.__name.to_sym)
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
        o() #return the operation
      end

      protected

      def set_assignlhs_while(val, &block)
        old = @assignlhs
        @assignlhs = val
        begin
          yield
        ensure
          @assignlhs = old
        end
      end

      def to_als(*args)
        ans = Alloy::Utils::AlloyPrinter.new({
          :sig_namer => method(:_sig_name).to_proc,
          :fun_namer => method(:_fun_name).to_proc,
          :arg_namer => method(:_arg_name).to_proc
        }).export_to_als(*args)
        ans
      end

      def _sig_name(sig_cls)
        case
        when sig_cls == Slang::Model::Operation; "Op"
        when sig_cls < Slang::Model::Operation;  _op_name(sig_cls)
        when sig_cls < Slang::Model::Module;     _mod_name(sig_cls)
        when sig_cls < Slang::Model::Data;       _data_name(sig_cls)
        when sig_cls == Integer;                 "Int"
        else
          fail "Unknown sig cls: #{sig_cls}"
        end
      end
      def _op_name(op_cls)
        "#{op_cls.__parent().relative_name}__#{op_cls.relative_name}"
      end
      def _data_name(data_cls) data_cls.relative_name end
      def _mod_name(mod_cls)   mod_cls.relative_name end
      def _arg_name(arg)
        case arg
        when Alloy::Ast::Field
          "#{_sig_name arg.parent}__#{arg.name}"
        when Alloy::Ast::Arg
          arg.name
        else
          raise ArgumentError, "not an Arg: #{arg}:#{arg.class}"
        end
      end
      def _fun_name(fun)
        "#{_sig_name(fun.owner)}___#{fun.name}"
      end

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
