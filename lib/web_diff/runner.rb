require "yaml"

module WebDiff    
    class Runner
        def initialize
            # Load config
            begin
                @config = YAML::load(File.open(Rails.root + "config/web_diff.yml"))
            rescue Errno::ENOENT => e
                puts "Could not load the config file."
                raise e
            end

            # Ensure output path for this set of tests
            if ENV['CIRCLE_ARTIFACTS']
                @output_path = FileUtils.mkdir(ENV['CIRCLE_ARTIFACTS'] + "shots").join('')
            elsif Dir.exists?(Rails.root + "tmp/shots")
                @output_path = FileUtils.mkdir(Rails.root + "tmp/shots/#{Time.now.to_i}").join('')
            else
                FileUtils.mkdir(Rails.root + "tmp/shots")
                @output_path = FileUtils.mkdir(Rails.root + "tmp/shots/#{Time.now.to_i}").join('')
            end

            @fog = Fog::Storage.new({
                :provider                 => 'AWS',
                :aws_access_key_id        => WebDiff.configuration.aws_key,
                :aws_secret_access_key    => WebDiff.configuration.aws_secret
            })
        end

        def run
            # Load required classes
            @selenium_handler = SeleniumHandler.new(@output_path, @config)
            @image_handler = ImageHandler.new(@output_path)
            @gallery_creator = GalleryCreator.new(@output_path)

            # Parallelism setup
            total_nodes = ENV["CIRCLE_NODE_TOTAL"] ? ENV["CIRCLE_NODE_TOTAL"].to_i : 1
            current_node = ENV["CIRCLE_NODE_INDEX"] ? ENV["CIRCLE_NODE_INDEX"].to_i : 0

            # Assign tests and run them
            to_run = split_run(total_nodes, current_node)
            parallel_run(to_run)

            # Create and upload manifest
            dir_name = ENV["CIRCLE_BUILD_NUM"]
            @fog.directories.get("circle-artifacts").files.create(
                key: "artifacts.#{dir_name}/manifest_#{current_node}.json",
                body: {
                    diffs: @image_handler.diffs
                }.to_json
            )

            # Create gallery
            # puts "Creating gallery..."
            # @gallery_creator.create_gallery(@image_handler.diffs, ENV["CIRCLE_BUILD_NUM"])
        end

        def split_run(total_nodes, current_node)
            all_tests = @config['pages']
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

        def parallel_run(tests)
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
                        if true # remote option?
                            print "Uploading... "
                            @image_handler.upload_images(ENV["CIRCLE_BUILD_NUM"])
                        end

                        puts "\n", ("=" * 85)
                    end
                end

                # Log diffs
                puts @image_handler.diffs
            ensure
                @selenium_handler.cleanup
            end
        end
    end
end