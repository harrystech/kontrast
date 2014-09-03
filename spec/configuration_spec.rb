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
end
