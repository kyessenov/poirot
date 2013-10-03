require 'alloy/ast/sig'
require 'slang/model/nondet_helper'

module Seculloy
  module Model

    module DataStatic
      include NondetHelper
    end

    class Data < Alloy::Ast::Sig
      extend DataStatic

      _define_meta

      meta.set_placeholder

      def initialize(*field_values)
        field_values.each_with_index do |val, idx|
          fld = meta.fields[idx]
          if fld
            write_field(fld, val)
          end
        end
      end
    end

  end
end
