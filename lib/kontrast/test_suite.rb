module Kontrast
    class TestSuite
        attr_reader :tests

        def initialize
            @tests = []
        end

        def <<(test)
            if(!test.is_a?(Test))
                raise TestSuiteException.new("Cannot add a #{test.class} to the test suite.")
            end
            @tests << test
        end

        def load_specs
            spec_files = Dir[Kontrast.root + "/kontrast_specs/**/*_spec.rb"]
            spec_files.each do |file|
                require file
            end
        end

        def bind_specs
            specs = Kontrast.get_spec_builder.specs
            specs.each do |spec|
                test = @tests.find { |t| t.to_s == spec.name }
                if test
                    test.bind_spec(spec)
                end
            end
        end

        # For rspec
        def to_h
            suite_hash = Hash.new

            @tests.each do |test|
                suite_hash[test.width] ||= {}
                suite_hash[test.width][test.name] = test.path
            end

            return suite_hash
        end

        private
            def clear
                @tests = []
            end
    end
end
