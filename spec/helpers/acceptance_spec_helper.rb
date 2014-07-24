def document_media_requests
  # this is here so rspec_api_documentation can be generated
  # any request that returns content that cannot be json serialised (e.g. binary data)
  # will cause generating the documentation to fail
  if ENV['GENERATE_DOC']
    false
  else
    true
  end
end

def standard_request(description, expected_status, expected_json_path = nil, document = true, response_body_content = nil, invalid_content = nil)
  # Execute request with ids defined in above let(:id) statements
  example "#{description} - #{expected_status}", :document => document do
    do_request

    actual_response = response_body
    the_request_method = method
    the_request_path = path

    message_prefix =  "Requested #{the_request_method} #{the_request_path} expecting"

    status.should eq(expected_status), "#{message_prefix} status #{expected_status} but got status #{status}. Response body was #{actual_response}"

    actual_response.should have_json_path(expected_json_path), "#{message_prefix} to find '#{expected_json_path}' in '#{actual_response}'" unless expected_json_path.blank?
    # this check ensures that there is an assertion when the content is not blank.
    #expect(actual_response).to be_blank, "#{message_prefix} blank response, but got #{actual_response}" if response_body_content.blank? && expected_json_path.blank?
    expect(actual_response).to include(response_body_content), "#{message_prefix} to find '#{response_body_content}' in '#{actual_response}'" unless response_body_content.blank?
    expect(actual_response).to_not include(invalid_content), "#{message_prefix} not to find '#{response_body_content}' in '#{actual_response}'" unless invalid_content.blank?

    if block_given?
      yield(actual_response)
    end

    actual_response
  end
end

def check_site_lat_long_response(description, expected_status, should_be_obfuscated = true)
  example "#{description} - #{expected_status}", document: false do
    do_request
    status.should eq(expected_status), "Requested #{path} expecting status #{expected_status} but got status #{status}. Response body was #{response_body}"
    response_body.should have_json_path('location_obfuscated'), response_body.to_s
    #response_body.should have_json_type(Boolean).at_path('location_obfuscated'), response_body.to_s
    site = JSON.parse(response_body)

    #'Accurate to with a kilometre (± 1000m)'

    lat = site['latitude']
    long = site['longitude']

    if should_be_obfuscated
      min = 3
      max = 6
      expect(lat.to_s.split('.').last.size)
      .to satisfy { |v| v >= min && v <= max },
          "expected latitude to be obfuscated to between #{min} to #{max} places, "+
              "got #{lat.to_s.split('.').last.size} from #{lat}"

      expect(long.to_s.split('.').last.size)
      .to satisfy { |v| v >= min && v <= max },
          "expected longitude to be obfuscated to between #{min} to #{max} places, "+
              "got #{long.to_s.split('.').last.size} from #{long}"
    end
  end
end