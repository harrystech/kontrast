module Kontrast
    module ImageUploader
        def upload_images(test)
            worker_pool = Workers::Pool.new
            worker_pool.resize(Kontrast.configuration.workers_pool_size)

            Workers.map(Dir.entries("#{Kontrast.path}/#{test}"), pool: worker_pool) do |file|
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
