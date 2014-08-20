require "erb"
require "fog"

module WebDiff
    class GalleryCreator
        def initialize(path)
            @path = path
            @fog = Fog::Storage.new({
                :provider                 => 'AWS',
                :aws_access_key_id        => WebDiff.configuration.aws_key,
                :aws_secret_access_key    => WebDiff.configuration.aws_secret
            })
        end

        def create_gallery(dir_name)
            @directory = FileUtils.mkdir("#{@path}/gallery").join('')

            # Generate HTML
            html = generate_html

            # Write file
            File.open("#{@directory}/gallery.html", 'w') do |outf|
                outf.write(html)
            end

            # Upload file
            @fog.directories.get("circle-artifacts").files.create(
                key: "artifacts.#{dir_name}/gallery/gallery.html",
                body: File.open("#{@directory}/gallery.html")
            )
        end

        def generate_html
            # Parse manifests
            parsed_manifests = parse_manifests
            files = parsed_manifests[:files]
            diffs = parsed_manifests[:diffs]

            # Template variables
            domain = @path.split('/').last
            directories = parse_directories(files, diffs)

            # HTML
            template = File.read(WebDiff.root + '/lib/web_diff/gallery/template.erb')
            return ERB.new(template).result(binding)
        end

        def parse_manifests
            files = []
            diffs = {}
            manifest_files = Dir["#{@path}/manifest_*.json"]
            manifest_files.each do |manifest|
                manifest = JSON.parse(File.read(manifest))
                files.concat(manifest['files'])
                diffs.reverse_merge!(manifest["diffs"])
            end

            return {
                files: files,
                diffs: diffs
            }
        end

        def parse_directories(files, diffs)
            dirs = {}
            directories = files.map { |f| f.split('/').first }.uniq

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
                            image: "../#{size}_#{test_name}/" + type + ".png",
                            thumb: "../#{size}_#{test_name}/" + type + "_thumb.png",
                            domain: type,
                            diff_amt: (diffs["#{size}_#{test_name}"]) ? diffs["#{size}_#{test_name}"]["diff"] : 0
                        }
                    else
                        dirs[size][test_name][:variants] << {
                            image: "../#{size}_#{test_name}/" + type + ".png",
                            thumb: "../#{size}_#{test_name}/" + type + "_thumb.png",
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
