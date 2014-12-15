module Kontrast
    class << self
        attr_accessor :spec_builder

        def get_spec_builder
            self.spec_builder ||= SpecBuilder.new
        end

        def describe(spec_name)
            self.get_spec_builder.add(spec_name)
            yield(self.get_spec_builder)
        end
    end

    class SpecBuilder
        attr_reader :specs

        def initialize
            @specs = []
        end

        def add(spec_name)
            new_spec = Spec.new(spec_name)
            @specs << new_spec
            @current_spec = new_spec
        end

        def before_screenshot(&block)
            @current_spec._before_screenshot = block
        end

        def after_screenshot(&block)
            @current_spec._after_screenshot = block
        end
    end
end
