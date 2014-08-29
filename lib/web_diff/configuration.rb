module WebDiff
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
        attr_accessor :_before_run, :_after_run, :_before_gallery, :_after_gallery, :_before_screenshot
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

        def pages(width)
            if !block_given?
                raise Exception.new("You must pass a block to this method.")
            end
            WebDiff.tests.add_width(width)
            yield(WebDiff.tests)
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

        def after_gallery(&block)
            if block_given?
                @_after_gallery = block
            else
                @_after_gallery.call if @_after_gallery
            end
        end

        def before_screenshot(&block)
            if block_given?
                @_before_screenshot = block
            else
                @_before_screenshot.call if @_before_screenshot
            end
        end
    end

    class TestBuilder
        attr_reader :tests

        def initialize
            @tests = Hash.new
        end

        def add_width(width)
            @tests[width] = Hash.new
            @current_width = width
        end

        # Adds a given test from config to the suite
        def method_missing(name, *args)
            @tests[@current_width][name.to_s] = args.first
        end
    end
end
