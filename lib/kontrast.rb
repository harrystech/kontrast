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

            if Kontrast.configuration.run_parallel
                @@path = FileUtils.mkdir_p(Kontrast.configuration.local_path).join('')
            elsif Kontrast.in_rails?
                @@path = FileUtils.mkdir_p(Rails.root + "tmp/shots/#{Time.now.to_i}").join('')
            else
                @@path = FileUtils.mkdir_p("/tmp/shots/#{Time.now.to_i}").join('')
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

        def make_gallery(result_path = nil)
            puts "Creating gallery..."
            gallery_info = {}
            begin
                # Call "before" hook
                Kontrast.configuration.before_gallery

                gallery_creator = GalleryCreator.new(result_path)
                if Kontrast.configuration.run_parallel
                    gallery_info = gallery_creator.create_gallery(Kontrast.configuration.local_path)
                else
                    gallery_info = gallery_creator.create_gallery(result_path)
                end
            ensure
                # Call "after" hook
                Kontrast.configuration.after_gallery(gallery_info[:diffs], gallery_info[:path])
            end
        end
    end
end
