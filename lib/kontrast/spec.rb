module Kontrast
    class Spec
        attr_accessor :name, :_before_screenshot, :_after_screenshot

        def initialize(name)
            @name = name
        end

        def before_screenshot(test_driver, production_driver, current_test)
            if @_before_screenshot
                @_before_screenshot.call(test_driver, production_driver, current_test)
            end
        end

        def after_screenshot(test_driver, production_driver, current_test)
            if @_after_screenshot
                @_after_screenshot.call(test_driver, production_driver, current_test)
            end
        end
    end
end
