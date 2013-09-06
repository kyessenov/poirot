require 'alloy/ast/sig'

module Seculloy
  module Model
    
    class Data < Alloy::Ast::Sig
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
