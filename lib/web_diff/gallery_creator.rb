require "erb"

module WebDiff
    class GalleryCreator
        def initialize(path)
            @path = path
        end

        # This gets run only once per suite. It collects the manifests from all nodes
        # and uses them to generate a nice gallery of images.
        def create_gallery(dir_name)
            @gallery_dir = FileUtils.mkdir("#{@path}/gallery").join('')
            @build = dir_name

            # Get and parse manifests
            parsed_manifests = parse_manifests(get_manifests)
            files = parsed_manifests[:files]
            diffs = parsed_manifests[:diffs]

            # Generate HTML
            html = generate_html(files, diffs)

            # Write file
            File.open("#{@gallery_dir}/gallery.html", 'w') do |outf|
                outf.write(html)
            end

            if WebDiff.configuration.remote
                # Upload gallery file
                WebDiff.fog.directories.get(WebDiff.configuration.aws_bucket).files.create(
                    key: "#{@build}/gallery/gallery.html",
                    body: File.open("#{@gallery_dir}/gallery.html")
                )
            end
        end

        def generate_html(files, diffs)
            # Template variables
            domain = @path.split('/').last
            directories = parse_directories(files, diffs)

            # HTML
            template = File.read(WebDiff.root + '/lib/web_diff/gallery/template.erb')
            return ERB.new(template).result(binding)
        end

        def get_manifests
            if WebDiff.configuration.remote
                # Download manifests
                files = WebDiff.fog.directories.get(WebDiff.configuration.aws_bucket, prefix: "#{@build}/manifest").files
                files.each do |file|
                    filename = "#{@path}/" + file.key.split('/').last
                    File.open(filename, 'w') do |local_file|
                        local_file.write(file.body)
                    end
                end
            end
            manifest_files = Dir["#{@path}/manifest_*.json"]
            return manifest_files
        end

        def parse_manifests(manifest_files)
            files = []
            diffs = {}
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

        # This function just turns the list of files and diffs into a hash that the gallery
        # creator can insert into a template. See an example of the created hash below.
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

                # Set correct paths for image gallery
                if WebDiff.configuration.remote
                    base_path = WebDiff.configuration.upload_base_uri
                else
                    base_path = ".."
                end

                # Add variations
                ['test', 'production', 'diff'].each_with_index do |type, i|
                    dirs[size][test_name][:variants] << {
                        image: "#{base_path}/#{size}_#{test_name}/" + type + ".png",
                        thumb: "#{base_path}/#{size}_#{test_name}/" + type + "_thumb.png",
                        domain: type
                    }
                    if type == 'diff'
                        dirs[size][test_name][:variants][i][:diff_amt] = (diffs["#{size}_#{test_name}"]) ? diffs["#{size}_#{test_name}"]["diff"] : 0
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
