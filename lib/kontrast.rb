# Dependencies
require "fog"

# Load classes
require "kontrast/exceptions"
require "kontrast/configuration"
require "kontrast/test_builder"
require "kontrast/selenium_handler"
require "kontrast/image_handler"
require "kontrast/gallery_creator"
require "kontrast/runner"

module Kontrast
    class << self
        @@path = nil

        def root
            File.expand_path('../..', __FILE__)
        end

        def in_rails?
            begin
                Gem::Specification.find_by_name('rails')
                return true
            rescue Gem::LoadError
                return false
            end
        end

        def path
            return @@path if @@path

            if Kontrast.configuration.remote
                if Dir.exists?(Kontrast.configuration.remote_path)
                    @@path = Kontrast.configuration.remote_path
                else
                    @@path = FileUtils.mkdir(Kontrast.configuration.remote_path).join('')
                end
            elsif Kontrast.in_rails?
                @@path = ensure_output_path(Rails.root + "tmp/shots/#{Time.now.to_i}")
            else
                @@path = ensure_output_path("/tmp/shots/#{Time.now.to_i}")
            end

            return @@path
        end

        def fog
            return Fog::Storage.new({
                :provider                 => 'AWS',
                :aws_access_key_id        => Kontrast.configuration.aws_key,
                :aws_secret_access_key    => Kontrast.configuration.aws_secret
            })
        end

        def run
            beginning_time = Time.now

            begin
                # Call "before" hook
                Kontrast.configuration.before_run

                runner = Runner.new
                runner.run
            ensure
                # Call "after" hook
                Kontrast.configuration.after_run
            end

            end_time = Time.now
            puts "Time elapsed: #{(end_time - beginning_time)} seconds"
        end

        def make_gallery(path = nil)
            puts "Creating gallery..."
            gallery_info = {}
            begin
                # Call "before" hook
                Kontrast.configuration.before_gallery

                gallery_creator = GalleryCreator.new(path)
                if Kontrast.configuration.remote
                    gallery_info = gallery_creator.create_gallery(Kontrast.configuration.gallery_path)
                else
                    gallery_info = gallery_creator.create_gallery(path)
                end
            ensure
                # Call "after" hook
                Kontrast.configuration.after_gallery(gallery_info[:diffs], gallery_info[:path])
            end
        end

        private
            def ensure_output_path(path)
                # Make sure path is created
                begin
                    FileUtils.mkdir_p(path)
                rescue Exception => e
                    raise e
                end

                return path.to_s
            end
    end
end