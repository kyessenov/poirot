require 'arby/ast/model'
require 'arby/ast/type_checker'
require 'slang/utils/sdsl_converter'

module Slang
  module Model

    class View < Arby::Ast::Model
      def data(*args)
        sigs(*args).select{|sig| sig < Slang::Model::Data}
      end

      def modules(*args)
        sigs(*args).select{|sig| sig < Slang::Model::Module}
      end

      def critical()             @critical ||= [] end
      def add_critical(data_cls)
        msg = "Use `add_critical' to add a critical *Data* instance"
        Arby::Ast::TypeChecker.check_sig_class!(data_cls, Slang::Model::Data, msg)
        critical << data_cls
      end
      
      def global() 
        @global ||= [] 
      end      
      def add_global(data_cls)
        msg = "Use `add_global' to add an global *Data* instance"
        Arby::Ast::TypeChecker.check_sig_class!(data_cls, Slang::Model::Data, msg)
        global << data_cls        
      end

      def to_sdsl        
        Slang::Utils::SdslConverter.new.convert_view(self)
      end

      def to_poirot_sdsl        
        Slang::Utils::SdslConverter.new.convert_view(self)
      end
    end

  end
end
