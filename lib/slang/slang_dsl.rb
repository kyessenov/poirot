require 'arby/dsl/model_builder'
require 'slang/dsl/view_dsl_api'
require 'slang/dsl/module_dsl_api'

module Slang

  module Dsl
    extend self

    def view(name, &block)
      Arby.conf.do_with(:defer_body_eval => false, 
                         :detect_appended_facts => false) do
        Arby::Dsl::ModelBuilder.new({
          :mods_to_include => [Slang::Dsl::ViewDslApi]
        }).model(:view, name, &block)
      end
    end

  end

end
