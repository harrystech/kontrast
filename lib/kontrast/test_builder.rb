module Kontrast

    LazyTest = Struct.new(:prefix, :headers, :block)

    class TestBuilder
        attr_reader :suite
        attr_accessor :prefix, :headers, :url_params

        def initialize
            @suite = TestSuite.new
            @prefix = nil
            @headers = {}
            @url_params = {}
        end

        # Needed in case someone tries to name a test "tests"
        def tests(param = nil)
            if param
                raise ConfigurationException.new("'tests' is not a valid name for a test.")
            end
            return @suite.tests
        end

        # API
        # add more?
        %i(get post).each do |http_method|
            define_method http_method do |name, path|
                @suite << ApiEndpointTest.new(@prefix, name, path, headers: headers.dup)
            end
        end

        def lazy_api_endpoints(&block)
            @suite.lazy_tests << LazyTest.new(@prefix, @headers.dup, block)
        end

        # Adds a given test from config to the suite
        def method_missing(name, *args)
            @suite << PageTest.new(@prefix, name.to_s, args.first, url_params: @url_params)
        end
    end
end
