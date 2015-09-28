module Kontrast
    module ImageUploader
        def upload_images(test)
            Workers.map(Dir.entries("#{Kontrast.path}/#{test}")) do |file|
                next if ['.', '..'].include?(file)
                Kontrast.fog.directories.get(Kontrast.configuration.aws_bucket).files.create(
                    key: "#{Kontrast.configuration.remote_path}/#{test}/#{file}",
                    body: File.open("#{Kontrast.path}/#{test}/#{file}"),
                    public: true
                )
            end
        end

    end
end
