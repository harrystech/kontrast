module Kontrast
    class TestSuite
        attr_reader :tests

        def initialize
            @tests = []
        end

        def <<(test)
            @tests << test
        end

        # Mostly used for testing
        def to_h
            suite_hash = Hash.new

            @tests.each do |test|
                suite_hash[test.width] ||= []
                suite_hash[test.width] << { test.name => test.path }
            end

            return suite_hash
        end
    end
end
