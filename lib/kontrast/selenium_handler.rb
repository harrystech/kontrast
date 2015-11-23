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

        def run_comparison(test)
            # Create folder for this test
            current_output = FileUtils.mkdir_p("#{@path}/#{test}").join('')

            # Open test host tabs
            navigate(test.path)

            # Resize to given width and total height
            resize(test.width)

            screenshot_args = [@test_driver[:driver], @production_driver[:driver], { width: test.width, name: test.name }]

            # Take screenshot
            begin
                # Global callback
                Kontrast.configuration.before_screenshot(*screenshot_args)

                # Spec callback
                test.run_callback(:before_screenshot, *screenshot_args)

                screenshot(current_output)
            ensure
                # Global callback
                Kontrast.configuration.after_screenshot(*screenshot_args)

                # Spec callback
                test.run_callback(:after_screenshot, *screenshot_args)
            end
        end

        private
            def navigate(path)
                # Get domains
                test_host = Kontrast.configuration.test_domain
                production_host = Kontrast.configuration.production_domain

                Workers.map([@test_driver, @production_driver]) do |driver|
                    if driver[:name] == "test"
                        driver[:driver].navigate.to("#{test_host}#{path}")
                    elsif driver[:name] == "production"
                        driver[:driver].navigate.to("#{production_host}#{path}")
                    end
                end
            end

            def resize(width)
                Workers.map([@test_driver, @production_driver]) do |driver|
                    driver[:driver].manage.window.resize_to(width, driver[:driver].manage.window.size.height)
                end
            end

            def screenshot(output_path)
                Workers.map([@test_driver, @production_driver]) do |driver|
                    if driver[:name] == "test"
                        driver[:driver].save_screenshot("#{output_path}/test.png")
                    elsif driver[:name] == "production"
                        driver[:driver].save_screenshot("#{output_path}/production.png")
                    end
                end
            end
    end
end
