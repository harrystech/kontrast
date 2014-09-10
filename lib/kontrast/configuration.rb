module Kontrast
    class << self
        attr_accessor :configuration, :test_suite

        def configure
            self.configuration ||= Configuration.new
            yield(configuration)
        end

        def tests
            self.test_suite ||= TestBuilder.new
        end
    end

    class Configuration
        attr_accessor :run_parallel, :total_nodes, :current_node
        attr_accessor :_before_run, :_after_run, :_before_gallery, :_after_gallery, :_before_screenshot, :_after_screenshot
        attr_accessor :distortion_metric, :highlight_color, :lowlight_color
        attr_accessor :remote, :remote_path, :gallery_path, :aws_bucket, :aws_key, :aws_secret, :upload_base_uri
        attr_accessor :test_domain, :production_domain
        attr_accessor :browser_driver, :browser_profile

        def initialize
            # Set defaults
            @browser_driver = "firefox"
            @browser_profile = {}

            @run_parallel = false
            @remote = false

            @distortion_metric = "MeanAbsoluteErrorMetric"
            @highlight_color = "blue"
            @lowlight_color = "rgba(255, 255, 255, 0.3)"
        end

        def validate
            # Check that Kontrast has everything it needs to proceed
            check_nil_vars(["test_domain", "production_domain"])
            if Kontrast.test_suite.nil?
                raise ConfigurationException.new("Kontrast has no tests to run.")
            end
        end

        def pages(width)
            if !block_given?
                raise ConfigurationException.new("You must pass a block to the pages config option.")
            end
            Kontrast.tests.add_width(width)
            yield(Kontrast.tests)
        end

        def before_run(&block)
            if block_given?
                @_before_run = block
            else
                @_before_run.call if @_before_run
            end
        end

        def after_run(&block)
            if block_given?
                @_after_run = block
            else
                @_after_run.call if @_after_run
            end
        end

        def before_gallery(&block)
            if block_given?
                @_before_gallery = block
            else
                @_before_gallery.call if @_before_gallery
            end
        end

        def after_gallery(diffs = nil, gallery = nil, &block)
            if block_given?
                @_after_gallery = block
            else
                @_after_gallery.call(diffs, gallery) if @_after_gallery
            end
        end

        def before_screenshot(driver1 = nil, driver2 = nil, &block)
            if block_given?
                @_before_screenshot = block
            else
                @_before_screenshot.call(driver1, driver2) if @_before_screenshot
            end
        end

        def after_screenshot(driver1 = nil, driver2 = nil, &block)
            if block_given?
                @_after_screenshot = block
            else
                @_after_screenshot.call(driver1, driver2) if @_after_screenshot
            end
        end

        private
            def check_nil_vars(vars)
                vars.each do |var|
                    if instance_variable_get("@#{var}").nil?
                        raise ConfigurationException.new("Kontrast config is missing the #{var} option.")
                    end
                end
            end
    end
end
