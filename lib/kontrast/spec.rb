module Kontrast
    class Spec
        attr_accessor :name, :_before_screenshot, :_after_screenshot

        def initialize(name)
            @name = name
        end

        def before_screenshot(test_driver, production_driver, current_test)
            @_before_screenshot.call(test_driver, production_driver, current_test)
        end

        def after_screenshot(test_driver, production_driver, current_test)
            @_after_screenshot.call(test_driver, production_driver, current_test)
        end
    end
end
