require 'alloy/ast/type_checker'
require 'alloy/dsl/model_api'
require 'alloy/dsl/sig_api'

require 'sdg_utils/caching/searchable_attr'
require 'sdg_utils/random'

require 'seculloy/model/data'
require 'seculloy/model/operation'
require 'seculloy/model/invocation'

module Seculloy
  module Dsl

    module ModuleDslApi
      include Alloy::Dsl::SigDslApi

      def creates(data_cls)
        Alloy::Ast::TypeChecker.check_sig_class(data_cls, Seculloy::Model::Data)
        meta.add_creates(data_cls)
      end

      def operation(*args, &body)
        op = Alloy::Dsl::SigBuilder.new(
          :superclass => Seculloy::Model::Operation,
          :create_const => false
        ).sig(*args, &body)
        meta.add_operation op
      end

      # # @deprecated
      # def after(name, &block)
      #   fun_name = "after_#{name}_#{SDGUtils::Random.salted_timestamp}"
      #   fun = fun(fun_name, &block)
      #   meta.add_invoke Seculloy::Model::Invocation.new(
      #     :type          => :after,
      #     :owner         => self,
      #     :fun           => fun,
      #     :target_export => name
      #   )
      #   fun
      # end

      # # @deprecated
      # def nondet(&block)
      #   fun_name = "nondet_#{SDGUtils::Random.salted_timestamp}"
      #   fun = fun(fun_name, &block)
      #   meta.add_invoke Seculloy::Model::Invocation.new(
      #     :type          => :nondet,
      #     :owner         => self,
      #     :fun           => fun
      #   )
      #   fun
      # end

      # def after_fun_from_method_added(fun)
      #   meta.add_export(fun)
      #   _define_method_for_fun(fun, false, true)
      #   fun
      # end

      # Extend the existing Alloy::Ast::SigMeta class with some extra
      # methods for fetching Seculloy specific stuff.
      def _define_meta
        meta = super
        meta.singleton_class.send :include, AlloySigMetaModuleExt
        meta
      end
    end

    module AlloySigMetaModuleExt
      include SDGUtils::Caching::SearchableAttr
      def creates()             @creates ||= [] end
      def add_creates(data_cls) creates << data_cls end

      attr_hier_searchable :operation

      def _hierarchy_up
        up=super && AlloySigMetaModuleExt === up
      end
    end
  end
end
