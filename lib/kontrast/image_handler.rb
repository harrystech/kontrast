require "RMagick"
require "workers"

module Kontrast
    class ImageHandler
        include Magick
        attr_reader :diffs, :path

        def initialize
            @path = Kontrast.path

            # This is where failed diffs will be stored
            @diffs = {}
        end

        # In order for images to be diff'ed, they need to have the same dimensions
        def crop_images(test)
            # Load images
            test_image = Image.read("#{@path}/#{test}/test.png").first
            production_image = Image.read("#{@path}/#{test}/production.png").first

            # Let's not do anything if the images are already the same size
            return if test_image.rows == production_image.rows

            # Get max height of both images
            max_height = [test_image.rows, production_image.rows].max

            # Crop
            Workers.map([test_image, production_image]) do |image|
                image.extent(test.width, max_height).write(image.filename)
            end
        end

        # Uses the compare_channel function to highlight the differences between two images
        # Docs: http://www.imagemagick.org/RMagick/doc/image1.html#compare_channel
        def diff_images(test)
            # Load images
            test_image = Image.read("#{@path}/#{test}/test.png").first
            production_image = Image.read("#{@path}/#{test}/production.png").first

            # Compare and save diff
            diff = test_image.compare_channel(production_image, Magick.const_get(Kontrast.configuration.distortion_metric)) do |options|
                options.highlight_color = Kontrast.configuration.highlight_color
                options.lowlight_color = Kontrast.configuration.lowlight_color
            end
            diff.first.write("#{@path}/#{test}/diff.png")

            # If the images are different, let the class know about it so that it gets added to the manifest
            if diff.last > 0
                @diffs["#{test}"] = {
                    width: test.width,
                    name: test.name,
                    diff: diff.last
                }
            end
        end

        # For the gallery. Not sure if this is really necessary.
        def create_thumbnails(test)
            # Load images
            test_image = Image.read("#{@path}/#{test}/test.png").first
            production_image = Image.read("#{@path}/#{test}/production.png").first
            diff_image = Image.read("#{@path}/#{test}/diff.png").first

            # Crop images
            Workers.map([test_image, production_image, diff_image]) do |image|
                filename = image.filename.split('/').last.split('.').first + "_thumb"
                image.resize_to_fill(200, 200, NorthGravity).write("#{@path}/#{test}/#{filename}.png")
            end
        end

        # We upload the images per test
        def upload_images(test)
            Workers.map(Dir.entries("#{@path}/#{test}")) do |file|
                next if ['.', '..'].include?(file)
                Kontrast.fog.directories.get(Kontrast.configuration.aws_bucket).files.create(
                    key: "#{Kontrast.configuration.remote_path}/#{test}/#{file}",
                    body: File.open("#{@path}/#{test}/#{file}"),
                    public: true
                )
            end
        end

        # The manifest is a per-node .json file that is used to create the gallery
        # without having to download all assets from S3 to the test environment
        def create_manifest(current_node, build = nil)
            # Set up structure
            manifest = {
                diffs: @diffs,
                files: []
            }

            # Dump directories
            Dir.foreach(@path) do |subdir|
                next if ['.', '..'].include?(subdir)
                next if subdir.index('manifest_')
                Dir.foreach("#{@path}/#{subdir}") do |img|
                    next if ['.', '..'].include?(img)
                    manifest[:files] << "#{subdir}/#{img}"
                end
            end

            if Kontrast.configuration.run_parallel
                # Upload manifest
                Kontrast.fog.directories.get(Kontrast.configuration.aws_bucket).files.create(
                    key: "#{build}/manifest_#{current_node}.json",
                    body: manifest.to_json
                )
            else
                # Write manifest
                File.open("#{@path}/manifest_#{current_node}.json", 'w') do |outf|
                    outf.write(manifest.to_json)
                end
            end

            return manifest
        end
    end
end