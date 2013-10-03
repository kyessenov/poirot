require 'alloy/dsl/fun_helper'
require 'sdg_utils/random'

module Seculloy
  module Dsl

    # REQUIREMENT: `meta.add_effect(t)' method chain must be
    #              available in the target class (where this module is
    #              included)
    module EffectsHelper
      include Alloy::Dsl::FunHelper

      def effects(&block)
        name = "effect_#{SDGUtils::Random.salted_timestamp}"
        p = pred(name, {}, nil, &block)
        expr_kind = if p.owner < Seculloy::Model::Operation
                      "arg"
                    elsif p.owner < Seculloy::Model::Module
                      "parent_mod"
                    else
                      fail "Didn't expect `effects' clause to be included in #{p.owner}"
                    end
        p.instance_eval <<-RUBY, __FILE__, __LINE__+1
          def sym_exe_export
            op_inst = Alloy::Ast::Fun.dummy_instance(@owner)
            __sym_exe op_inst.make_me_#{expr_kind}_expr
          end
        RUBY
        meta.add_effect p
      end
    end

  end
end
