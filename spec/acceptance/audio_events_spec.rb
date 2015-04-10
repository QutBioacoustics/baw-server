require 'spec_helper'
require 'rspec_api_documentation/dsl'
require 'helpers/acceptance_spec_helper'

def library_request(settings = {})
  description = settings[:description]
  expected_status = settings[:expected_status]
  expected_json_path = settings[:expected_json_path]
  document = settings[:document]
  response_body_content = settings[:response_body_content]

  example "#{description} - #{expected_status}", :document => document do
    do_request

    expect(status).to eq(expected_status), "Requested #{path} expecting status #{expected_status} but got status #{status}. Response body was #{response_body}"

    unless expected_json_path.blank?
      response_body.should have_json_path(expected_json_path), "could not find #{expected_json_path} in #{response_body}"
    end

    unless response_body_content.blank?
      expect(response_body).to include(response_body_content)
    end

    parsed_response_body = JsonSpec::Helpers::parse_json(response_body)

    if !ordered_audio_recordings.blank? && ordered_audio_recordings.respond_to?(:each_index) &&
        !parsed_response_body.blank? && parsed_response_body.respond_to?(:each_index)
      parsed_response_body.each_index do |index|
        expect(parsed_response_body[index]['audio_event_id'])
            .to eq(ordered_audio_recordings[index]),
                "Result body index #{index} in #{ordered_audio_recordings}: #{parsed_response_body}"
      end
      ordered_audio_recordings.each_index do |index|
        expect(ordered_audio_recordings[index])
            .to eq(parsed_response_body[index]['audio_event_id']),
                "Audio Event Order index #{index} in #{ordered_audio_recordings}: #{parsed_response_body}"
      end
    end

  end
end

