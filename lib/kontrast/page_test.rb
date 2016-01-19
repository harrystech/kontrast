require 'uri'
require 'rack'

module Kontrast
    class PageTest < Test

        attr_reader :width, :url_params

        def initialize(prefix, name, path, headers: {}, url_params: {})
            super(prefix, name, path, headers)
            @width = prefix
            @url_params = url_params
            @path = get_path_with_params(url_params)
        end

        def get_path_with_params(url_params)
            uri = URI(@path)
            original_query = Rack::Utils.parse_query(uri.query)
            new_query = url_params.merge(original_query)
            uri.query = Rack::Utils.build_query(new_query)
            return uri.to_s
        end
    end
end
