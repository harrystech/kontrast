module Kontrast
    class ApiEndpointRunner
        include ImageUploader
        include ThumbnailCreator

        attr_accessor :diffs

        def initialize
            @api_diff_comparator = ApiEndpointComparator.new
            @diffs = {}
        end

        def run(total_nodes, current_node)
            # Assign tests and run them
            suite = split_run(total_nodes, current_node)
            parallel_run(suite, current_node)
        end

        # Given the total number of nodes and the index of the current node,
        # we determine which tests the current node will run
        def split_run(total_nodes, current_node)
            test_suite = Kontrast.api_endpoint_test_suite
            # Load lazy tests
            # Some tests are lazy loaded from the initializer
            # In that case, we stored a block instead of adding a test to the
            # suite when reading the initializer
            # We need to execute the block, this will add the test to the suite
            # This is needed for tests that are dynamically defined: like,
            # get all the product pages in the DB and create a test for each
            # one.
            test_suite.lazy_tests.each do |lazy_test|
                Kontrast.api_endpoint_test_builder.prefix = lazy_test.prefix
                Kontrast.api_endpoint_test_builder.headers = lazy_test.headers
                lazy_test.block.call(Kontrast.api_endpoint_test_builder)
            end
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

        # Runs tests
        def parallel_run(suite, current_node)

            # Run per-page tasks
            suite.each do |test|
                begin
                    print "Processing #{test.name} @ #{test.prefix}... "

                    # Download the json file
                    # Create the diff hash, there
                    @api_diff_comparator.diff(test)

                    # Create thumbnails for gallery
                    print "Creating thumbnails... "
                    images = Dir.entries(File.join(Kontrast.path, test.to_s)).reject { |file_name|
                        ['.', '..'].include?(file_name) || file_name.include?('.json')
                    }

                    create_thumbnails(test, images)

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
            # We need the diff at the runner level to create the manifest
            @diffs = @api_diff_comparator.diffs
        end

    end
end
