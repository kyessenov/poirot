require 'arby/dsl/model_api'
require 'slang/dsl/type_mod_helper'
require 'slang/model/data'
require 'slang/model/module'
require 'slang/model/view'
require 'sdg_utils/dsl/syntax_error'

module Slang
  module Dsl

    module ViewDslApi
      include Arby::Dsl::ModelDslApi
      include Slang::Dsl::TypeModHelper
      extend self

      def policy(*args, &block)
        assertion(*args, &block)
      end

      def data(*args, &block)
        Arby::Dsl::SigBuilder.new(
          :superclass => Slang::Model::Data,
          :return     => :builder
        ).sig(*args, &block)
      end

      def mod(*args, &block)
        Arby::Dsl::SigBuilder.new(
          :superclass => Slang::Model::Module,
          :return     => :builder
        ).sig(*args, &block)
      end

      alias_method :component, :mod

      def trusted(*args, &block)
        blder,blk = if args.size == 1 && Arby::Dsl::SigBuilder === args.first
                      [args.first, block]
                    else
                      [mod(*args, &block), nil]
                    end
        blder.apply_modifier("trusted", Slang::Model::Module, &blk)
      end

      def many(blder, &block)
        blder.apply_modifier("many", Slang::Model::Module, &block)
      end

      def get_data_klasses(data_classes, &block) 
        fst = data_classes.first
        if data_classes.size == 1 && Arby::Dsl::SigBuilder === fst
          data_classes = fst.return_result(:array)
        end
        if block
          data_classes.each do |dc|
            dc.send :class_eval, &block
          end
        end
        data_classes
      end

      def secret(*data_classes, &block)
        critical(*data_classes, &block)
      end

      def critical(*data_classes, &block)
        data_klasses = get_data_klasses(data_classes, &block)
        data_klasses.each do |data_cls|
          meta.add_critical(data_cls)
        end
      end
      
      def global(*data_classes, &block)
        data_klasses = get_data_klasses(data_classes, &block)
        data_klasses.each do |data_cls|
          meta.add_global(data_cls)
        end
      end
      
      def __finish
        super
      end

      def __create_model(scope_module)
        Slang::Model::View.new(scope_module, self)
      end

      # meta predicates

      def mayAccess(mod, data)
        pred = Arby::Ast::Fun.pred(:name => :mayAccess)
        Arby::Ast::Expr::CallExpr.new(nil, pred, mod, data)
      end

      def isTrusted(mod)
        pred = Arby::Ast::Fun.pred(:name => :isTrusted)
        Arby::Ast::Expr::CallExpr.new(nil, pred, mod)
      end   

      def confidential(rel, col)
        pred = Arby::Ast::Fun.pred(:name => :confidential)
        Arby::Ast::Expr::CallExpr.new(nil, pred, rel, col)
      end

      def contains(rel, col1, col2)
        pred = Arby::Ast::Fun.pred(:name => :contains)
        Arby::Ast::Expr::CallExpr.new(nil, pred, rel, col1, col2)
      end

      def uniqueAssignments(rel)
        pred = Arby::Ast::Fun.pred(:name => :uniqueAssignments)
        Arby::Ast::Expr::CallExpr.new(nil, pred, rel)
      end
    end

  end
end
