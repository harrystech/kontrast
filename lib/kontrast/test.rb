module Kontrast
    class Test
        attr_reader :name, :width, :path, :spec

        def initialize(width, name, path)
            @width, @name, @path = width, name, path
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
            "#{@width}_#{@name}"
        end
    end
end
