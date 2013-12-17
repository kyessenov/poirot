require 'arby/dsl/fun_helper'
require 'sdg_utils/random'

module Slang
  module Dsl

    # REQUIREMENT: `meta.add_effect(t)' method chain must be
    #              available in the target class (where this module is
    #              included)
    module EffectsHelper
      include Arby::Dsl::FunHelper

      def effects(&block)
        name = "effect_#{SDGUtils::Random.salted_timestamp}"
        p = pred(name, {}, nil, &block)
        expr_kind = if p.owner < Slang::Model::Operation
                      "arg"
                    elsif p.owner < Slang::Model::Module
                      "parent_mod"
                    else
                      fail "Didn't expect `effects' clause to be included in #{p.owner}"
                    end
        p.instance_eval <<-RUBY, __FILE__, __LINE__+1
          def sym_exe_export
            op_inst = Arby::Ast::Fun.dummy_instance(@owner)
            __sym_exe op_inst.make_me_#{expr_kind}_expr
          end
        RUBY
        meta.add_effect p
      end
    end

  end
end
