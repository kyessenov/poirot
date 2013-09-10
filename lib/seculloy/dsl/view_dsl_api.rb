require 'alloy/dsl/model_api'
require 'seculloy/model/data'
require 'seculloy/model/module'
require 'seculloy/model/view'
require 'sdg_utils/dsl/syntax_error'

module Seculloy
  module Dsl

    module ViewDslApi
      include Alloy::Dsl::ModelDslApi
      extend self

      @@data_builder = Alloy::Dsl::SigBuilder.new(
        :superclass => Seculloy::Model::Data,
        :return     => :builder
      )

      @@mod_builder = Alloy::Dsl::SigBuilder.new(
        :superclass => Seculloy::Model::Module,
        :return     => :builder
      )

      def data(*args)
        @@data_builder.sig(*args)
      end

      def mod(*args, &block)
        @@mod_builder.sig(*args, &block)
      end

      def trusted(*args, &block)
        blder,blk = if args.size == 1 && Alloy::Dsl::SigBuilder === args.first
                      [args.first, block]
                    else
                      [mod(*args, &block), nil]
                    end
        blder.apply_modifier("trusted", Seculloy::Model::Module, &blk)
      end

      def many(blder, &block)
        blder.apply_modifier("many", Seculloy::Model::Module, &block)
      end

      def abstract(blder, &block)
        blder.apply_modifier("abstract", nil, &block)
      end

      def critical(*data_classes)
        data_classes.each do |data_cls|
          meta.add_critical(data_cls)
        end
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
