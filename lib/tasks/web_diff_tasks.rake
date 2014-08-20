namespace :web_diff do
    desc "Run the comparisons"
    task :run => :environment do
        WebDiff.run
    end

    task :make_gallery => :environment do
        WebDiff.make_gallery
    end
end