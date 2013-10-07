module Slang
  module Model

    class Invocation
      attr_reader :type, :owner, :fun, :opts

      def initialize(hash)
        hash = hash.clone
        @type = ensure_key(hash, :type)
        @owner = ensure_key(hash, :owner)
        @fun = ensure_key(hash, :fun)
        @opts = hash
        hash.each do |k,v|
          define_singleton_method k.to_sym, lambda{v}
        end
      end

      private

      def ensure_key(hash, key)
        ans = hash.delete key
        msg = "mandatory key #{key.inspect} not found in #{hash}"
        raise ArgumentError, msg unless ans
        ans
      end

    end

  end
end
