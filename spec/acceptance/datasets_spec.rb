require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'helpers/acceptance_spec_helper'

def id_params
  parameter :id, 'Dataset id in request url', required: true
end

def body_params
  parameter :name, 'Name of dataset', scope: :dataset, :required => true
  parameter :description, 'Description of dataset', scope: :dataset
end

# https://github.com/zipmark/rspec_api_documentation
resource 'Datasets' do

  header 'Accept', 'application/json'
  header 'Content-Type', 'application/json'
  header 'Authorization', :authentication_token

  let(:format) { 'json' }

  create_entire_hierarchy

  # Create post parameters from factory
  let(:post_attributes) { FactoryGirl.attributes_for(:dataset, name: 'New Dataset name') }

  ################################
  # INDEX
  ################################

  # Expected count is 2 because of the 'default dataset', which is seed data added during a clean install.

  get '/datasets' do
    let(:authentication_token) { admin_token }
    standard_request_options(
        :get,
        'INDEX (as admin)',
        :ok,
        {expected_json_path: 'data/0/name', data_item_count: 2}
    )
  end

  # will only return dataset that are created by the user

  get '/datasets' do
    let(:authentication_token) { reader_token }
    standard_request_options(
        :get,
        'INDEX (as non admin user)',
        :ok,
        {response_body_content: '200', data_item_count: 0}
    )
  end

  get '/datasets' do
    let(:authentication_token) { invalid_token }
    standard_request_options(
        :get,
        'INDEX (with invalid token)',
        :unauthorized,
        {expected_json_path: get_json_error_path(:sign_up)}
    )
  end

  get '/datasets' do
    standard_request_options(
        :get,
        'INDEX (as anonymous user)',
        :ok,
        {remove_auth: true, response_body_content: '200', data_item_count: 0}
    )
  end

  get '/datasets' do
    let(:authentication_token) { harvester_token }
    standard_request_options(
        :get,
        'INDEX (as harvester)',
        :ok,
        {remove_auth: true, response_body_content: '200', data_item_count: 0}
    )
  end

  ################################
  # CREATE
  ################################

  post '/datasets' do
    body_params
    let(:raw_post) { {'dataset' => post_attributes}.to_json }
    let(:authentication_token) { admin_token }
    standard_request_options(
        :post,
        'CREATE (as admin)',
        :created,
        {expected_json_path: 'data/name', response_body_content: 'New Dataset name'}
    )
  end

  post '/datasets' do
    body_params
    let(:raw_post) { {'dataset' => post_attributes}.to_json }
    let(:authentication_token) { reader_token }
    standard_request_options(
        :post,
        'CREATE (as non admin user)',
        :created,
        {expected_json_path: 'data/name', response_body_content: 'New Dataset name'}
    )
  end

  post '/datasets' do
    body_params
    let(:raw_post) { {'dataset' => post_attributes}.to_json }
    let(:authentication_token) { invalid_token }
    standard_request_options(
        :post,
        'CREATE (invalid token)',
        :unauthorized,
        {expected_json_path: get_json_error_path(:sign_up)}
    )
  end

  post '/datasets' do
    body_params
    let(:raw_post) { {'dataset' => post_attributes}.to_json }
    standard_request_options(
        :post,
        'CREATE (as anonymous user)',
        :unauthorized,
        {remove_auth: true, expected_json_path: get_json_error_path(:sign_up)}
    )
  end

  ################################
  # NEW
  ################################

  get '/datasets/new' do
    let(:authentication_token) { admin_token }
    standard_request_options(
        :get,
        'NEW (as admin)',
        :ok,
        {expected_json_path: 'data/name/'}
    )
  end

  get '/datasets/new' do
    let(:authentication_token) { no_access_token }
    standard_request_options(
        :get,
        'NEW (as non admin user)',
        :ok,
        {expected_json_path: 'data/name'}
    )
  end

  get '/datasets/new' do
    let(:authentication_token) { invalid_token }
    standard_request_options(
        :get,
        'NEW (with invalid token)',
        :unauthorized,
        {expected_json_path: get_json_error_path(:sign_up)}
    )
  end

  get '/datasets/new' do
    standard_request_options(
        :get,
        'NEW (as anonymous user)',
        :ok,
        {expected_json_path: 'data/name'}
    )
  end

  ################################
  # SHOW
  ################################

  get '/datasets/:id' do
    id_params
    let(:id) { dataset.id }
    let(:authentication_token) { admin_token }
    standard_request_options(
        :get,
        'SHOW (as admin)',
        :ok,
        {expected_json_path: 'data/name'}
    )
  end

  get '/datasets/:id' do
    id_params
    let(:id) { dataset.id }
    let(:authentication_token) { no_access_token }
    standard_request_options(
        :get,
        'SHOW (as non admin user)',
        :ok,
        {expected_json_path: 'data/name'}
    )
  end

  get '/datasets/:id' do
    id_params
    let(:id) { dataset.id }
    let(:authentication_token) { invalid_token }
    standard_request_options(
        :get,
        'SHOW (with invalid token)',
        :unauthorized,
        {expected_json_path: get_json_error_path(:sign_up)}
    )
  end

  get '/datasets/:id' do
    id_params
    let(:id) { dataset.id }
    standard_request_options(
        :get,
        'SHOW (an anonymous user)',
        :unauthorized,
        {remove_auth: true, expected_json_path: get_json_error_path(:sign_up)}
    )
  end


  ################################
  # UPDATE
  ################################

  put '/datasets/:id' do
    body_params
    let(:id) { dataset.id }
    let(:raw_post) { {dataset: post_attributes}.to_json }
    let(:authentication_token) { admin_token }
    standard_request_options(
        :put,
        'UPDATE (as admin)',
        :ok,
        {expected_json_path: 'data/name', response_body_content: 'New Dataset name'}
    )
  end

  put '/datasets/:id' do
    body_params
    let(:id) { dataset.id }
    let(:raw_post) { {dataset: post_attributes}.to_json }
    let(:authentication_token) { no_access_token }
    standard_request_options(
        :put,
        'UPDATE (as non admin user)',
        :forbidden,
        {expected_json_path: get_json_error_path(:permissions)}
    )
  end

  put '/datasets/:id' do
    body_params
    let(:id) { dataset.id }
    let(:raw_post) { {dataset: post_attributes}.to_json }
    let(:authentication_token) { invalid_token }
    standard_request_options(
        :put,
        'UPDATE (with invalid token)',
        :unauthorized,
        {expected_json_path: get_json_error_path(:sign_up)}
    )
  end

  put '/datasets/:id' do
    body_params
    let(:id) { dataset.id }
    let(:raw_post) { {dataset: post_attributes}.to_json }
    standard_request_options(
        :put,
        'UPDATE (as anonymous user)',
        :unauthorized,
        {remove_auth: true, expected_json_path: get_json_error_path(:sign_in)}
    )
  end


  ################################
  # DESTROY
  ################################

  # Destroy is not implemented, so just one test for expected 404
  delete '/datasets/:id' do
    body_params
    let(:id) { dataset.id }
    let(:authentication_token) { admin_token }
    standard_request_options(
        :delete,
        'DESTROY (as admin)',
        :not_found,
        {expected_json_path: 'meta/error/info/original_route', response_body_content: 'Could not find'}
    )
  end

  ################################
  # FILTER
  ################################

  # expected count is 2 because of the 'default dataset'. The 'default dataset' exists as seed data in a clean install
  post '/datasets/filter' do
    let(:authentication_token) { admin_token }
    standard_request_options(
        :post,
        'FILTER (as admin)',
        :ok,
        {response_body_content: ['200', 'gen_dataset'], expected_json_path: 'data/0/name', data_item_count: 2}
    )
  end

  post '/datasets/filter' do
    let(:authentication_token) { no_access_token }
    standard_request_options(
        :post,
        'FILTER (as non admin user)',
        :ok,
        {response_body_content: ['200'], expected_json_path: 'data', data_item_count: 0}
    )
  end

  post '/datasets/filter' do
    let(:authentication_token) { invalid_token }
    standard_request_options(
        :post,
        'FILTER (with invalid token)',
        :unauthorized,
        {expected_json_path: get_json_error_path(:sign_up)}
    )
  end

  post '/datasets/filter' do
    standard_request_options(
        :post,
        'FILTER (as anonymous user)',
        :ok,
        {expected_json_path: 'data', data_item_count: 0}
    )
  end

end