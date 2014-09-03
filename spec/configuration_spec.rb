describe WebDiff::Configuration do
    it "can set basic options" do
        WebDiff.configure do |config|
            config.test_domain = "http://google.com"
        end
        expect(WebDiff.configuration.test_domain).to eql "http://google.com"
    end

    it "cannot set options that don't exist" do
        expect {
            WebDiff.configure do |config|
                config.foo = "bar"
            end
        }.to raise_error(NoMethodError)
    end

    it "sets defaults" do
        # Set up a config block with no options
        WebDiff.configure do |config|
        end

        # Check that we have some defaults
        expect(WebDiff.configuration.browser_driver).to eql "firefox"
        expect(WebDiff.configuration.run_parallel).to eql false
        expect(WebDiff.configuration.distortion_metric).to eql "MeanAbsoluteErrorMetric"
    end

    it "sets up and runs blocks" do
        WebDiff.configure do |config|
            config.before_run do
                x = 1
                x += 1
                # Implicit return of x
            end
        end
        expect(WebDiff.configuration.before_run).to eql 2
    end

    it "passes data to some blocks" do
        WebDiff.configure do |config|
            config.after_gallery do |diffs, gallery|
                {
                    diffs: diffs,
                    gallery: gallery
                }
            end
        end
        expect(WebDiff.configuration.after_gallery("arg1", "arg2")).to eql({
            diffs: "arg1",
            gallery: "arg2"
        })
    end
end
