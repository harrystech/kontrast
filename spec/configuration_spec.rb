describe Kontrast::Configuration do
    it "can set basic options" do
        Kontrast.configure do |config|
            config.test_domain = "http://google.com"
        end
        expect(Kontrast.configuration.test_domain).to eql "http://google.com"
    end

    it "cannot set options that don't exist" do
        expect {
            Kontrast.configure do |config|
                config.foo = "bar"
            end
        }.to raise_error(NoMethodError)
    end

    it "sets defaults" do
        # Set up a config block with no options
        Kontrast.configure do |config|
        end

        # Check that we have some defaults
        expect(Kontrast.configuration.browser_driver).to eql "firefox"
        expect(Kontrast.configuration.run_parallel).to eql false
        expect(Kontrast.configuration.distortion_metric).to eql "MeanAbsoluteErrorMetric"
    end

    it "sets up and runs blocks" do
        Kontrast.configure do |config|
            config.before_run do
                x = 1
                x += 1
                # Implicit return of x
            end
        end
        expect(Kontrast.configuration.before_run).to eql 2
    end

    it "passes data to some blocks" do
        Kontrast.configure do |config|
            config.after_gallery do |diffs, gallery|
                {
                    diffs: diffs,
                    gallery: gallery
                }
            end
        end
        expect(Kontrast.configuration.after_gallery("arg1", "arg2")).to eql({
            diffs: "arg1",
            gallery: "arg2"
        })
    end

    context "workers pool size" do
        before do
            Kontrast.configuration = nil
            Kontrast.configure {}
        end

        it "defaults to 5" do
            expect(Kontrast.configuration.workers_pool_size).to eq(5)
        end

        it "can be overriden" do
            Kontrast.configure do |config|
                config.workers_pool_size = 10
            end

            expect(Kontrast.configuration.workers_pool_size).to eq(10)
        end
    end
end
