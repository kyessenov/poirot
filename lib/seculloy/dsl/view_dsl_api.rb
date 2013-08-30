require 'alloy/dsl/model_api'
require 'seculloy/model/data'
require 'seculloy/model/module'

module Seculloy
  module Dsl

    module ViewDslApi
      include Alloy::Dsl::ModelDslApi
      extend self

      def data(*names)
        sb = Alloy::Dsl::SigBuilder.new(
          :superclass => Seculloy::Model::Data
        )
        names.each{ |name| sb.sig(name, {}) }
      end

      def mod(*args, &block)
        Alloy::Dsl::SigBuilder.new(
          :superclass => Seculloy::Model::Module
        ).sig(*args, &block)
      end

      # Extend the existing Alloy::Ast::Model class with some extra
      # methods for fetching Seculloy specific entites.
      def __define_meta(alloy_model)
        alloy_model.singleton_class.send :include, AlloyModelExt
        define_singleton_method :meta, lambda{alloy_model}
      end
    end

    module AlloyModelExt
      def data(*args)
        sigs(*args).select{|sig| sig < Seculloy::Model::Data}
      end

      def modules(*args)
        sigs(*args).select{|sig| sig < Seculloy::Model::Module}
      end
    end
  end
end
