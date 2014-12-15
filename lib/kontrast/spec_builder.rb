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

        def self.load_specs
            if Kontrast.in_rails?
                spec_folder = Rails.root.to_s + "/kontrast_specs"
            else
                spec_folder = Kontrast.root + "/kontrast_specs"
            end

            spec_files = Dir[spec_folder + "/**/*_spec.rb"]
            spec_files.each do |file|
                require file
            end
        end
    end
end
