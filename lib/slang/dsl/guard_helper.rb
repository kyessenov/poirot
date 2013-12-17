require 'arby/dsl/fun_helper'
require 'sdg_utils/random'

module Slang
  module Dsl

    # REQUIREMENT: `meta.add_guard(g)' method chain must be
    #              available in the target class (where this module is
    #              included)
    module GuardHelper
      include Arby::Dsl::FunHelper

      def guard(hash={}, &block)
        hash.empty? || _check_single_fld_hash(hash)
        name = "guard"
        name += "_#{SDGUtils::StringUtils.to_iden hash.values.first}" unless hash.empty?
        name += "_#{SDGUtils::Random.salted_timestamp}"
        g = pred(name, hash, nil, &block)
        expr_kind = if g.owner < Slang::Model::Operation
                      "arg"
                    elsif g.owner < Slang::Model::Module
                      "parent_mod"
                    else
                      fail "Didn't expect trigger to be included in #{g.owner}"
                    end
        g.instance_eval <<-RUBY, __FILE__, __LINE__+1
          def sym_exe_export
            op_inst = Arby::Ast::Fun.dummy_instance(@owner)
            __sym_exe op_inst.make_me_#{expr_kind}_expr
          end
        RUBY
        meta.add_guard g
      end

    end

  end
end
