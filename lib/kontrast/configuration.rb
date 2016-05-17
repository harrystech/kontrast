module Kontrast
    class << self
        attr_accessor :configuration, :page_builder, :api_endpoint_builder

        def configure
            self.configuration ||= Configuration.new
            yield(configuration)
        end

        def page_test_builder
            self.page_builder ||= TestBuilder.new
        end

        def api_endpoint_test_builder
            self.api_endpoint_builder ||= TestBuilder.new
        end

        def page_test_suite
            self.page_builder ? self.page_builder.suite : nil
        end

        def api_endpoint_test_suite
            self.api_endpoint_builder ? self.api_endpoint_builder.suite : nil
        end
    end

    class Configuration
        attr_accessor :run_parallel, :total_nodes, :current_node
        attr_accessor :_before_run, :_after_run, :_before_gallery, :_after_gallery, :_before_screenshot, :_after_screenshot
        attr_accessor :distortion_metric, :highlight_color, :lowlight_color
        attr_accessor :local_path, :remote_path, :aws_bucket, :aws_key, :aws_secret
        attr_accessor :test_domain, :production_domain
        attr_accessor :browser_driver, :browser_profile
        attr_accessor :fail_build
        attr_accessor :workers_pool_size
        attr_accessor :production_oauth_app_uid, :production_oauth_app_secret,
          :test_oauth_app_uid, :test_oauth_app_secret, :oauth_token_url,
          :oauth_token_from_response, :test_oauth_app_proc

        def initialize
            # Set defaults
            @browser_driver = "firefox"
            @browser_profile = {}

            @run_parallel = false
            @total_nodes = 1
            @current_node = 0

            @distortion_metric = "MeanAbsoluteErrorMetric"
            @highlight_color = "blue"
            @lowlight_color = "rgba(255, 255, 255, 0.3)"

            @fail_build = false
        end

        def validate
            # Check that Kontrast has everything it needs to proceed
            check_nil_vars(["test_domain", "production_domain"])
            if Kontrast.page_test_suite.nil? && Kontrast.api_endpoint_test_suite.nil?
                raise ConfigurationException.new("Kontrast has no tests to run.")
            end

            # If remote, check for more options
            if @run_parallel
                check_nil_vars(["aws_bucket", "aws_key", "aws_secret"])
                check_nil_vars(["local_path", "remote_path"])

                # Make sure total nodes is >= 1 so we don't get divide by 0 errors
                if @total_nodes < 1
                    raise ConfigurationException.new("total_nodes cannot be less than 1.")
                end
            end
        end

        def pages(width, url_params = {})
            if !block_given?
                raise ConfigurationException.new("You must pass a block to the pages config option.")
            end
            Kontrast.page_test_builder.prefix = width
            Kontrast.page_test_builder.url_params = url_params
            yield(Kontrast.page_test_builder)
        end

        def api_endpoints(group_name)
            if !block_given?
                raise ConfigurationException.new("You must pass a block to the api_endpoints config option.")
            end
            Kontrast.api_endpoint_test_builder.prefix = group_name
            yield(Kontrast.api_endpoint_test_builder)
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

        def before_screenshot(test_driver = nil, production_driver = nil, current_test = nil, &block)
            if block_given?
                @_before_screenshot = block
            else
                @_before_screenshot.call(test_driver, production_driver, current_test) if @_before_screenshot
            end
        end

        def after_screenshot(test_driver = nil, production_driver = nil, current_test = nil, &block)
            if block_given?
                @_after_screenshot = block
            else
                @_after_screenshot.call(test_driver, production_driver, current_test) if @_after_screenshot
            end
        end

        def workers_pool_size
            @workers_pool_size || 5
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
