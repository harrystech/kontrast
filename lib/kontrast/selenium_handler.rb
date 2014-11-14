require "selenium-webdriver"
require "workers"

module Kontrast
    class SeleniumHandler
        def initialize
            @path = Kontrast.path

            # Configure profile
            driver_name = Kontrast.configuration.browser_driver
            profile = Selenium::WebDriver.const_get(driver_name.capitalize)::Profile.new
            Kontrast.configuration.browser_profile.each do |option, value|
                profile[option] = value
            end

            # Get drivers with profile
            @test_driver = {
                name: "test",
                driver: Selenium::WebDriver.for(driver_name.to_sym, profile: profile)
            }
            @production_driver = {
                name: "production",
                driver: Selenium::WebDriver.for(driver_name.to_sym, profile: profile)
            }
        end

        def cleanup
            # Make sure windows are closed
            Workers.map([@test_driver, @production_driver]) do |driver|
                driver[:driver].quit
            end
        end

        def run_comparison(width, path, name)
            # Create folder for this test
            current_output = FileUtils.mkdir_p("#{@path}/#{width}_#{name}").join('')

            # Open test host tabs
            navigate(path)

            # Resize to given width and total height
            resize(width)

            # Take screenshot
            begin
                Kontrast.configuration.before_screenshot(@test_driver[:driver], @production_driver[:driver], { width: width, name: name })
                screenshot(current_output)
            ensure
                Kontrast.configuration.after_screenshot(@test_driver[:driver], @production_driver[:driver], { width: width, name: name })
            end

        end

        private
            def navigate(path)
                # Get domains
                test_host = Kontrast.configuration.test_domain
                @test_driver[:driver].navigate.to("#{test_host}#{path}")

                production_host = Kontrast.configuration.production_domain
                @production_driver[:driver].navigate.to("#{production_host}#{path}")
            end

            def resize(width)
                @test_driver[:driver].manage.window.resize_to(width, @test_driver[:driver].manage.window.size.height)
                @production_driver[:driver].manage.window.resize_to(width, @production_driver[:driver].manage.window.size.height)
            end

            def screenshot(output_path)
                @test_driver[:driver].save_screenshot("#{output_path}/test.png")
                @production_driver[:driver].save_screenshot("#{output_path}/production.png")
            end
    end
end