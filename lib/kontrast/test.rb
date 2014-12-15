module Kontrast
    class Test
        attr_reader :name, :width, :path, :spec

        def initialize(width, name, path)
            @width, @name, @path = width, name, path
        end

        def bind_spec(spec)
            @spec = spec
        end

        def to_s
            "#{@width}_#{@name}"
        end
    end
end
