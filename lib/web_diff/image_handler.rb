require "RMagick"
require "fog"

module WebDiff
    class ImageHandler
        include Magick
        attr_reader :diffs

        def initialize(path)
            @path = path

            # This is where failed diffs will be stored
            @diffs = {}

            @fog = Fog::Storage.new({
                :provider                 => 'AWS',
                :aws_access_key_id        => WebDiff.configuration.aws_key,
                :aws_secret_access_key    => WebDiff.configuration.aws_secret
            })
        end

        def crop_images(width, name)
            # Load images
            test_image = Image.read("#{@path}/#{width}_#{name}/test.png").first
            production_image = Image.read("#{@path}/#{width}_#{name}/production.png").first

            # Get max height of both images
            max_height = [test_image.rows, production_image.rows].max

            # Crop
            test_image.extent(width, max_height).write(test_image.filename)
            production_image.extent(width, max_height).write(production_image.filename)
        end

        def diff_images(width, name)
            # Load images
            test_image = Image.read("#{@path}/#{width}_#{name}/test.png").first
            production_image = Image.read("#{@path}/#{width}_#{name}/production.png").first

            # Compare and save diff
            diff = test_image.compare_channel(production_image, Magick.const_get(WebDiff.configuration.distortion_metric)) do |options|
                options.highlight_color = WebDiff.configuration.highlight_color
                options.lowlight_color = WebDiff.configuration.lowlight_color
            end
            diff.first.write("#{@path}/#{width}_#{name}/diff.png")

            # Is the file actually different?
            if diff.last > 0
                @diffs["#{width}_#{name}"] = {
                    width: width,
                    name: name,
                    diff: diff.last
                }
            end
        end

        def create_thumbnails(width, name)
            # Load images
            test_image = Image.read("#{@path}/#{width}_#{name}/test.png").first
            production_image = Image.read("#{@path}/#{width}_#{name}/production.png").first
            diff_image = Image.read("#{@path}/#{width}_#{name}/diff.png").first

            # Crop images
            test_image.resize_to_fill(200, 200, NorthGravity).write("#{@path}/#{width}_#{name}/test_thumb.png")
            production_image.resize_to_fill(200, 200, NorthGravity).write("#{@path}/#{width}_#{name}/production_thumb.png")
            diff_image.resize_to_fill(200, 200, NorthGravity).write("#{@path}/#{width}_#{name}/diff_thumb.png")
        end

        def create_manifest(current_node)
            # Set up structure
            manifest = {
                diffs: @diffs,
                files: []
            }

            # Dump directories
            Dir.foreach(@path) do |subdir|
                next if ['.', '..'].include?(subdir)
                Dir.foreach("#{@path}/#{subdir}") do |img|
                    next if ['.', '..'].include?(img)
                    manifest[:files] << "#{subdir}/#{img}"
                end
            end

            # Write manifest
            File.open("#{@path}/manifest_#{current_node}.json", 'w') do |outf|
                outf.write(manifest.to_json)
            end

            return manifest
        end

        def upload_manifest(current_node, dir_name)
            @fog.directories.get("circle-artifacts").files.create(
                key: "artifacts.#{dir_name}/manifest_#{current_node}.json",
                body: File.open("#{@path}/manifest_#{current_node}.json")
            )
        end

        def upload_images(dir_name)
            Dir.foreach(@path) do |subdir|
                next if ['.', '..'].include?(subdir)
                Dir.foreach("#{@path}/#{subdir}") do |img|
                    next if ['.', '..'].include?(img)
                    @fog.directories.get("circle-artifacts").files.create(
                        key: "artifacts.#{dir_name}/#{subdir}/#{img}",
                        body: File.open("#{@path}/#{subdir}/#{img}"),
                        public: true
                    )
                end
            end
        end
    end
end