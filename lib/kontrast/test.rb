module Kontrast
    class Test
        attr_reader :name, :width, :path

        def initialize(width, name, path)
            @width, @name, @path = width, name, path
        end

        def run
        end
    end
end
