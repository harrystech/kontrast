module Kontrast
    class PageRunner
        include ImageUploader
        include ThumbnailCreator

        attr_reader :diffs

        def initialize
            @diffs = {}
            @selenium_handler = nil
            @page_comparator = nil
        end

        def run(total_nodes, current_node)
            # Nothing to run
            return if Kontrast.page_test_suite.nil?

            # Load & bind specs
            Kontrast.page_test_suite.bind_specs

            # Assign tests and run them
            suite = split_run(total_nodes, current_node)
            parallel_run(suite, current_node)
        end

        # Given the total number of nodes and the index of the current node,
        # we determine which tests the current node will run
        def split_run(total_nodes, current_node)
            test_suite = Kontrast.page_test_suite
            tests_to_run = []

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
            @page_comparator = PageComparator.new

            # Run per-page tasks
            suite.each do |test|
                begin
                    print "Processing #{test.name} @ #{test.width}... "

                    # Run the browser and take screenshots
                    @selenium_handler.run_comparison(test)

                    # Compare images
                    print "Diffing... "
                    @page_comparator.diff(test)

                    # Create thumbnails for gallery
                    print "Creating thumbnails... "
                    create_thumbnails(test, ['test.png', 'production.png', 'diff.png'])

                    # Upload to S3
                    if Kontrast.configuration.run_parallel
                        print "Uploading... "
                        upload_images(test)
                    end

                    puts "\n", ("=" * 85)
                rescue Net::ReadTimeout => e
                    puts "Test timed out. Message: #{e.inspect}"
                    if Kontrast.configuration.fail_build
                        raise e
                    end
                rescue StandardError => e
                    puts "Exception: #{e.inspect}"
                    puts e.backtrace.inspect
                    if Kontrast.configuration.fail_build
                        raise e
                    end
                end
            end
        ensure
            # Log diffs
            puts @page_comparator.diffs

            # We need the diff at the runner level to create the manifest
            @diffs = @page_comparator.diffs

            @selenium_handler.cleanup
        end
    end
end
