require 'alloy/dsl/model_builder'
require 'seculloy/dsl/view_dsl_api'
require 'seculloy/dsl/module_dsl_api'

module Seculloy

  module Dsl
    extend self

    def view(name, &block)
      Alloy::Dsl::ModelBuilder.new({
        :mods_to_include => [Seculloy::Dsl::ViewDslApi]
      }).model(:view, name, &block)
    end

  end

end
