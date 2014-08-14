require "erb"

module WebDiff
    class GalleryCreator
        def initialize(path)
            @path = path
        end

        def create_gallery
            @directory = FileUtils.mkdir("#{@path}/gallery").join('')

            # Generate HTML
            html = generate_html

            # Write file
            File.open("#{@directory}/gallery.html", 'w') do |outf|
                outf.write(html)
            end
        end

        def generate_html
            # Template variables
            domain = @path.split('/').last
            directories = parse_directories(@path)

            # HTML
            template = File.read(WebDiff.root + '/lib/web_diff/gallery/template.erb')
            return ERB.new(template).result(binding)
        end

        def parse_directories(dirname)
            dirs = {}

            directories = Dir.foreach(dirname).select do |directory|
                if ['.', '..', 'gallery'].include? directory
                    # Ignore special dirs
                    false
                else
                    true
                end
            end

            # At this point, we have an array of all folders that ran for this test
            # Example: ["1280_sign_in", "320_sign_in"]
            # For each folder, get production, test, and diff images + thumbs

            # Get all sizes
            sizes = directories.map { |d| d.split('_').first }
            sizes.each { |size|
                dirs[size] = {}

                # Get all directories for this size
                tests_for_size = directories.select { |d| d.index(size + "_") == 0 }
                tests_for_size.each do |dir|
                    array = dir.split('_')
                    array.delete_at(0)
                    test_name = array.join('_')
                    dirs[size][test_name] = {
                        variants: []
                    }
                end
            }

            # Fill in the files as variants
            directories.each do |directory|
                array = directory.split('_')
                size = array.first
                array.delete_at(0)
                test_name = array.join('_')

                # Add variations
                ['test', 'production', 'diff'].each do |type|
                    if type == 'diff'
                        dirs[size][test_name][:variants] << {
                            image: type + ".png",
                            thumb: type + "_thumb.png",
                            domain: type,
                            size: 0.1
                        }
                    else
                        dirs[size][test_name][:variants] << {
                            image: type + ".png",
                            thumb: type + "_thumb.png",
                            domain: type
                        }
                    end
                end
            end

            return dirs

            # For reference
            # gallery_format = {
            #     "1080" => {
            #         "name" => {
            #             variants: [{
            #                 image: "full_img_src",
            #                 thumb: "thumb_src",
            #                 domain: "production"
            #             }, {
            #                 image: "foo_src",
            #                 thumb: "thumb_src",
            #                 domain: "test"
            #             }, {
            #                 image: "diff_src",
            #                 thumb: "diff_thumb_src",
            #                 domain: "diff",
            #                 size: 0.1
            #             }]
            #         }
            #     }
            # }
        end
    end
end
