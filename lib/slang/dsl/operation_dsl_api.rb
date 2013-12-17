require 'arby/ast/type_checker'
require 'arby/dsl/sig_api'

require 'sdg_utils/caching/searchable_attr'
require 'sdg_utils/random'
require 'sdg_utils/string_utils'

require 'slang/dsl/effects_helper'
require 'slang/dsl/guard_helper'
require 'slang/dsl/trigger_helper'

module Slang
  module Dsl

    module OperationDslApi
      include Arby::Dsl::SigDslApi
      include Slang::Dsl::TriggerHelper
      include Slang::Dsl::GuardHelper
      include Slang::Dsl::EffectsHelper

      alias_method :response, :sends


      private

      # Extend the existing Arby::Ast::SigMeta class with some extra
      # methods for fetching Slang specific stuff.
      def _define_meta
        meta = super
        meta.singleton_class.send :include, AlloySigMetaOperationExt
        meta
      end
    end

    module AlloySigMetaOperationExt
      include SDGUtils::Caching::SearchableAttr

      attr_hier_searchable :guard, :trigger, :effect
    end
  end
end
