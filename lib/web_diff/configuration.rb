module WebDiff
    class << self
        attr_accessor :configuration
    end

    def self.configure
        self.configuration ||= Configuration.new
        yield(configuration)
    end

    class Configuration
        attr_accessor :run_parallel, :total_nodes, :current_node
        attr_accessor :_before_run, :_after_run, :_before_gallery, :_after_gallery
        attr_accessor :distortion_metric, :highlight_color, :lowlight_color
        attr_accessor :remote, :remote_path, :gallery_path, :aws_key, :aws_secret
        attr_accessor :local_uri

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
    end
end
