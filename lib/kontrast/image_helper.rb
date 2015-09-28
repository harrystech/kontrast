require "RMagick"
require "workers"

module Kontrast

    class ImageHelper
        def initialize(img1_path, img2_path)
            @img1_path, @img2_path = img1_path, img2_path
            @img1 = load_image(@img1_path)
            @img2 = load_image(@img2_path)
            @path = Kontrast.path
        end

        def reload_images
            @img1 = load_image(@img1_path)
            @img2 = load_image(@img2_path)
        end

        def load_image(path)
            return Magick::Image.read(path).first
        end

        def crop(width)
            # Let's not do anything if the images are already the same size
            return if @img1.rows == @img2.rows

            # Get max height of both images
            max_height = [@img1.rows, @img2.rows].max

            # Crop
            Workers.map([@img1, @img2]) do |image|
                image.extent(width, max_height).write(image.filename)
            end
            reload_images
        end

        # Uses the compare_channel function to highlight the differences between
        # two images Docs:
        # http://www.rubydoc.info/github/gemhome/rmagick/Magick%2FImage%3Acompare_channel
        def compare(output_dir, output_file_name)
            begin
                distortion_metric = Magick.const_get(Kontrast.configuration.distortion_metric)
                diff = @img1.compare_channel(@img2, distortion_metric) do |options|
                    options.highlight_color = Kontrast.configuration.highlight_color
                    options.lowlight_color = Kontrast.configuration.lowlight_color
                end

                output_path = "#{Kontrast.path}/#{output_dir}"
                FileUtils.mkdir_p(output_path) # Just in case
                diff.first.write(File.join(output_path, output_file_name))

                # diff is an array, the last (second) value is the diff value,
                # a float between 0 and 1, 0 being the same image, 1 being an
                # entirely different image
                return diff.last
            rescue Magick::ImageMagickError => e
                puts "Error comparing images: #{e.message}"
                # 1 means that both images are different
                return 1
            end
        end
    end
end
