require 'alloy/dsl/model_api'
require 'seculloy/model/data'
require 'seculloy/model/module'
require 'seculloy/model/view'

module Seculloy
  module Dsl

    module ViewDslApi
      include Alloy::Dsl::ModelDslApi
      extend self

      def data(*names)
        sb = Alloy::Dsl::SigBuilder.new(
          :superclass => Seculloy::Model::Data
        )
        names.map{ |name| sb.sig(name, {}) }
      end

      def abstract_data(*args, &block)
        data(*args, &block).map do |d|
          d.abstract()
          d
        end
      end

      def mod(*args, &block)
        Alloy::Dsl::SigBuilder.new(
          :superclass => Seculloy::Model::Module
        ).sig(*args, &block)
      end

      def __finish
        meta.modules.each do |mod|
          mod.meta.eval_lazy_operations
        end
      end

      def __create_model(scope_module)
        Seculloy::Model::View.new(scope_module, self)
      end
    end

  end
end
