namespace :web_diff do
    desc "Run the comparisons"
    task :run => :environment do
        WebDiff.run
    end

    desc "Make the gallery"
    task :make_gallery, [:path] => :environment do |t, args|
        WebDiff.make_gallery(args[:path])
    end

    desc "Run comparison tests and gallery creation locally"
    task :run_locally => :environment do
        WebDiff.run
        WebDiff.make_gallery(WebDiff.path)
    end
end