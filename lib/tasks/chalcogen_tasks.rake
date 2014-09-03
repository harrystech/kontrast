namespace :chalcogen do
    desc "Run the comparisons"
    task :run => :environment do
        Chalcogen.run
    end

    desc "Make the gallery"
    task :make_gallery, [:path] => :environment do |t, args|
        Chalcogen.make_gallery(args[:path])
    end

    desc "Run comparison tests and gallery creation locally"
    task :run_locally => :environment do
        Chalcogen.run
        Chalcogen.make_gallery(Chalcogen.path)
    end
end
