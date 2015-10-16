require "workers"
require "kontrast/api_client"

module Kontrast
    class ApiEndpointComparator
        attr_reader :diffs, :prod_client, :test_client

        def initialize

            @prod_client = Kontrast::ApiClient.new(
                'production',
                Kontrast.configuration.production_domain,
                Kontrast.configuration.production_oauth_app_uid,
                Kontrast.configuration.production_oauth_app_secret,
            )

            test_oauth_app = Kontrast.configuration.test_oauth_app_proc.call
            @test_client = Kontrast::ApiClient.new(
                'test',
                Kontrast.configuration.test_domain,
                test_oauth_app.uid,
                test_oauth_app.secret,
            )

            @image_index = 0

            @result = {}

            # This is where failed diffs will be stored
            @diffs = {}
        end

        def diff(test)
            @image_index = 0
            @prod_client.headers = test.headers
            @test_client.headers = test.headers

            # Create the folder
            FileUtils.mkdir_p(File.join(Kontrast.path, test.to_s))

            Workers.map([@test_client, @prod_client]) do |client|
                client.fetch(test.path, save_file: true, folder_name: test.to_s)
            end

            @diffs[test.to_s] = {images: []}
            if !compare(@prod_client.responses[test.path], @test_client.responses[test.path], test)
                @diffs[test.to_s].merge!({
                    type: 'api_endpoint',
                    name: test.name,
                    diff: 1,
                })
            else
                # Clear the diff
                @diffs.delete test.to_s
            end
        end

        def compare(prod_data, test_data, test, key: nil)

            if prod_data == test_data
                return true
            elsif is_image_string?(prod_data, key)
                # If it's an image, we need to compare both files
                if compare_images(prod_data, test_data, test)
                    return true
                else
                    diff_details = { index: @image_index - 1 }
                    @diffs[test.to_s][:images] << diff_details
                    return false
                end
            elsif prod_data.is_a?(Hash)
                return false if prod_data.keys != test_data.keys

                return prod_data.map do |key, value|
                    compare(prod_data[key], test_data[key], test, key: key)
                end.all?
            elsif prod_data.is_a?(Array) # Make it more generic?
                return false if prod_data.length != test_data.length

                return prod_data.map.with_index do |value, i|
                    compare(prod_data[i], test_data[i], test)
                end.all?
            else
                return false
            end
        end

        def is_image_string?(image_string, key)
            # Either a URL or a local path
            if !key.nil? && key != ''
                return key.match(/(image|url)/) && image_string.is_a?(String)
            else
                return image_string.is_a?(String) && image_string.match(/^(http|\/)/)
            end
        end

        def compare_images(prod_image, test_image, test)
            images = [
                {'env' => 'production', 'image' => prod_image},
                {'env' => 'test', 'image' => test_image},
            ]
            files = Workers.map(images) do |image|
                load_image_file(image['image'], test, image['env'])
            end

            image_helper = Kontrast::ImageHelper.new(files[0].path, files[1].path)

            diff = image_helper.compare(test.to_s, "diff_#{@image_index}.png")

            @image_index += 1
            return diff == 0
        end

        def load_image_file(image, test, prefix)
            if image.start_with?('http')
                extension = image.split('.')[-1]
                file_name = "#{prefix}_#{@image_index}.#{extension}"
                open(File.join(Kontrast.path, test.to_s, file_name), 'wb') do |file|
                    file << open(image).read
                end
            else
                File.new(image)
            end
        end
    end
end
