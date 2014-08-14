namespace :web_diff do
    desc "Run the comparisons"
    task :run => :environment do
        WebDiff.run
    end
end