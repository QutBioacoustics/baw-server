# included in rails_helpers.rb
require 'swagger_helper'

require 'rswag/specs'
load 'rswag/specs/swagger_formatter'
module Rswag
  module Specs
    #https://github.com/rswag/rswag/issues/325
    module PatchedSwaggerFormatter
      def upgrade_content!(mime_list, target_node)
        target_node[:content] ||= {} # Here we're avoiding "content" key overriding
        schema = target_node[:schema]
        return if mime_list.empty? || schema.nil?

        mime_list.each do |mime_type|
          # TODO: upgrade to have content-type specific schema
          (target_node[:content][mime_type] ||= {}).merge!(schema: schema)
        end
      end
    end
  end
end

Rswag::Specs::SwaggerFormatter.prepend Rswag::Specs::PatchedSwaggerFormatter

RSpec.shared_context :api_spec_shared_context do
  before do
    # need to freeze time so that docs generation does not produce different
    # output every time it's run. This affects timestamps in particular.
    Timecop.freeze(Time.local(2020, 1, 2, 3, 4, 5.678))
  end

  after do
    Timecop.return
  end

  def json_example
    {
      'application/json' => {
        example: api_result
      }
    }
  end

  def raw_example
    {
      response.content_type => {
        example: response_body
      }
    }
  end

  def add_example(spec_example)
    case response&.content_type
    when %r{.*application/json.*}
      spec_example.metadata[:response][:content] = json_example
    when String
      spec_example.metadata[:response][:content] = raw_example
    else
      # add no example
    end
  end

  # after every api test
  after(:each) do |example|
    # include the response as an example
    add_example(example)

    next if defined?(skip_automatic_description) && skip_automatic_description
    raise 'API specs must have a model set in a `let`' if model.nil?

    # if a test failed, don't proceed with the following
    next if request.nil?

    # also include additional tags
    example.metadata[:operation][:tags] ||= []
    example.metadata[:operation][:tags] << model.model_name.plural

    # also include information about route access
    # first resolve path to controller and action
    route = Rails.application.routes.recognize_path(request.url, method: request.env['REQUEST_METHOD'])

    # then for all of the test users we know about, see if they have access
    can, cannot = all_users.partition { |user|
      abilities = Ability.new(user)
      abilities.can? route[:action].to_sym, model
    }
    user_name = ->(user) { '`' + (user&.user_name.nil? ? 'anyone' : user.user_name) + '`' }

    description = example.metadata[:operation][:description]
    description = <<~MARKDOWN
      #{(description.nil? ? '' : description)}
      Users that can invoke this route: #{can.map(&user_name).join(', ')}.<br />
      Users that can't: #{cannot.map(&user_name).join(', ')}.

      Note: accessing a list/index/filter endpoint may return no results due to project permissions
    MARKDOWN
    example.metadata[:operation][:description] = description
  end

  before(:each) do |example|
    #    puts example.metadata
  end
end

