module Slang
  module Dsl

    module BelongsToHelper
      def belongs_to(*args)
        meta.belongs_to += args
      end
    end

  end
end
