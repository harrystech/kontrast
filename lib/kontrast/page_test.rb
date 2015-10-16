module Kontrast
    class PageTest < Test

        attr_reader :width

        def initialize(prefix, name, path, headers: {})
            super
            @width = prefix
        end
    end
end