# https://github.com/zipmark/rspec_api_documentation
resource 'AudioEvents' do
  # set header
  header 'Accept', 'application/json'
  header 'Content-Type', 'application/json'
  header 'Authorization', :authentication_token

  # default format
  let(:format) { 'json' }

  before(:each) do
    # this creates a @write_permission.user with write access to @write_permission.project,
    # a @read_permission.user with read access, as well as
    # a site, audio_recording and audio_event having off the project (see permission_factory.rb)
    @write_permission = FactoryGirl.create(:write_permission) # has to be 'write' so that the uploader has access
    @read_permission = FactoryGirl.create(:read_permission, project: @write_permission.project)
    @existing_tag = FactoryGirl.create(:tag, text: 'existing')
    @admin_user = FactoryGirl.create(:admin)
  end

  # prepare ids needed for paths in requests below
  #let(:project_id) { @write_permission.project.id }
  #let(:site_id) { @write_permission.project.sites.order(:id).first.id }
  let(:audio_recording_id) { @write_permission.project.sites.order(:id).first.audio_recordings.order(:id).first.id }
  #  freq diff 5600, duration diff 0.6, start_time_seconds 5.2, low_frequency_hertz 400, high_frequency_hertz 6000, end_time_seconds 5.8
  let(:id) { @write_permission.project.sites.order(:id).first.audio_recordings.order(:id).first.audio_events.order(:id).first.id }

  # prepare authentication_token for different users
  let(:writer_token) { "Token token=\"#{@write_permission.user.authentication_token}\"" }
  let(:reader_token) { "Token token=\"#{@read_permission.user.authentication_token}\"" }
  let(:other_user_token) { "Token token=\"#{FactoryGirl.create(:user).authentication_token}\"" }
  let(:unconfirmed_token) { "Token token=\"#{FactoryGirl.create(:unconfirmed_user).authentication_token}\"" }
  let(:admin_token) { "Token token=\"#{@admin_user.authentication_token}\"" }
  let(:invalid_token) { "Token token=\"blah_blah_blah\"" }

  # Create post parameters from factory
  let(:post_attributes) { FactoryGirl.attributes_for(:audio_event) }
  let(:post_nested_attributes) {
    {tags_attributes: [
        FactoryGirl.attributes_for(:tag),
        {
            is_taxanomic: @existing_tag.is_taxanomic,
            text: @existing_tag.text,
            type_of_tag: @existing_tag.type_of_tag,
            retired: @existing_tag.retired
        }
    ]}
  }

  ################################
  # LIST
  ################################
  get '/audio_recordings/:audio_recording_id/audio_events' do

    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :start_offset, 'Request audio events within offset bounds (start)'
    parameter :end_offset, 'Request audio events within offset bounds (end)'

    let(:authentication_token) { writer_token }

    standard_request('LIST (as writer)', 200, '0/start_time_seconds', true)

  end

  get '/audio_recordings/:audio_recording_id/audio_events' do

    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :start_offset, 'Request audio events within offset bounds (start)'
    parameter :end_offset, 'Request audio events within offset bounds (end)'

    let(:authentication_token) { reader_token }

    standard_request('LIST (as reader)', 200, '0/start_time_seconds', true)

  end


  get '/audio_recordings/:audio_recording_id/audio_events' do

    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :start_offset, 'Request audio events within offset bounds (start)'
    parameter :end_offset, 'Request audio events within offset bounds (end)'

    let(:authentication_token) { reader_token }

    standard_request('LIST (as reader with shallow path)', 200, '0/start_time_seconds', true)

  end

  get '/audio_recordings/:audio_recording_id/audio_events?start_offset=1&end_offset=2.5' do

    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :start_offset, 'Request audio events within offset bounds (start)'
    parameter :end_offset, 'Request audio events within offset bounds (end)'

    let(:authentication_token) { reader_token }
    # create three audio_events with times 1 - 4, 2 - 4, 3 - 4
    before do
      #won't be included
      FactoryGirl.create(:audio_event,
                         audio_recording: @write_permission.project.sites[0].audio_recordings[0],
                         start_time_seconds: 0, end_time_seconds: 1)
      #won't be included
      FactoryGirl.create(:audio_event,
                         audio_recording: @write_permission.project.sites[0].audio_recordings[0],
                         start_time_seconds: 2.5, end_time_seconds: 5)
      #will be included
      FactoryGirl.create(:audio_event,
                         audio_recording: @write_permission.project.sites[0].audio_recordings[0],
                         start_time_seconds: 0, end_time_seconds: 2)
      #will be included
      FactoryGirl.create(:audio_event,
                         audio_recording: @write_permission.project.sites[0].audio_recordings[0],
                         start_time_seconds: 2, end_time_seconds: 4)
      #will be included
      FactoryGirl.create(:audio_event,
                         audio_recording: @write_permission.project.sites[0].audio_recordings[0],
                         start_time_seconds: 1, end_time_seconds: 2.5)
      #will be included
      FactoryGirl.create(:audio_event,
                         audio_recording: @write_permission.project.sites[0].audio_recordings[0],
                         start_time_seconds: 1.5, end_time_seconds: 2)
    end

    example 'LIST (with offsets as reader) - 200', :document => true do
      do_request
      expect(status).to eq(200)
      expect(response_body).to have_json_path('1/start_time_seconds')
      # should only return four
      expect(response_body).to have_json_size(4)
      # TODO: check the values of the events that are returned
    end
  end

  get '/audio_recordings/:audio_recording_id/audio_events' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :start_offset, 'Request audio events within offset bounds (start)'
    parameter :end_offset, 'Request audio events within offset bounds (end)'

    let(:authentication_token) { unconfirmed_token }

    standard_request('LIST (as unconfirmed user)', 403, nil, true)

  end

  get '/audio_recordings/:audio_recording_id/audio_events' do

    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :start_offset, 'Request audio events within offset bounds (start)'
    parameter :end_offset, 'Request audio events within offset bounds (end)'

    let(:authentication_token) { reader_token }

    standard_request_options(:get, 'LIST (as reader with shallow path testing quoted numbers)', :ok,
                             {
                                 expected_json_path: '0/start_time_seconds',
                                 response_body_content: '"start_time_seconds":5.2,"end_time_seconds":5.8,"low_frequency_hertz":400.0,"high_frequency_hertz":6000.0'
                             })

  end

  ################################
  # SHOW
  ################################
  get '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { writer_token }

    standard_request('SHOW (as writer)', 200, 'start_time_seconds', true)
  end

  get '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { reader_token }

    standard_request('SHOW (as reader)', 200, 'start_time_seconds', true)
  end

  get '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { reader_token }

    standard_request('SHOW (as reader with shallow path)', 200, 'start_time_seconds', true)
  end

  get '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { reader_token }

    let(:id) { @audio_event.id }
    let(:audio_recording_id) { @other_audio_recording_id }

    before do
      other_permissions = FactoryGirl.create(:write_permission)
      @other_audio_recording_id = other_permissions.project.sites[0].audio_recordings[0].id
      @audio_event = FactoryGirl.create(:audio_event, audio_recording_id: @other_audio_recording_id, start_time_seconds: 5, end_time_seconds: 6, is_reference: true)
    end

    standard_request('SHOW (as reader with shallow path for reference audio event with no access to audio recording)', 200, 'start_time_seconds', true)
  end

  get '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { unconfirmed_token }

    standard_request('SHOW (as unconfirmed user)', 403, nil, true)
  end

  get '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { reader_token }


    standard_request_options(:get, 'SHOW (as reader with shallow path testing quoted numbers)', :ok,
                             {
                                 expected_json_path:'start_time_seconds',
                                 response_body_content: '"start_time_seconds":5.2,"end_time_seconds":5.8,"high_frequency_hertz":6000.0,"low_frequency_hertz":400.0'
                             })
  end

  ################################
  # CREATE
  ################################
  post '/audio_recordings/:audio_recording_id/audio_events' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true

    parameter :start_time_seconds, 'start_time in seconds, has to be lower than end_time', scope: :audio_event, required: true
    parameter :end_time_seconds, 'end_time in seconds, has to be higher than start_time', scope: :audio_event
    parameter :low_frequency_hertz, 'low_frequency in hertz, has to be lower than high_frequency', scope: :audio_event, :required => true
    parameter :high_frequency_hertz, 'high_frequency in hertz, has to be higher than low frequency', scope: :audio_event
    parameter :is_reference, 'set to true if audio event is a reference', scope: :audio_event

    let(:raw_post) { {'audio_event' => post_attributes}.to_json }

    let(:authentication_token) { writer_token }

    standard_request('CREATE (as writer)', 201, nil, true)

  end

  post 'audio_recordings/:audio_recording_id/audio_events' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true

    parameter :start_time_seconds, 'start_time in seconds, has to be lower than end_time', scope: :audio_event, required: true
    parameter :end_time_seconds, 'end_time in seconds, has to be higher than start_time', scope: :audio_event
    parameter :low_frequency_hertz, 'low_frequency in hertz, has to be lower than high_frequency', scope: :audio_event, :required => true
    parameter :high_frequency_hertz, 'high_frequency in hertz, has to be higher than low frequency', scope: :audio_event
    parameter :is_reference, 'set to true if audio event is a reference', scope: :audio_event

    let(:raw_post) { {'audio_event' => post_attributes}.to_json }

    let(:authentication_token) { writer_token }

    standard_request('CREATE (as writer with shallow path)', 201, nil, true)

  end

  post '/audio_recordings/:audio_recording_id/audio_events' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true

    parameter :start_time_seconds, 'start_time in seconds, has to be lower than end_time', scope: :audio_event, required: true
    parameter :end_time_seconds, 'end_time in seconds, has to be higher than start_time', scope: :audio_event
    parameter :low_frequency_hertz, 'low_frequency in hertz, has to be lower than high_frequency', scope: :audio_event, :required => true
    parameter :high_frequency_hertz, 'high_frequency in hertz, has to be higher than low frequency', scope: :audio_event
    parameter :is_reference, 'set to true if audio event is a reference', scope: :audio_event

    let(:raw_post) { {'audio_event' => post_attributes}.to_json }

    let(:authentication_token) { reader_token }

    standard_request('CREATE (as reader)', 403, nil, true)

  end

  post '/audio_recordings/:audio_recording_id/audio_events' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true

    parameter :start_time_seconds, 'start_time in seconds, has to be lower than end_time', scope: :audio_event, required: true
    parameter :end_time_seconds, 'end_time in seconds, has to be higher than start_time', scope: :audio_event
    parameter :low_frequency_hertz, 'low_frequency in hertz, has to be lower than high_frequency', scope: :audio_event, :required => true
    parameter :high_frequency_hertz, 'high_frequency in hertz, has to be higher than low frequency', scope: :audio_event
    parameter :is_reference, 'set to true if audio event is a reference', scope: :audio_event

    let(:raw_post) { {'audio_event' => post_attributes}.to_json }

    let(:authentication_token) { unconfirmed_token }

    standard_request('CREATE (as unconfirmed user)', 403, nil, true)

  end

  post '/audio_recordings/:audio_recording_id/audio_events' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true

    parameter :start_time_seconds, 'start_time in seconds, has to be lower than end_time', scope: :audio_event, required: true
    parameter :end_time_seconds, 'end_time in seconds, has to be higher than start_time', scope: :audio_event
    parameter :low_frequency_hertz, 'low_frequency in hertz, has to be lower than high_frequency', scope: :audio_event, :required => true
    parameter :high_frequency_hertz, 'high_frequency in hertz, has to be higher than low frequency', scope: :audio_event
    parameter :is_reference, 'set to true if audio event is a reference', scope: :audio_event
    parameter :tags_attributes, 'array of valid tag attributes, see tag resource', scope: :audio_event

    let(:raw_post) { {'audio_event' => post_attributes.merge(post_nested_attributes)}.to_json }
    let(:authentication_token) { writer_token }

    #standard_request('CREATE (with tags_attributes (one existing, one new) as writer)', 201, nil, true)
    example 'CREATE (with tags_attributes (one existing tag text, one new) as writer) - 201', :document => true do
      explanation 'this should create an audiorecording, including two taggings, one with the newly created tag and one with an existing tag'
      tag_count = Tag.count
      request = do_request

      # expecting two 'taggings'

      # check response
      opts =
          {
              expected_status: :created,
              expected_method: :post,
              expected_response_content_type: 'application/json',
              document: document_media_requests
          }

      opts = acceptance_checks_shared(request, opts)

      opts.merge!({expected_json_path: 'taggings/1/tag', response_body_content: 'start_time_seconds'})
      acceptance_checks_json(opts)

      # only one tag should have been created, so new tag count should be one more than old tag count
      expect(tag_count).to eq(Tag.count - 1)
    end
  end

  post '/audio_recordings/:audio_recording_id/audio_events' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true

    parameter :start_time_seconds, 'start_time in seconds, has to be lower than end_time', scope: :audio_event, required: true
    parameter :end_time_seconds, 'end_time in seconds, has to be higher than start_time', scope: :audio_event
    parameter :low_frequency_hertz, 'low_frequency in hertz, has to be lower than high_frequency', scope: :audio_event, :required => true
    parameter :high_frequency_hertz, 'high_frequency in hertz, has to be higher than low frequency', scope: :audio_event
    parameter :is_reference, 'set to true if audio event is a reference', scope: :audio_event
    parameter :tag_ids, 'array of existing tag ids', scope: :audio_event

    let(:raw_post) { {'audio_event' => post_attributes.merge("tag_ids" => [@tag1.id, @tag2.id])}.to_json }
    let(:authentication_token) { writer_token }

    # create two existing tags
    before do
      @tag1 = FactoryGirl.create(:tag)
      @tag2 = FactoryGirl.create(:tag)
    end

    #standard_request('CREATE (with tags_attributes (one existing, one new) as writer)', 201, nil, true)
    example 'CREATE (with existing tag_ids as writer) - 201', :document => true do
      tag_count = Tag.count
      request = do_request

      # expecting two 'taggings'

      # check response
      opts =
          {
              expected_status: :created,
              expected_method: :post,
              expected_response_content_type: 'application/json',
              document: document_media_requests
          }

      opts = acceptance_checks_shared(request, opts)

      opts.merge!({expected_json_path: 'taggings/1/tag', response_body_content: 'start_time_seconds'})
      acceptance_checks_json(opts)

      # only one tag should have been created, so new tag count should be one more than old tag count
      expect(tag_count).to eq(Tag.count)
    end
  end

  ################################
  # UPDATE
  ################################
  put '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    parameter :start_time_seconds, 'start_time in seconds, has to be lower than end_time', scope: :audio_event, required: true
    parameter :end_time_seconds, 'end_time in seconds, has to be higher than start_time', scope: :audio_event
    parameter :low_frequency_hertz, 'low_frequency in hertz, has to be lower than high_frequency', scope: :audio_event, :required => true
    parameter :high_frequency_hertz, 'high_frequency in hertz, has to be higher than low frequency', scope: :audio_event
    parameter :is_reference, 'set to true if audio event is a reference', scope: :audio_event

    let(:raw_post) { {'audio_event' => post_attributes}.to_json }

    let(:authentication_token) { writer_token }

    standard_request('UPDATE (as writer)', 201, nil, true)
  end

  put '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    parameter :start_time_seconds, 'start_time in seconds, has to be lower than end_time', scope: :audio_event, required: true
    parameter :end_time_seconds, 'end_time in seconds, has to be higher than start_time', scope: :audio_event
    parameter :low_frequency_hertz, 'low_frequency in hertz, has to be lower than high_frequency', scope: :audio_event, :required => true
    parameter :high_frequency_hertz, 'high_frequency in hertz, has to be higher than low frequency', scope: :audio_event
    parameter :is_reference, 'set to true if audio event is a reference', scope: :audio_event

    let(:raw_post) { {'audio_event' => post_attributes}.to_json }

    let(:authentication_token) { writer_token }

    standard_request('UPDATE (as writer with shallow path)', 201, nil, true)
  end

  put '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    parameter :start_time_seconds, 'start_time in seconds, has to be lower than end_time', scope: :audio_event, required: true
    parameter :end_time_seconds, 'end_time in seconds, has to be higher than start_time', scope: :audio_event
    parameter :low_frequency_hertz, 'low_frequency in hertz, has to be lower than high_frequency', scope: :audio_event, :required => true
    parameter :high_frequency_hertz, 'high_frequency in hertz, has to be higher than low frequency', scope: :audio_event
    parameter :is_reference, 'set to true if audio event is a reference', scope: :audio_event

    let(:raw_post) { {'audio_event' => post_attributes}.to_json }

    let(:authentication_token) { reader_token }

    standard_request('UPDATE (as reader)', 403, nil, true)
  end

  put '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    parameter :start_time_seconds, 'start_time in seconds, has to be lower than end_time', scope: :audio_event, required: true
    parameter :end_time_seconds, 'end_time in seconds, has to be higher than start_time', scope: :audio_event
    parameter :low_frequency_hertz, 'low_frequency in hertz, has to be lower than high_frequency', scope: :audio_event, :required => true
    parameter :high_frequency_hertz, 'high_frequency in hertz, has to be higher than low frequency', scope: :audio_event
    parameter :is_reference, 'set to true if audio event is a reference', scope: :audio_event

    let(:raw_post) { {'audio_event' => post_attributes}.to_json }

    let(:authentication_token) { unconfirmed_token }

    standard_request('UPDATE (as unconfirmed user)', 403, nil, true)
  end

  ################################
  # DELETE
  ################################

  delete '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { writer_token }
    standard_request_options(:delete, 'DELETE (as writer user)', :no_content, {expected_response_has_content: false, expected_response_content_type: nil})
  end

  delete '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { reader_token }
    standard_request_options(:delete, 'DELETE (as reader user)', :forbidden, {expected_json_path: 'meta/error/links/request permissions'})
  end

  delete '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { other_user_token }
    standard_request_options(:delete, 'DELETE (as other user)', :forbidden, {expected_json_path: 'meta/error/links/request permissions'})
  end

  delete '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { unconfirmed_token }
    standard_request_options(:delete, 'DELETE (as unconfirmed user)', :forbidden, {expected_json_path: 'meta/error/links/confirm your account'})
  end

  delete '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { admin_token }
    standard_request_options(:delete, 'DELETE (as admin user)', :no_content, {expected_response_has_content: false, expected_response_content_type: nil})
  end

  delete '/audio_recordings/:audio_recording_id/audio_events/:id' do
    parameter :audio_recording_id, 'Requested audio recording id (in path/route)', required: true
    parameter :id, 'Requested audio event id (in path/route)', required: true

    let(:authentication_token) { invalid_token }
    standard_request_options(:delete, 'DELETE (with invalid token)', :unauthorized, {expected_json_path: 'meta/error/links/sign in'})
  end

  #####################
  # Filter
  #####################

  post '/audio_events/filter' do
    let(:authentication_token) { reader_token }
    let(:raw_post) { {
        'filter' => {
            'start_time_seconds' => {
                'in' => ['5.2', '7', '100', '4']
            }
        },
        'projection' => {
            'include' => ['id', 'start_time_seconds', 'audio_recording_id', 'creator_id']
        }
    }.to_json }
    standard_request_options(:post, 'FILTER (as reader)', :ok,
                             {
                                 expected_json_path: 'data/0/start_time_seconds',
                                 data_item_count: 1,
                                 regex_match: /"in"\:\[\"5.2\",\"7\",\"100\",\"[0-9]+\"\]/,
                                 response_body_content: "\"start_time_seconds\":",
                                 invalid_content: "\"project_ids\":[{\"id\":"
                             })
  end

  post '/audio_events/filter' do
    let(:authentication_token) { reader_token }
    let(:raw_post) { {
        'filter' => {
            'start_time_seconds' => {
                'in' => ['5.2', '7', '100', '4']
            }
        },
        'projection' => {
            'include' => ['id', 'start_time_seconds', 'audio_recording_id', 'creator_id']
        }
    }.to_json }
    standard_request_options(:post, 'FILTER (as reader)', :ok,
                             {
                                 expected_json_path: 'data/0/start_time_seconds',
                                 data_item_count: 1,
                                 regex_match: /"taggings":\[\{"id":\d+,"audio_event_id":\d+,"created_at":"[^"]+","updated_at":"[^"]+","creator_id":\d+,"updater_id":null\}\]/,
                                 response_body_content: "\"taggings\":[{\"",
                                 invalid_content: "\"taggings\":[\"",
                             })
  end


  post '/audio_events/filter' do
    let(:authentication_token) { reader_token }
    let(:raw_post) { {
        'filter' => {
            'start_time_seconds' => {
                'in' => ['5.2', '7', '100', '4']
            }
        }
    }.to_json }
    standard_request_options(:post, 'FILTER (no projection, as reader)', :ok,
                             {
                                 expected_json_path: 'data/0/high_frequency_hertz',
                                 data_item_count: 1,
                                 regex_match: /"in"\:\[\"5.2\",\"7\",\"100\",\"[0-9]+\"\]/,
                                 response_body_content: "\"low_frequency_hertz\":400.0",
                                 invalid_content: "\"project_ids\":[{\"id\":"
                             })
  end

end