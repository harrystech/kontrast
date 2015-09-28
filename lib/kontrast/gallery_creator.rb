require "erb"
require "json"

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
            rescue StandardError => e
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
            groups, without_diffs, with_diffs = parse_directories(files, diffs)

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
                diffs.merge!(manifest["diffs"])
            end

            return {
                files: files,
                diffs: diffs
            }
        end

        def test_name_from_dir(dir)
            # dir is a string prefixed with a group name:
            # '1280_home' or '2x_home_screen'
            return dir.split('_')[1..-1].join('_')
        end

        def base_path
            # This determines where to display images from in the gallery
            if Kontrast.configuration.run_parallel
                # Build the remote path to S3
                return "https://#{Kontrast.configuration.aws_bucket}.s3.amazonaws.com/#{Kontrast.configuration.remote_path}"
            else
                return ".."
            end
        end

        def variants_for_page(directory, diffs)
            # Return a hash that will be used in the erb template to show the
            # diffs for a given test.
            variants = []
            ['test', 'production', 'diff'].each do |type|
                variant = {
                    image: "#{base_path}/#{directory}/" + type + ".png",
                    thumb: "#{base_path}/#{directory}/" + type + "_thumb.png",
                    domain: type,
                    type: 'page',
                }
                if type == 'diff' && diffs[directory]
                    variant[:diff_amt] = diffs[directory]["diff"]
                end
                variants << variant
            end

            return variants
        end

        def variants_for_api_endpoint(directory, diffs, files)
            # Return a hash that will be used in the erb template to show the
            # diffs for a given test.
            variants = []
            ['test', 'production', 'diff'].each do |type|
                variant = {
                    file: "#{base_path}/#{directory}/#{type}.json",
                    domain: type,
                    type: 'api_endpoint',
                    diff_amt: 0,
                }
                if diffs[directory]
                    variant[:diff_amt] = 1
                end

                # Get all images
                image_files = files.select { |file_name|
                    file_name.match /#{directory}\/#{type}_\d+.(jpg|png)/
                }.map { |file_name|
                    name_without_extension = file_name.split('.')[0..-2].join('.')
                    {
                        image: "#{base_path}/#{file_name}",
                        thumb: "#{base_path}/#{name_without_extension}_thumb.png",
                    }
                }
                variant[:images] = image_files
                variants << variant
            end

            return variants
        end

        # This function just turns the list of files and diffs into a hash that the gallery
        # creator can insert into a template. See an example of the created hash below.
        def parse_directories(files, diffs)
            files.sort!

            # Initialize those hashes, where each key will map to hash, in wich
            # each key maps to an array:
            # {
            #   key1: {
            #   },
            #   key2: {
            #   },
            # }
            #
            without_diffs = Hash.new { |h,k| h[k] = {} }
            with_diffs = Hash.new { |h,k| h[k] = {} }

            directories = files.map { |f| f.split('/').first }.uniq
            groups = directories.map { |dir| dir.split('_').first }.uniq


            # Fill in the files as variants
            directories.each do |directory|
                group = directory.split('_')[0]
                test_name = test_name_from_dir(directory)

                # Determines the type of test by the presence of the diff.png
                # file in the folder.
                # Ideally the manifest file format would be different and
                # include the test type with
                if files.select { |file_name| file_name.start_with?(directory) }.any? { |file_name| file_name.include?('diff.png') }
                    variants = variants_for_page(directory, diffs)
                else
                    variants = variants_for_api_endpoint(directory, diffs, files)
                end

                if diffs[directory]
                    with_diffs[group][test_name] = variants
                else
                    without_diffs[group][test_name] = variants
                end
            end

            return groups, without_diffs, with_diffs

            # For reference
            # gallery_format = {
            #     "1080" => {
            #         "name" => [
            #             {
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
            #                 diff_amt: 0.1
            #             }
            #         }
            #     }
            # }
        end
    end
end
