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

        # Binds specs to tests automatically by matching the test's name to the spec's name
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
