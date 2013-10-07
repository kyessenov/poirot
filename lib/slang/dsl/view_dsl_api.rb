require 'alloy/dsl/model_api'
require 'slang/dsl/type_mod_helper'
require 'slang/model/data'
require 'slang/model/module'
require 'slang/model/view'
require 'sdg_utils/dsl/syntax_error'

module Slang
  module Dsl

    module ViewDslApi
      include Alloy::Dsl::ModelDslApi
      include Slang::Dsl::TypeModHelper
      extend self

      def data(*args)
        Alloy::Dsl::SigBuilder.new(
          :superclass => Slang::Model::Data,
          :return     => :builder
        ).sig(*args)
      end

      def mod(*args, &block)
        Alloy::Dsl::SigBuilder.new(
          :superclass => Slang::Model::Module,
          :return     => :builder
        ).sig(*args, &block)
      end

      def trusted(*args, &block)
        blder,blk = if args.size == 1 && Alloy::Dsl::SigBuilder === args.first
                      [args.first, block]
                    else
                      [mod(*args, &block), nil]
                    end
        blder.apply_modifier("trusted", Slang::Model::Module, &blk)
      end

      def many(blder, &block)
        blder.apply_modifier("many", Slang::Model::Module, &block)
      end

      def critical(*data_classes)
        data_classes.each do |data_cls|
          meta.add_critical(data_cls)
        end
      end

      def __finish
      end

      def __create_model(scope_module)
        Slang::Model::View.new(scope_module, self)
      end

    end

  end
end
