require "RMagick"

module WebDiff
    class ImageHandler
        include Magick
        attr_reader :diffs

        def initialize(path)
            @path = path

            # This is where failed diffs will be stored
            @diffs = {}
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
    end
end