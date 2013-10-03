require 'alloy/ast/type_checker'
require 'slang/model/module'
require 'slang/model/view'
require 'slang/model/operation'
require 'sdg_utils/lambda/sourcerer'

module Seculloy
  module Model

    module Helpers
      protected

      def check_view(*views)
        views.each do |view|
          Alloy::Ast::TypeChecker.check_alloy_module(view, "Not a View module!")
          msg = "`#{view}' is not a view module"
          raise Alloy::Ast::TypeError, msg unless Seculloy::Model::View === view.meta
        end
      end      

      def check_subcls(parent_cls, *klasses)
        klasses.each do |klass|
          msg = "`#{klass}' is not a Seculloy #{parent_cls.relative_name} class"
          raise Alloy::Ast::TypeError, msg unless klass < parent_cls
        end
      end

      def check_module(*mods) check_subcls(Seculloy::Model::Module, *mods) end
      def check_data(*data)   check_subcls(Seculloy::Model::Data, *data) end
      def check_op(*ops)      check_subcls(Seculloy::Model::Operation, *ops) end

      def proc_src(proc)
        SDGUtils::Lambda::Sourcerer.proc_to_src_and_loc(proc)
      end

      def inst_eval_block(obj, proc)
        obj.instance_eval *proc_src(proc)
      end
    end

    # -------------------------------
    # === Class +Refinement+
    #
    # -------------------------------
    class Refinement
      include Helpers
      extend Helpers

      # @param views [Array(Seculloy::Model::View)]
      def self.define(*views, &block)
        ans = self.new(*views)
        inst_eval_block(ans, block) if block
      end

      def mod_map(hash, &blk) 
        msg = "Can't specify a single block for more than one module refinement"
        raise ArgumentError, msg if hash.size > 1 && blk
        @mod_refs += hash.map{|lhs, rhs| ModRef.new(lhs, rhs, &blk)}
      end

      def data_map(hash, &blk) 
        msg = "Can't specify a single block for more than one datatype refinement"
        raise ArgumentError, msg if hash.size > 1 && blk
        @data_refs += hash.map{|lhs, rhs| DataRef.new(lhs, rhs, &blk)}
      end
      
      attr_reader :mod_refs, :data_refs

      def initialize(*views)
        check_view(*views)
        views.each do |view| 
          self.singleton_class.send :include, view
        end
        @mod_refs = []
        @data_refs = []
      end
    end

    # -------------------------------
    # === Class +BaseRef+
    #
    # -------------------------------
    class BaseRef
      include Helpers

      attr_reader :from, :to
      def initialize(from, to)
        @from, @to = from, to
      end
    end

    # -------------------------------
    # === Class +ModRef+
    #
    # -------------------------------
    class ModRef < BaseRef
      def initialize(from, to, &blk)
        super(from, to)
        check_module(@from, @to)
        @op_refs = []
        if blk
          ops = from.meta.operations + to.meta.operations
          ops.each do |op|
            str = "#{op.relative_name} = #{op.name}"
            self.instance_eval str
          end
          inst_eval_block(self, blk)
        end
      end

      def op_map(hash, &blk) 
        msg = "Can't specify a single block for more than one operation refinement"
        raise ArgumentError, msg if hash.size > 1 && blk
        @op_refs += hash.map{|lhs, rhs| OpRef.new(lhs, rhs, &blk)}
      end

    end

    # -------------------------------
    # === Class +OpRef+
    #
    # -------------------------------
    class OpRef < BaseRef
      def initialize(from, to, &blk)
        super(from, to)
        check_op(@from, @to)
      end
    end

    # -------------------------------
    # === Class +DataRef+
    #
    # -------------------------------
    class DataRef < BaseRef
      def initialize(from, to, &blk)
        super(from, to)
        check_data(@from, @to)
      end
    end
    
  end
end
