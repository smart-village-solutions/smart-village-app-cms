module Converter
  class Base
    def build_mutation(name, data, update = false, return_keys = "id")
      data = cleanup(data) unless name.downcase.include?("update") || update
      data = convert_to_json(data)
      data = convert_keys_to_camelcase(data)
      data = remove_quotes_from_keys(data)
      data = remove_quotes_from_boolean_values(data)

      # remove leading and tailing curly braces
      data = data.gsub(/^\{/, "").gsub(/\}$/, "")

      safe_parse("mutation { #{name} (forceCreate: true, #{data}) { #{return_keys} } }")
    end

    def cleanup(data)
      data.delete :id

      data
    end

    def convert_to_json(data)
      JSON.parse(data.to_json)
    end

    def convert_keys_to_camelcase(data)
      data.deep_transform_keys { |key| key.to_s.camelize(:lower) }
    end

    def remove_quotes_from_keys(data)
      json_string = data.to_json
      json_string.scan(/"\w*":/).uniq.each do |key|
        json_string.gsub!(key, key.delete('"'))
      end

      json_string
    end

    def remove_quotes_from_boolean_values(data)
      data.gsub!(":\"true\"", ":true")

      data
    end

    private

      # in https://github.com/github/graphql-client/blob/v0.15.0/lib/graphql/client.rb#L123-L167
      # there occur some errors when parsing strings with a certain regex, so we need to append
      # a space after "..." in the matched string
      def safe_parse(str)
        str.gsub(/(\.\.\.)([a-zA-Z0-9_]+(::[a-zA-Z0-9_]+)*)/) do
          match = Regexp.last_match
          "#{match[1]} #{match[2]}"
        end
      end
  end
end
