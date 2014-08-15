class ApplicationController < ActionController::Base
  layout :api_or_html

  # CanCan - always check authorization
  check_authorization unless: :devise_controller?

  # userstamp
  include Userstamp

  # see routes.rb for the catch-all route for routing errors.
  # see application.rb for the exceptions_app settings.
  # see errors_controller.rb for the actions that handle routing errors and uncaught errors.
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found_response
  rescue_from CustomErrors::ItemNotFoundError, with: :item_not_found_response
  rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique_response
  rescue_from CustomErrors::UnsupportedMediaTypeError, with: :unsupported_media_type_response
  rescue_from CustomErrors::NotAcceptableError, with: :not_acceptable_response
  rescue_from CustomErrors::UnprocessableEntityError, with: :unprocessable_entity_response
  rescue_from ActiveResource::BadRequest, with: :bad_request_response

  # error handling for cancan authorisation checks
  rescue_from CanCan::AccessDenied, with: :access_denied_response

  # error handling for routes that take a combination of attributes
  rescue_from CustomErrors::RoutingArgumentError, with: :routing_argument_missing

  protect_from_forgery

  skip_before_filter :verify_authenticity_token, if: :json_request?

  after_filter :set_csrf_cookie_for_ng, :resource_representation_caching_fixes

  protected

  def add_archived_at_header(model)
    if model.respond_to?(:deleted_at) && !model.deleted_at.blank?
      response.headers['X-Archived-At'] = model.deleted_at
    end
  end

  def no_content_as_json
    head :no_content, :content_type => 'application/json'
  end

  def json_request?
    request.format && request.format.json?
  end

  # http://stackoverflow.com/questions/14734243/rails-csrf-protection-angular-js-protect-from-forgery-makes-me-to-log-out-on
  def set_csrf_cookie_for_ng
    csrf_cookie_key = 'XSRF-TOKEN'
    if request.format && request.format.json?
      cookies[csrf_cookie_key] = form_authenticity_token if protect_against_forgery?
    end
  end

  # http://stackoverflow.com/questions/14734243/rails-csrf-protection-angular-js-protect-from-forgery-makes-me-to-log-out-on
  # cookies can only be accessed by js from the same origin (protocol, host and port) as the response.
  # WARNING: disable csrf check for json for now.
  def verified_request?
    if request.format && request.format.json?
      true
    else
      csrf_header_key = 'X-XSRF-TOKEN'
      super || form_authenticity_token == request.headers[csrf_header_key]
    end
  end

  # from http://stackoverflow.com/a/94626
  def render_csv(filename = nil)
    require 'csv'
    filename ||= params[:action]
    filename = filename.trim('.', '')
    filename += '.csv'

    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers['Content-type'] = 'text/plain'
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = '0'
    else
      headers['Content-Type'] ||= 'text/csv'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    end

    render layout: false
  end

  def auth_custom_audio_recording(request_params)
    # do auth manually
    #authorize! :show, @audio_recording

    audio_recording = AudioRecording.where(id: request_params[:audio_recording_id]).first
    fail ActiveRecord::RecordNotFound, 'Could not find audio recording with given id.' if audio_recording.blank?

    # can? also checks for admin access
    can_access_audio_recording = can? :show, audio_recording

    # Can't do anything if can't access audio recording and no audio event id given
    has_any_permission = can_access_audio_recording || !request_params[:audio_event_id].blank?
    fail CanCan::AccessDenied, 'Permission denied to audio recording and no audio event id given.' unless has_any_permission

    audio_recording
  end

  def auth_custom_audio_event(request_params, audio_recording)
    audio_event = AudioEvent.where(id: request_params[:audio_event_id]).first
    fail ActiveRecord::RecordNotFound, 'Could not find audio event with given id.' if audio_event.blank?

    # can? also checks for admin access
    can_access_audio_event = can? :read, audio_event
    matching_ids = audio_event.audio_recording_id == audio_recording.id
    is_reference = audio_event.is_reference
    has_any_permission = can_access_audio_event || is_reference

    unless matching_ids
      msg = "Requested audio event (#{audio_event.audio_recording_id}) " +
          "and audio recording (#{audio_recording.id}) must be related."
      fail CanCan::AccessDenied, msg
    end

    unless has_any_permission
    msg = "Permission denied to audio event (#{audio_event.id})"+
        'and it is not a marked as reference.'
      fail CanCan::AccessDenied, msg
    end

    audio_event
  end

  def auth_custom_offsets(request_params, audio_recording, audio_event)
    # check offsets are within range

    start_offset = 0.0
    start_offset = request_params[:start_offset].to_f if request_params.include?(:start_offset)

    end_offset = audio_recording.duration_seconds.to_f
    end_offset = request_params[:end_offset].to_f if request_params.include?(:end_offset)

    audio_event_start = audio_event.start_time_seconds
    audio_event_end = audio_event.end_time_seconds

    allowable_padding = 5

    allowable_start_offset = audio_event_start - allowable_padding
    allowable_end_offset = audio_event_end + allowable_padding

    msg1 = "Permission denied to audio recording (#{audio_recording.id}): "
    msg3 = "(including padding of #{allowable_padding})."

    if start_offset < allowable_start_offset
      msg2 = "start offset (#{start_offset}) was less than allowable bounds (#{allowable_start_offset}) "
      fail CanCan::AccessDenied, msg1 + msg2 + msg3
    end

    if end_offset > allowable_end_offset
      msg2 = "end offset (#{end_offset}) was greater than allowable bounds (#{allowable_end_offset}) "
      fail CanCan::AccessDenied, msg1 + msg2 + msg3
    end

  end

  def create_json_data_response(status_symbol, data)
    # used by other controllers to easily return json responses.
    json_response = create_json_response(status_symbol)

    json_response[:data] = data

    json_response
  end

  def render_error(status_symbol, detail_message, error, method_name, links_object = nil, template = nil, error_info = nil)

    json_response = create_json_error_response(status_symbol, detail_message, links_object)

    unless error_info.blank?
      json_response.meta.error.merge!(error_info)
    end

    # method_name = __method__
    # caller[0]
    log_original_error(method_name, error, json_response)

    respond_to do |format|
      format.html {
        default_template = 'errors/generic'
        if template.blank?
          redirect_to get_redirect, alert: detail_message
        else
          render template: template, status: status_symbol
        end
      }
      format.json { render json: json_response, status: status_symbol }
      # http://blogs.thewehners.net/josh/posts/354-obscure-rails-bug-respond_to-formatany
      format.all { render json: json_response, status: status_symbol, content_type: 'application/json' }
    end

    check_reset_stamper
  end

  def get_redirect
    if !request.env['HTTP_REFERER'].blank? and request.env['HTTP_REFERER'] != request.env['REQUEST_URI']
      redirect_target = :back
    else
      redirect_target = root_path
    end

    redirect_target
  end

  private

  def record_not_found_response(error)

    render_error(
        :not_found,
        'Could not find the requested item.',
        error,
        'record_not_found_error',
        nil,
        'errors/record_not_found'
    )
  end

  def item_not_found_response(error)
    # #render json: {code: 404, phrase: 'Not Found', message: 'Audio recording is not ready'}, status: :not_found
    render_error(
        :not_found,
        'Could not find the requested item.',
        error,
        'resource_not_found_error',
        nil,
        'errors/record_not_found'
    )
  end


  def record_not_unique_response(error)

    render_error(
        :conflict,
        'The item must be unique.',
        error,
        'record_not_unique_error',
        nil,
        'errors/generic'
    )
  end

  def unsupported_media_type_response(error)
    # 415 - Unsupported Media Type
    # they sent what we don't want
    # render json: {code: 415, phrase: 'Unsupported Media Type', message: 'Requested format is invalid. It must be one of available_formats.', available_formats: @available_formats}, status: :unsupported_media_type

    render_error(
        :unsupported_media_type,
        'The format of the request is not supported.',
        error,
        'unsupported_media_type_error',
        nil,
        'errors/generic',
        {available_formats: error.available_formats_info}
    )
  end

  def not_acceptable_response(error)
    # 406 - Not Acceptable
    # we can't send what they want

    request.format = :json

    render_error(
        :not_acceptable,
        'None of the acceptable response formats are available.',
        error,
        'not_acceptable_error',
        nil,
        'errors/generic',
        {available_formats: error.available_formats_info}
    )
  end

  def unprocessable_entity_response(error)
    render_error(
        :unprocessable_entity,
        'The request could not be understood.',
        error,
        'unsupported_media_type',
        nil,
        'errors/generic'
    )
  end

  def bad_request_response(error)
    # render json: {code: 400, phrase: 'Bad Request', message: 'Invalid request'}, status: :bad_request

    render_error(
        :bad_request,
        'The request was not valid.',
        error.message,
        'bad_request',
        nil,
        'errors/generic'
    )
  end

  def access_denied_response(error)
    if current_user && current_user.confirmed?
      render_error(:forbidden, I18n.t('devise.failure.unauthorized'), error, 'access_denied - forbidden', [:permissions])

    elsif current_user && !current_user.confirmed?
      render_error(:forbidden, I18n.t('devise.failure.unconfirmed'), error, 'access_denied - unconfirmed', [:confirm])

    else
      render_error(:unauthorized, I18n.t('devise.failure.unauthenticated'), error, 'access_denied - unauthorised', [:sign_in, :confirm])

    end
  end

  def routing_argument_missing(error)

    render_error(
        :not_found,
        'Could not find the requested page.',
        error,
        'routing_argument_missing',
        nil,
        'errors/routing'
    )
  end

  def resource_representation_caching_fixes
    # send Vary: Accept for all text/html and application/json responses
    if response.content_type == 'text/html' || response.content_type == 'application/json'
      response.headers['Vary'] = 'Accept'
    end
  end

  def check_reset_stamper
    reset_stamper if User.stamper
  end

  def log_original_error(method_name, error, response_given)

    msg = "Error handled by #{method_name} in application or errors controller."

    if error.blank?
      msg += ' No original error.'
    else
      msg += " Original error: #{error.inspect}."
    end

    msg += " Response given: #{response_given}."

    Rails.logger.warn msg
  end

  def api_or_html
    if json_request?
      'api'
    else
      'application'
    end
  end

  def create_json_response(status_symbol)
    status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status_symbol]
    status_message = Rack::Utils::HTTP_STATUS_CODES[status_code]

    json_response = {
        meta: {
            status: status_code,
            message: status_message
        },
        data: nil
    }

    json_response
  end

  def create_json_error_response(status_symbol, detail_message, links_object = nil)
    json_response = create_json_response(status_symbol)

    json_response[:meta][:error] = {} if !detail_message.blank? || !links_object.blank?

    json_response[:meta][:error][:details] = detail_message unless detail_message.blank?

    json_response[:meta][:error][:links] = {} unless links_object.blank?
    json_response[:meta][:error][:links]['sign in'] = new_user_session_url if !links_object.blank? && links_object.include?(:sign_in)
    json_response[:meta][:error][:links]['request permissions'] = new_access_request_projects_url if !links_object.blank? && links_object.include?(:permissions)
    json_response[:meta][:error][:links]['confirm your account'] = new_user_confirmation_url if !links_object.blank? && links_object.include?(:confirm)

    json_response
  end

end
