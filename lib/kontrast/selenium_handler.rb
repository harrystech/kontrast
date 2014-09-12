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
            @driver = {
                name: "test",
                driver: Selenium::WebDriver.for(driver_name.to_sym, profile: profile)
            }
            @driver2 = {
                name: "production",
                driver: Selenium::WebDriver.for(driver_name.to_sym, profile: profile)
            }
        end

        def cleanup
            # Make sure windows are closed
            Workers.map([@driver, @driver2]) do |driver|
                driver[:driver].quit
            end
        end

        def run_comparison(width, path, name)
            # Create folder for this test
            current_output = Kontrast.ensure_output_path("#{@path}/#{width}_#{name}")

            # Open test host tabs
            navigate(path)

            # Resize to given width and total height
            resize(width)

            # Take screenshot
            begin
                Kontrast.configuration.before_screenshot(@driver, @driver2)
                screenshot(current_output)
            ensure
                Kontrast.configuration.after_screenshot(@driver, @driver2)
            end
        end

        private
            def navigate(path)
                # Get domains
                test_host = Kontrast.configuration.test_domain
                production_host = Kontrast.configuration.production_domain

                Workers.map([@driver, @driver2]) do |driver|
                    if driver[:name] == "test"
                        driver[:driver].navigate.to("#{test_host}#{path}")
                    elsif driver[:name] == "production"
                        driver[:driver].navigate.to("#{production_host}#{path}")
                    end
                end
            end

            def resize(width)
                Workers.map([@driver, @driver2]) do |driver|
                    driver[:driver].manage.window.resize_to(width, driver[:driver].manage.window.size.height)
                end
            end

            def screenshot(output_path)
                Workers.map([@driver, @driver2]) do |driver|
                    if driver[:name] == "test"
                        driver[:driver].save_screenshot("#{output_path}/test.png")
                    elsif driver[:name] == "production"
                        driver[:driver].save_screenshot("#{output_path}/production.png")
                    end
                end
            end
    end
end