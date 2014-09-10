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
            @driver = Selenium::WebDriver.for(driver_name.to_sym, profile: profile)
            @driver2 = Selenium::WebDriver.for(driver_name.to_sym, profile: profile)
        end

        def cleanup
            # Make sure windows are closed
            @driver.quit
            @driver2.quit
        end

        def run_comparison(width, path, name)
            # Create folder for this test
            current_output = FileUtils.mkdir("#{@path}/#{width}_#{name}").join('')

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
            # todo: would love to do this concurrently
            def navigate(path)
                # Get domains
                test_host = Kontrast.configuration.test_domain
                production_host = Kontrast.configuration.production_domain

                @driver.navigate.to("#{test_host}#{path}")
                @driver2.navigate.to("#{production_host}#{path}")
            end

            def resize(width)
                Workers.map([@driver, @driver2]) do |driver|
                    driver.manage.window.resize_to(width, driver.manage.window.size.height)
                end
            end

            # todo: would love to do this concurrently
            def screenshot(output_path)
                @driver.save_screenshot("#{output_path}/test.png")
                @driver2.save_screenshot("#{output_path}/production.png")
            end
    end
end