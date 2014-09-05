# Dependencies
require "fog"

# Load classes
require "chalcogen/configuration"
require "chalcogen/test_builder"
require "chalcogen/selenium_handler"
require "chalcogen/image_handler"
require "chalcogen/gallery_creator"
require "chalcogen/runner"

module Chalcogen
    class << self
        @@path = nil

        def root
            File.expand_path('../..', __FILE__)
        end

        def path
            return @@path if @@path

            if Chalcogen.configuration.remote
                if Dir.exists?(Chalcogen.configuration.remote_path)
                    @@path = Chalcogen.configuration.remote_path
                else
                    @@path = FileUtils.mkdir(Chalcogen.configuration.remote_path).join('')
                end
            elsif Dir.exists?("/tmp/shots")
                @@path = FileUtils.mkdir("/tmp/shots/#{Time.now.to_i}").join('')
            else
                FileUtils.mkdir("/tmp/shots")
                @@path = FileUtils.mkdir("/tmp/shots/#{Time.now.to_i}").join('')
            end

            return @@path
        end

        def fog
            return Fog::Storage.new({
                :provider                 => 'AWS',
                :aws_access_key_id        => Chalcogen.configuration.aws_key,
                :aws_secret_access_key    => Chalcogen.configuration.aws_secret
            })
        end

        def run
            beginning_time = Time.now

            begin
                # Call "before" hook
                Chalcogen.configuration.before_run

                runner = Runner.new
                runner.run
            ensure
                # Call "after" hook
                Chalcogen.configuration.after_run
            end

            end_time = Time.now
            puts "Time elapsed: #{(end_time - beginning_time)} seconds"
        end

        def make_gallery(path = nil)
            puts "Creating gallery..."
            gallery_info = {}
            begin
                # Call "before" hook
                Chalcogen.configuration.before_gallery

                gallery_creator = GalleryCreator.new(path)
                if Chalcogen.configuration.remote
                    gallery_info = gallery_creator.create_gallery(Chalcogen.configuration.gallery_path)
                else
                    gallery_info = gallery_creator.create_gallery(path)
                end
            ensure
                # Call "after" hook
                Chalcogen.configuration.after_gallery(gallery_info[:diffs], gallery_info[:path])
            end
        end
    end
end
