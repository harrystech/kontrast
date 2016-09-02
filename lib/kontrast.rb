# Dependencies
require "fog/aws"
require "bundler"

# Load classes
require "kontrast/exceptions"
require "kontrast/configuration"
require "kontrast/test"
require "kontrast/page_test"
require "kontrast/api_endpoint_test"
require "kontrast/test_builder"
require "kontrast/test_suite"
require "kontrast/spec"
require "kontrast/spec_builder"
require "kontrast/selenium_handler"
require "kontrast/image_helper"
require "kontrast/gallery_creator"
require "kontrast/global_runner"
require "kontrast/image_uploader"
require "kontrast/thumbnail_creator"
require "kontrast/page_runner"
require "kontrast/api_endpoint_runner"
require "kontrast/page_comparator"
require "kontrast/api_endpoint_comparator"

module Kontrast
    class << self
        @@path = nil

        def root
            File.expand_path('../..', __FILE__)
        end

        def in_rails?
            # Logic: Rails uses Bundler, so if the Bundler environment contains Rails, return true.
            # If there's any error whatsoever, return false.
            begin
                Bundler.environment.current_dependencies.each do |dep|
                    return true if dep.name == "rails"
                end
            rescue StandardError => e
                # Quietly ignore any exceptions
            end
            return false
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

                runner = GlobalRunner.new
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
            rescue StandardError => e
                puts e.class
                puts e.message
                puts e.backtrace
            ensure
                # Call "after" hook
                Kontrast.configuration.after_gallery(gallery_info.fetch(:diffs, {}), gallery_info[:path])
            end

            # Return based on if we have diffs or not
            gallery_info.fetch(:diffs, {}).empty?
        end
    end
end
