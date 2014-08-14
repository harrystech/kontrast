require "yaml"

module WebDiff    
    class Runner
        def initialize
            # Load config
            @config = YAML::load(File.open(WebDiff.root + "/config/config.yml"))

            # Set path for output
            @output_path = FileUtils.mkdir(WebDiff.root + "/shots/#{Time.now.to_i}").join('')
        end

        def run
            beginning_time = Time.now

            # Call "before" hook
            WebDiff.configuration.before_run

            # Load required classes
            @selenium_handler = SeleniumHandler.new(@output_path, @config)
            @image_handler = ImageHandler.new(@output_path)
            @gallery_creator = GalleryCreator.new(@output_path)

            begin
                # Run per-page tasks
                to_run = @config['pages']
                to_run.each do |width, pages|
                    next if pages.nil?
                    pages.each do |name, path|
                        print "Processing #{name} @ #{width}... "

                        # Run the browser and take screenshots
                        @selenium_handler.run_comparison(width, path, name)

                        # Crop images
                        print "Cropping... "
                        @image_handler.crop_images(width, name)

                        # Compare images
                        print "Diffing... "
                        @image_handler.diff_images(width, name)

                        # Create thumbnails for gallery
                        print "Creating thumbnails... "
                        @image_handler.create_thumbnails(width, name)

                        puts "\n", ("=" * 85)
                    end
                end
            ensure
                @selenium_handler.cleanup
            end

            # Log diffs
            puts @image_handler.diffs

            # Create gallery
            puts "Creating gallery..."
            @gallery_creator.create_gallery

            # Upload to S3 (if not local)

            # Call "after" hook
            WebDiff.configuration.after_run

            end_time = Time.now
            puts "Time elapsed: #{(end_time - beginning_time)} seconds"
        end
    end
end