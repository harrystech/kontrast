module WebDiff
    class << self
        attr_accessor :configuration
    end

    def self.configure
        self.configuration ||= Configuration.new
        yield(configuration)
    end

    class Configuration
        attr_accessor :_before_run, :_after_run
        attr_accessor :distortion_metric, :highlight_color, :lowlight_color
        attr_accessor :aws_key, :aws_secret

        def initialize
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
    end
end
