require "yaml"
require "net/http"

module Kontrast
    class Runner
        def run
            # Make sure the local server is running
            wait_for_server

            # Assign nodes
            if Kontrast.configuration.run_parallel
                total_nodes = Kontrast.configuration.total_nodes
                current_node = Kontrast.configuration.current_node
            else
                # Override the config for local use
                total_nodes = 1
                current_node = 0
            end

            # Assign tests and run them
            suite = split_run(total_nodes, current_node)
            parallel_run(suite, current_node)
        end

        # Given the total number of nodes and the index of the current node,
        # we determine which tests the current node will run
        def split_run(total_nodes, current_node)
            test_suite = Kontrast.test_suite
            tests_to_run = TestSuite.new

            index = 0
            test_suite.tests.each do |test|
                if index % total_nodes == current_node
                    tests_to_run << test
                end
                index += 1
            end

            return tests_to_run
        end

        # Runs tests, handles all image operations, creates manifest for current node
        def parallel_run(suite, current_node)
            # Load test handlers
            @selenium_handler = SeleniumHandler.new
            @image_handler = ImageHandler.new

            begin
                # Run per-page tasks
                suite.tests.each do |test|
                    begin
                        print "Processing #{test.name} @ #{test.width}... "

                        # Run the browser and take screenshots
                        @selenium_handler.run_comparison(test)

                        # Crop images
                        print "Cropping... "
                        @image_handler.crop_images(test)

                        # Compare images
                        print "Diffing... "
                        @image_handler.diff_images(test)

                        # Create thumbnails for gallery
                        print "Creating thumbnails... "
                        @image_handler.create_thumbnails(test)

                        # Upload to S3
                        if Kontrast.configuration.run_parallel
                            print "Uploading... "
                            @image_handler.upload_images(test)
                        end

                        puts "\n", ("=" * 85)
                    rescue Net::ReadTimeout => e
                        puts "Test timed out. Message: #{e.inspect}"
                        if Kontrast.configuration.fail_build
                            raise e
                        end
                    end
                end

                # Log diffs
                puts @image_handler.diffs

                # Create manifest
                puts "Creating manifest..."
                if Kontrast.configuration.run_parallel
                    @image_handler.create_manifest(current_node, Kontrast.configuration.remote_path)
                else
                    @image_handler.create_manifest(current_node)
                end
            rescue Exception => e
                puts "Exception: #{e.inspect}"
                if Kontrast.configuration.fail_build
                    raise e
                end
            ensure
                @selenium_handler.cleanup
            end
        end

        private
            def wait_for_server
                # Test server
                tries = 30
                uri = URI(Kontrast.configuration.test_domain)
                begin
                    Net::HTTP.get(uri)
                rescue Errno::ECONNREFUSED => e
                    tries -= 1
                    if tries > 0
                        puts "Waiting for test server..."
                        sleep 2
                        retry
                    else
                        raise RunnerException.new("Could not reach the test server at '#{uri}'.")
                    end
                rescue Exception => e
                    raise RunnerException.new("An unexpected error occured while trying to reach the test server at '#{uri}': #{e.inspect}")
                end

                # Production server
                tries = 30
                uri = URI(Kontrast.configuration.production_domain)
                begin
                    Net::HTTP.get(uri)
                rescue Errno::ECONNREFUSED => e
                    tries -= 1
                    if tries > 0
                        puts "Waiting for production server..."
                        sleep 2
                        retry
                    else
                        raise RunnerException.new("Could not reach the production server at '#{uri}'.")
                    end
                rescue Exception => e
                    raise RunnerException.new("An unexpected error occured while trying to reach the production server at '#{uri}': #{e.inspect}")
                end
            end
    end
end
