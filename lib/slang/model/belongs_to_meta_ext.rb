module Slang
  module Model

    module BelongsToMetaExt
      def belongs_to()   @belongs_to ||= [] end
      def belongs_to=(x) @belongs_to = x end
    end

  end
end
