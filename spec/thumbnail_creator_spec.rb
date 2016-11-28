require 'spec_helper'

require 'kontrast'

describe Kontrast::ThumbnailCreator do
  let(:kontrast_path) { "/path/to/kontrast" }
  let(:test) { "home_1280" }
  let(:image_names) do
    [
      "diff_0.jpg",
      "test_0.jpg",
      "prod_0.jpg",
    ]
  end

  before do
    allow(Kontrast).to receive(:path).and_return(kontrast_path)
  end

  describe 'thumb_path' do
    it 'should return a png' do
      image_name = "diff_0.jpg"

      thumb_path = Kontrast::ThumbnailCreator.thumb_path(test, image_name)

      expect(thumb_path).to eql "#{kontrast_path}/#{test}/diff_0_thumb.png"
    end
  end

  describe 'create_thumbnails' do
    it 'creates thumbnails' do
      allow(Kontrast::ThumbnailCreator).to receive(:`)

      Kontrast::ThumbnailCreator.create_thumbnails(test, image_names)


      expect(Kontrast::ThumbnailCreator).to have_received(:`).with(/^convert.*/).exactly(3).times
    end
  end
end