# config.extend allows these methods to be used in describe/groups
module ApiSpecDescribeHelpers
  def self.extended(base); end

  attr_accessor :baw_consumes, :baw_produces, :baw_security, :baw_model_name, :baw_body_name, :baw_model, :baw_factory, :baw_model_schema, :baw_route_params, :baw_body_params

  def with_authorization
    # these tests document an API - they're not really for testing user access
    # Even if they were, the OAS specification has no concept of different
    # responses based on user roles. So all documentation tests are done under
    # the admin user.
    #
    # Actual auth tests should be done in the requests specs.
    #
    # NOTE: rswag won't use the let `Authorization` unless there is a
    # basic auth section defined in components/securitySchemes in swagger_helper!
    self.baw_security = [{ basic_auth_with_token: [] }]
    let(:Authorization) { admin_token }
  end

  def with_query_string_authorization
    # see notes in with_authorization about token
    self.baw_baw_security = [{ auth_token_query_string: [] }]
    let(:auth_token) { admin_token }
  end

  def sends_json_and_expects_json
    self.baw_consumes = ['application/json']
    self.baw_produces = ['application/json']
  end

  def for_model(given_model, factory: nil)
    self.baw_model_name = baw_model_name = given_model.model_name.singular
    self.baw_factory = factory || baw_model_name
    # rswag expects let statements to be defined with the same name as the parameters,
    # however, our creation scripts already define many let statements that have the
    # same name as our models... so naming the parameter project forces us to overwrite
    # the project let defined in creation.
    # All this wouldn't be so bad except that let statements are dynamically scoped
    # and any redefinition is applied to all uses (it doesn't just hide the parent for
    # the current lexical scope!)
    self.baw_body_name = baw_body_name = (baw_model_name + '_attributes').to_sym

    self.baw_model = given_model

    let(:model) { given_model }
    let(:model_name) { baw_model_name }
    let(:body_name) { baw_body_name }
    let(:factory) { factory || baw_model_name }
  end

  def resolve_ref(ref)
    swagger_doc = RSpec.configuration.swagger_docs.first[1]
    parts = ref.split('/').slice(1..).map(&:to_sym)
    schema = swagger_doc.dig(*parts)

    raise "Referenced parameter '#{ref}' must be defined" unless schema

    schema
  end

  # all data returned should have the following schema
  # schema can be a hash style JSON-schema fragment
  # or a string ref to the components/schemas section of
  # the root open api document (swagger_docs in code)
  def which_has_schema(schema)
    if schema.has_key? '$ref'
      ref =  schema
      schema = resolve_ref(schema['$ref'])
    end

    self.baw_model_schema = defined?(ref) ? ref : schema
    let(:model_schema) {
      schema
    }
  end

  def with_id_route_parameter
    self.baw_route_params ||= []
    self.baw_route_params << {
      name: 'id',
      in: :path,
      type: :integer,
      description: 'id',
      required: true
    }
  end

  def with_route_parameter(name, description = name)
    self.baw_route_params ||= []
    self.baw_route_params << {
      name: name.to_s,
      in: :path,
      type: :integer,
      description: description.to_s,
      required: true
    }
  end

  def model_sent_as_parameter_in_body
    self.baw_body_params ||= []
    self.baw_body_params << {
      name: (get_parent_param :baw_body_name),
      in: :body,
      schema: (get_parent_param :baw_model_schema)
    }
  end

  def send_model(&block)
    let((get_parent_param :baw_body_name)) do
      body = instance_eval(&block)
      unless body.is_a?(Hash) && body.key?(model_name)
        raise 'Body must have one key with model name which then contains attributes'
      end

      body
    end
  end

  # sends the default factory bot model for previously set :model
  # using attributes_for and filtering out readonly properties
  # from the hash, according to the given schema
  def auto_send_model(subset: nil)
    let((get_parent_param :baw_body_name)) do
      body_attributes_for(model_name, factory: factory, subset: subset)
    end
  end

  def ref(key)
    { '$ref' => "#/components/schemas/#{key}" }
  end

  def schema_for_single
    schema allOf: [
      { '$ref' => '#/components/schemas/standard_response' },
      {
        type: 'object',
        properties: {
          data: (get_parent_param :baw_model_schema)
        }
      }
    ]
  end

  def schema_for_many
    schema allOf: [
      { '$ref' => '#/components/schemas/standard_response' },
      {
        type: 'object',
        properties: {
          data: {
            type: 'array',
            items: (get_parent_param :baw_model_schema)
          }
        }
      }
    ]
  end

  # the way rspec creates describe blocks makes each new
  # describe/ExampleGroup its own class.
  # Any metadata we define on an example group is not accessible
  # unless we traverse up this pseudo-inheritance looking for
  # our desired variables
  def get_parent_param(name)
    # out attr_accessor is possibly defined on every example group
    layers = parent_groups.map { |x| x.send(name) }
    # pick the first non-nil value
    layers.reject(&:nil?).first
  end

  def run_test!(&block)
    # we're overriding run test because it is easier to insert our custom helper's
    # metadata in the right spots just before we invoke the test

    # remove accept header if we are not sending a body
    verb = metadata[:operation][:verb]
    if metadata[:operation][:consumes].blank?
      metadata[:operation][:consumes] = get_parent_param :baw_consumes unless [:get, :head, :options].include?(verb)
    end

    metadata[:operation][:produces] = get_parent_param :baw_produces if metadata[:operation][:produces].blank?
    metadata[:operation][:security] = get_parent_param :baw_security
    #baw_model_name = get_parent_param :baw_model_name
    #baw_body_name = get_parent_param :baw_body_name
    #baw_model = get_parent_param :baw_model
    #baw_model_schema = get_parent_param :baw_model_schema
    metadata[:operation][:parameters] ||= []

    baw_body_params = get_parent_param :baw_body_params
    metadata[:operation][:parameters] += baw_body_params if baw_body_params

    baw_route_params = get_parent_param :baw_route_params
    metadata[:operation][:parameters] += baw_route_params if baw_route_params

    # before do |example|
    #   # validate schema is valid
    #   metaschema = JSON::Validator.validator_for_name('http://json-schema.org/draft/schema#').metaschema
    #   JSON::Validator.validate(metaschema, example.metadata[:response][:schema])
    # end

    before do |example|
      submit_request(example.metadata)
    end

    it "returns a #{metadata[:response][:code]} response" do |example|
      assert_response_matches_metadata(example.metadata, &block)
      example.instance_exec(response, &block) if block_given?
    end

    after do |example|
      unless example.exception.nil?
        # I don't know of a good way to augment the original error with more
        # information. Raising a new error with more information seem to work OK.
        request&.body&.rewind
        message = <<~API_RESULT
          The API result that generated this failure is:
          ```
          #{api_result.nil? ? '<empty result>' : api_result}
          ```
          The request body was:
          ```
          #{request&.body&.nil? != false ? '<empty request body>' : request.body.read}
          ```
        API_RESULT
        raise StandardError, message
      end
    end
  end
end
