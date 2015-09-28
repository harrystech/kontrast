module Kontrast
    module ThumbnailCreator

        def create_thumbnails(test, image_names)
            # Load images
            images = image_names.map do |image|
                Magick::Image.read(File.join(Kontrast.path, test.to_s, image)).first
            end

            # Crop images
            Workers.map(images) do |image|
                filename = image.filename.split('/').last.split('.').first + "_thumb"
                full_path = "#{Kontrast.path}/#{test}/#{filename}.png"
                image.resize_to_fill(200, 200, Magick::NorthGravity).write(full_path)
            end
        end
    end
end
