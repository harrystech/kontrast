require "erb"
require "json"
require "active_support/core_ext/hash"

module Kontrast
    class GalleryCreator
        def initialize(path)
            @path = path || Kontrast.path
        end

        # This gets run only once per suite. It collects the manifests from all nodes
        # and uses them to generate a nice gallery of images.
        def create_gallery(output_dir)
            begin
                @gallery_dir = FileUtils.mkdir_p("#{output_dir}/gallery").join('')
            rescue Exception => e
                raise GalleryException.new("An unexpected error occurred while trying to create the gallery's output directory: #{e.inspect}")
            end

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

            # Upload file
            if Kontrast.configuration.run_parallel
                Kontrast.fog.directories.get(Kontrast.configuration.aws_bucket).files.create(
                    key: "#{Kontrast.configuration.remote_path}/gallery/gallery.html",
                    body: File.open("#{@gallery_dir}/gallery.html")
                )
            end

            # Return diffs and gallery path
            return {
                diffs: diffs,
                path: "#{@gallery_dir}/gallery.html"
            }
        end

        def generate_html(files, diffs)
            # Template variables
            directories = parse_directories(files, diffs)

            # HTML
            template = File.read(Kontrast.root + '/lib/kontrast/gallery/template.erb')
            return ERB.new(template).result(binding)
        end

        def get_manifests
            if Kontrast.configuration.run_parallel
                # Download manifests
                files = Kontrast.fog.directories.get(Kontrast.configuration.aws_bucket, prefix: "#{Kontrast.configuration.remote_path}/manifest").files
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
            files.sort!

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

            # This determines where to display images from in the gallery
            if Kontrast.configuration.run_parallel
                # Build the remote path to S3
                base_path = "https://#{Kontrast.configuration.aws_bucket}.s3.amazonaws.com/#{Kontrast.configuration.remote_path}"
            else
                base_path = ".."
            end

            # Fill in the files as variants
            directories.each do |directory|
                array = directory.split('_')
                size = array.first
                array.delete_at(0)
                test_name = array.join('_')

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
