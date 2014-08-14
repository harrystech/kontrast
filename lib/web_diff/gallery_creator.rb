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
            domain = @path.split('/')[1]
            directories = parse_directories(@path)

            # HTML
            template = File.read('lib/gallery/template.erb')
            return ERB.new(template).result(binding)
        end

        def parse_directories(dirname)
            dirs = {}

            categories = Dir.foreach(dirname).select do |category|
                if ['.', '..', 'gallery'].include? category
                    # Ignore special dirs
                    false
                else
                    true
                end
            end

            categories.each do |category|
                dirs[category] = {}
                Dir.foreach("#{dirname}/#{category}") do |filename|
                    next if ['.', '..'].include? filename

                    # Size
                    size = filename.split('_').first
                    dirs[category][size] = {}
                end
            end

            return dirs

            # Actual format...
            return {
                "directory_name" => {
                    "1080" => {
                        variants: [{
                            filename: "test_link",
                            thumb: "src",
                            name: "production"
                        }, {
                            filename: "test_link_2",
                            thumb: "src_2",
                            name: "test"
                        }],
                        diff: {
                            filename: "link_to_diff",
                            thumb: "src_of_diff"
                        },
                        data: 111
                    }
                }
            }
        end
    end
end
