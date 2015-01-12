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
            @current_spec = Spec.new(spec_name)
            @specs << @current_spec
        end

        def before_screenshot(&block)
            @current_spec._before_screenshot = block
        end

        def after_screenshot(&block)
            @current_spec._after_screenshot = block
        end

        def self.load_specs(specs_path = nil)
            if !specs_path.nil?
                spec_folder = specs_path
            elsif Kontrast.in_rails?
                spec_folder = Rails.root.to_s + "/kontrast_specs"
            else
                spec_folder = "./kontrast_specs"
            end

            spec_files = Dir[spec_folder + "/**/*_spec.rb"]
            spec_files.each do |file|
                require file
            end
        end

        private
            def clear
                @specs = []
            end
    end
end
