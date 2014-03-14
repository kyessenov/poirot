require 'arby/ast/sig'
require 'slang/model/nondet_helper'
require 'slang/model/belongs_to_meta_ext'
require 'slang/dsl/belongs_to_helper'

module Slang
  module Model

    module DataStatic
      include Arby::Dsl::SigDslApi
      include NondetHelper
      include Slang::Dsl::BelongsToHelper

      def _define_meta
        meta = super
        meta.singleton_class.send :include, Slang::Model::BelongsToMetaExt
        meta
      end
    end

    class Data < Arby::Ast::Sig
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
