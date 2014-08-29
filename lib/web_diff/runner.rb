require "yaml"
require "net/http"

module WebDiff
    class Runner
        def initialize
        end

        def run
            # Wait for local server to load for 20 seconds
            tries = 20
            uri = URI(WebDiff.configuration.test_domain)
            begin
                Net::HTTP.get(uri)
            rescue Errno::ECONNREFUSED => e
                tries -= 1
                if tries > 0
                    puts "Waiting for server..."
                    sleep 1
                    retry
                end
            end

            # Parallelism setup
            # We always assume some kind of "parallelism" even if we only have 1 node
            total_nodes = WebDiff.configuration.run_parallel ? WebDiff.configuration.total_nodes : 1
            current_node = WebDiff.configuration.run_parallel ? WebDiff.configuration.current_node : 0

            # Assign tests and run them
            to_run = split_run(total_nodes, current_node)
            parallel_run(to_run, current_node)
        end

        # Given the total number of nodes and the index of the current node,
        # we determine which tests the current node will run
        def split_run(total_nodes, current_node)
            all_tests = WebDiff.test_suite.tests
            tests_to_run = Hash.new

            index = 0
            all_tests.each do |width, pages|
                next if pages.nil?
                tests_to_run[width] = {}
                pages.each do |name, path|
                    if index % total_nodes == current_node
                        tests_to_run[width][name] = path
                    end
                    index += 1
                end
            end

            return tests_to_run
        end

        # Runs tests, handles all image operations, creates manifest for current node
        def parallel_run(tests, current_node)
            # Load test handlers
            @selenium_handler = SeleniumHandler.new
            @image_handler = ImageHandler.new

            begin
                # Run per-page tasks
                tests.each do |width, pages|
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

                        # Upload to S3
                        if WebDiff.configuration.remote
                            print "Uploading... "
                            @image_handler.upload_images(width, name)
                        end

                        puts "\n", ("=" * 85)
                    end
                end

                # Log diffs
                puts @image_handler.diffs

                # Create manifest
                puts "Creating manifest..."
                if WebDiff.configuration.remote
                    @image_handler.create_manifest(current_node, WebDiff.configuration.remote_path)
                else
                    @image_handler.create_manifest(current_node)
                end
            ensure
                @selenium_handler.cleanup
            end
        end
    end
end