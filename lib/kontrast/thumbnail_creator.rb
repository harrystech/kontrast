module Kontrast
  module ThumbnailCreator

    module_function

    def create_thumbnails(test, image_names)
      # Crop images
      Workers.map(image_names) do |image_name|
        src_path = File.join(Kontrast.path, test.to_s, image_name)

        # Resize to at least 200 width, the crop the top part of the image at 200x200
        # '+repage' means "don't keep the part of the image not shown in the crop"
        # http://www.imagemagick.org/discourse-server/viewtopic.php?t=18545
        options = '-resize "200x200^" -gravity North -crop 200x200+0+0 +repage'
        `convert "#{src_path}" #{options} "#{thumb_path(test, image_name)}"`
      end
    end

    def thumb_path(test, image_name)
        filename = "#{File.basename(image_name, ".*")}_thumb.png"
        File.join(Kontrast.path, test.to_s, filename)
    end
  end
end
