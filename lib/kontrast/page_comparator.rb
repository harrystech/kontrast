
module Kontrast
    class PageComparator
        include Magick
        attr_reader :diffs, :path

        def initialize
            @path = Kontrast.path

            # This is where failed diffs will be stored
            @diffs = {}
        end

        def test_image_path(test)
            return "#{@path}/#{test}/test.png"
        end

        def production_image_path(test)
            return "#{@path}/#{test}/production.png"
        end

        def diff(test)

            image_helper = Kontrast::ImageHelper.new(
                test_image_path(test),
                production_image_path(test),
            )

            # In order for images to be diff'ed, they need to have the same dimensions
            print "Cropping... "
            image_helper.crop(test.width)

            diff = image_helper.compare(test.to_s, "diff.png")

            # If the images are different, let the class know about it so that it gets added to the manifest
            if diff > 0
                @diffs["#{test}"] = {
                    type: 'page',
                    width: test.width,
                    name: test.name,
                    diff: diff,
                }
            end
        end
    end
end
