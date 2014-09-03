namespace :chalcogen do
    desc "Run the comparisons"
    task :run => :environment do
        Chalcogen.run
    end

    desc "Make the gallery"
    task :make_gallery, [:path] => :environment do |t, args|
        Chalcogen.make_gallery(args[:path])
    end
end
