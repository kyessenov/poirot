require 'alloy/ast/type_checker'
require 'alloy/dsl/sig_api'

require 'sdg_utils/caching/searchable_attr'
require 'sdg_utils/random'
require 'sdg_utils/string_utils'

require 'seculloy/dsl/trigger_helper'
require 'seculloy/dsl/guard_helper'

module Seculloy
  module Dsl

    module OperationDslApi
      include Alloy::Dsl::SigDslApi
      include Seculloy::Dsl::TriggerHelper
      include Seculloy::Dsl::GuardHelper

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
