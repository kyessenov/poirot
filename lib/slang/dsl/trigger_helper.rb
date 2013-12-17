require 'arby/dsl/fun_helper'
require 'sdg_utils/random'

module Slang
  module Dsl

    # REQUIREMENT: `meta.add_trigger(t)' method chain must be
    #              available in the target class (where this module is
    #              included)
    module TriggerHelper
      include Arby::Dsl::FunHelper

      def triggers(&block)
        name = "triggers_#{SDGUtils::Random.salted_timestamp}"
        t = fun(name, {}, nil, &block)
        expr_kind = if t.owner < Slang::Model::Operation
                      "trig"
                    elsif t.owner < Slang::Model::Module
                      "parent_mod"
                    else
                      fail "Didn't expect trigger to be included in #{t.owner}"
                    end
        t.instance_eval <<-RUBY, __FILE__, __LINE__+1
          def sym_exe_invoke
            op_inst = Arby::Ast::Fun.dummy_instance(@owner)
            __sym_exe op_inst.make_me_#{expr_kind}_expr
          end
        RUBY
        meta.add_trigger t
      end

      alias_method :sends, :triggers

    end

  end
end
