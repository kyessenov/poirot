require 'alloy/ast/type_checker'
require 'alloy/dsl/sig_api'

require 'sdg_utils/caching/searchable_attr'
require 'sdg_utils/random'
require 'sdg_utils/string_utils'

module Seculloy
  module Dsl

    module OperationDslApi
      include Alloy::Dsl::SigDslApi

      def guard(hash={}, &block)
        hash.empty? || _check_single_fld_hash(hash)
        name = "guard"
        name += "_#{SDGUtils::StringUtils.to_iden hash.values.first}" unless hash.empty?
        name += "_#{SDGUtils::Random.salted_timestamp}"
        g = pred(name, hash, nil, &block)
        g.instance_eval <<-RUBY, __FILE__, __LINE__+1
          def sym_exe_export
            op_inst = Alloy::Ast::Fun.dummy_instance(@owner)
            __sym_exe op_inst.make_me_arg_expr
          end
        RUBY
        meta.add_guard g
      end

      def triggers(&block)
        name = "triggers_#{SDGUtils::Random.salted_timestamp}"
        t = fun(name, {}, nil, &block)
        t.instance_eval <<-RUBY, __FILE__, __LINE__+1
          def sym_exe_invoke
            op_inst = Alloy::Ast::Fun.dummy_instance(@owner)
            __sym_exe op_inst.make_me_trig_expr
          end
        RUBY
        meta.add_trigger t
      end

      alias_method :sends, :triggers

      def effects(hash={}, &block)
        hash.empty? || _check_single_fld_hash(hash)
        name = "effects"
        name += "_#{SDGUtils::StringUtils.to_iden hash.values.first}" unless hash.empty?
        name += "_#{SDGUtils::Random.salted_timestamp}"
        e = fun(name, hash, nil, &block)
        meta.add_effect e
      end

      alias_method :affects, :effects #TODO: pick one or the other

      private

      # Extend the existing Alloy::Ast::SigMeta class with some extra
      # methods for fetching Seculloy specific stuff.
      def _define_meta
        meta = super
        meta.singleton_class.send :include, AlloySigMetaOperationExt
        meta
      end
    end

    module AlloySigMetaOperationExt
      include SDGUtils::Caching::SearchableAttr

      attr_hier_searchable :guard, :effect, :trigger
    end
  end
end
