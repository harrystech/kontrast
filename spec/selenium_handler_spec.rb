describe Kontrast::SeleniumHandler do
	before :each do
		@handler = Kontrast::SeleniumHandler.new
	end

	after :each do
		@handler.cleanup
	end

	it "names Selenium drivers" do
		expect(@handler.instance_eval { @driver.name }).to eql "test"
		expect(@handler.instance_eval { @driver2.name }).to eql "production"
	end
end