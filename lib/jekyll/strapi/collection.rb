require "net/http"
require "ostruct"
require "json"
module Jekyll
  module Strapi
    class StrapiCollection
      attr_accessor :collection_name, :config

      def initialize(site, collection_name, config)
        @site = site
        @collection_name = collection_name
        @config = config
      end

      def generate?
        @config['output'] || false
      end

      def each
        # Initialize the HTTP query
        path = "/#{@config['type'] || @collection_name}?_limit=10000#{@config['query'] || ''}"
        uri = URI("#{@site.endpoint}#{path}")
        
        result = nil

        if $result_uris.include?(uri)
          Jekyll.logger.info "Jekyll Strapi:", "Fetching #{@config['type']} from cache"
          result_index = $result_uris.index(uri)
          result = $result_data[result_index]
        else
          Jekyll.logger.info "Jekyll Strapi:", "Fetching #{@config['type']} from #{uri}"
          response = Net::HTTP.get_response(uri)
          if response.code == "200"
            result = JSON.parse(response.body, object_class: OpenStruct)
            $result_uris.push(uri)
            $result_data.push(result)
          elsif response.code == "401"
            raise "The Strapi server sent a error with the following status: #{response.code}. Please make sure you authorized the API access in the Users & Permissions section of the Strapi admin panel."
          else
            raise "The Strapi server sent a error with the following status: #{response.code}. Please make sure it is correctly running."
          end
        end

        # Add necessary properties
        result.each do |document|
          document.type = collection_name
          document.collection = collection_name
          document.id ||= document._id
          document.url = @site.strapi_link_resolver(collection_name, document)
        end

        result.each {|x| yield(x)}
      end
    end
  end
end
