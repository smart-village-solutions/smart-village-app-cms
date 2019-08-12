module Converter
  class Base
    def build_mutation(name, entry)
      data = cleanup_and_convert_to_json(entry)
      data = convert_keys_to_camelcase(data)
      data = remove_quotes_from_keys(data)
      data = remove_quotes_from_boolean_values(data)

      # remove leading and tailing curly braces
      data = data.gsub(/^\{/, '').gsub(/\}$/, '')

      "mutation { #{name} (forceCreate: true, #{data}) {id} }"
    end

    def cleanup_and_convert_to_json(entry)
      entry.delete :id

      JSON.parse(entry.to_json)
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
      data.gsub!("\\\"true\\\"", "true")

      data
    end



    def send_mutation(mutation, token)
      url = Rails.application.credentials.target_server[:url]
      response = ApiRequestService.new(url, nil, nil, {query: mutation}, { Authorization: token }).post_request

      Rails.logger.error '#' * 30
      Rails.logger.error mutation
      Rails.logger.error '#' * 30
    end
  end
end
