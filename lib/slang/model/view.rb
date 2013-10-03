require 'alloy/ast/model'
require 'alloy/ast/type_checker'
require 'slang/utils/sdsl_converter'

module Seculloy
  module Model

    class View < Alloy::Ast::Model
      def data(*args)
        sigs(*args).select{|sig| sig < Seculloy::Model::Data}
      end

      def modules(*args)
        sigs(*args).select{|sig| sig < Seculloy::Model::Module}
      end

      def critical()             @critical ||= [] end
      def add_critical(data_cls)
        msg = "Use `add_critical' to add a critical *Data* instance"
        Alloy::Ast::TypeChecker.check_sig_class(data_cls, Seculloy::Model::Data, msg)
        critical << data_cls
      end

      def to_sdsl
        Seculloy::Utils::SdslConverter.new.convert_view(self)
      end
    end

  end
end
