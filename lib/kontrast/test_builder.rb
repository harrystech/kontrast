module Kontrast
    class TestBuilder
        def initialize
            @tests = []
        end

        def add_width(width)
            @current_width = width
        end

        # Needed in case someone tries to name a test "tests"
        def tests(param = nil)
            if param
                raise ConfigurationException.new("'tests' is not a valid name for a test.")
            end
            return @tests
        end

        # Adds a given test from config to the suite
        def method_missing(name, *args)
            @tests << Test.new(@current_width, name.to_s, args.first)
        end
    end
end