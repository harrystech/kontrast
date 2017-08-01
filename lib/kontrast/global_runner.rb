require "yaml"
require "net/http"

module Kontrast
    class GlobalRunner

        def initialize
            @page_runner = PageRunner.new
            @api_endpont_runner = ApiEndpointRunner.new
            @path = Kontrast.path
            @current_node = 0
        end

        def run
            # Make sure the local server is running
            wait_for_server

            # Assign nodes
            if Kontrast.configuration.run_parallel
                total_nodes = Kontrast.configuration.total_nodes
                @current_node = Kontrast.configuration.current_node
            else
                # Override the config for local use
                total_nodes = 1
            end

            # Run both runners
            @page_runner.run(total_nodes, @current_node)
            @api_endpont_runner.run(total_nodes, @current_node)

            # Create manifest
            create_manifest
        end

        # The manifest is a per-node .json file that is used to create the gallery
        # without having to download all assets from S3 to the test environment
        def create_manifest
            # Create manifest
            puts "Creating manifest..."
            if Kontrast.configuration.run_parallel
                build = Kontrast.configuration.remote_path
            else
                build = nil
            end

            diffs = {}
            diffs.merge!(@page_runner.diffs)
            diffs.merge!(@api_endpont_runner.diffs)

            # Set up structure
            manifest = {
                diffs: diffs,
                files: []
            }

            # Dump directories
            Dir.foreach(@path) do |subdir|
                next if ['.', '..'].include?(subdir)
                next if subdir.index('manifest_')
                Dir.foreach("#{@path}/#{subdir}") do |img|
                    next if ['.', '..'].include?(img)
                    manifest[:files] << "#{subdir}/#{img}"
                end
            end

            if Kontrast.configuration.run_parallel
                # Upload manifest
                Kontrast.fog.directories.get(Kontrast.configuration.aws_bucket).files.create(
                    key: "#{build}/manifest_#{@current_node}.json",
                    body: manifest.to_json
                )
            else
                # Write manifest
                File.open("#{@path}/manifest_#{@current_node}.json", 'w') do |outf|
                    outf.write(manifest.to_json)
                end
            end

            return manifest
        end

        private
            def wait_for_server
                # Test server
                tries = 30
                uri = URI(Kontrast.configuration.test_domain)
                begin
                    Net::HTTP.get(uri)
                rescue Errno::ECONNREFUSED, EOFError => e
                    tries -= 1
                    if tries > 0
                        puts "Waiting for test server..."
                        sleep 2
                        retry
                    else
                        raise RunnerException.new("Could not reach the test server at '#{uri}'.")
                    end
                rescue StandardError => e
                    raise RunnerException.new("An unexpected error occured while trying to reach the test server at '#{uri}': #{e.inspect}")
                end

                # Production server
                tries = 30
                uri = URI(Kontrast.configuration.production_domain)
                begin
                    Net::HTTP.get(uri)
                rescue Errno::ECONNREFUSED => e
                    tries -= 1
                    if tries > 0
                        puts "Waiting for production server..."
                        sleep 2
                        retry
                    else
                        raise RunnerException.new("Could not reach the production server at '#{uri}'.")
                    end
                rescue StandardError => e
                    raise RunnerException.new("An unexpected error occured while trying to reach the production server at '#{uri}': #{e.inspect}")
                end
            end
    end
end
