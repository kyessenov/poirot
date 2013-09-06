require 'alloy/ast/model'
require 'seculloy/utils/sdsl_converter'

module Seculloy
  module Model
    
    class View < Alloy::Ast::Model
      def data(*args)
        sigs(*args).select{|sig| sig < Seculloy::Model::Data}
      end

      def modules(*args)
        sigs(*args).select{|sig| sig < Seculloy::Model::Module}
      end

      def to_sdsl
        Seculloy::Utils::SdslConverter.new.convert_view(self)
      end
    end

  end
end
