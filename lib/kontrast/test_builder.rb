module Kontrast
    class TestBuilder
        attr_reader :tests

        def initialize
            @tests = Hash.new
        end

        def add_width(width)
            @tests[width] = Hash.new
            @current_width = width
        end

        # Adds a given test from config to the suite
        def method_missing(name, *args)
            @tests[@current_width][name.to_s] = args.first
        end
    end
end