require 'uri'
require 'rack'

module Kontrast
    class PageTest < Test

        attr_reader :width, :url_params

        def initialize(prefix, name, path, headers: {}, url_params: {})
            super(prefix, name, path, headers)
            @width = prefix
            @url_params = url_params

            if url_params.any?
                uri = URI(@path)
                uri.query = Rack::Utils.build_query(url_params)
                @path = uri.to_s
            end
        end
    end
end
