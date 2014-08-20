namespace :web_diff do
    desc "Run the comparisons"
    task :run => :environment do
        WebDiff.run
    end

    task :make_gallery, [:path] => :environment do |t, args|
        WebDiff.make_gallery(args[:path])
    end
end