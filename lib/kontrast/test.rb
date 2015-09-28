module Kontrast
    class Test
        attr_reader :name, :path, :spec, :prefix, :headers

        def initialize(prefix, name, path, headers: {})
            @prefix, @name, @path, @headers = prefix, name, path, headers
        end

        def bind_spec(spec)
            @spec = spec
        end

        # Usage: test.run_callback(:before_screenshot, arg1, arg2, arg3)
        def run_callback(name, *args)
            return if @spec.nil?
            @spec.send(name.to_sym, *args)
        end

        def to_s
            return "#{@prefix}_#{@name}"
        end

        def to_str
            return to_s
        end
    end
end
