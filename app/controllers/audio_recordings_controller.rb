class AudioRecordingsController < ApplicationController

  load_resource :project, only: [:check_uploader, :create]
  load_resource :site, only: [:index, :create]
  skip_authorization_check only: :check_uploader
  load_and_authorize_resource :audio_recording, except: [:check_uploader]

  layout 'player', only: :show


  # GET /audio_recordings.json
  def index

    if @site
      @audio_recordings = @site.audio_recordings.order('recorded_date DESC').limit(5)
    else
      @audio_recordings = AudioRecording.order('recorded_date DESC').limit(5)
    end

    render json: @audio_recordings
  end

  # GET /audio_recordings/1.json
  def show

    respond_to do |format|
      format.html {}
      format.json { render json: @audio_recording }
    end
  end

  # GET /audio_recordings/new.json
  def new
    @audio_recording = AudioRecording.new

    required = [
        :uploader_id,
        :sample_rate_hertz,
        :media_type,
        :recorded_date,
        :bit_rate_bps,
        :data_length_bytes,
        :channels,
        :duration_seconds,
        :file_hash,
        :original_file_name
    ]

    render json: @audio_recording.to_json(only: required)
  end


  # POST /audio_recordings.json
  def create
    @audio_recording = match_existing_or_create_new(params)
    @audio_recording.site = @site

    uploader_id = params[:audio_recording][:uploader_id]
    user_exists = User.exists?(uploader_id)
    user = User.where(id: uploader_id).first
    highest_permission = user.highest_permission(@project)

    if !user_exists || highest_permission < AccessLevel::WRITE
      render json: {error: 'uploader does not have access to this project'}.to_json, status: :unprocessable_entity
    elsif @audio_recording.save
      render json: @audio_recording, status: :created, location: [@project, @site, @audio_recording]
    else
      render json: @audio_recording.errors, status: :unprocessable_entity
    end

  end

  def check_uploader
    # current user should be the harvester
    # uploader_id must have read access to the project

    if current_user.blank?
      render json: {error: 'not logged in'}.to_json, status: :unauthorized
    else
      if current_user.has_role? :harvester
        # auth check is skipped, so auth is checked manually here
        uploader_id = params[:uploader_id]
        user_exists = User.exists?(uploader_id)
        user = User.where(id: uploader_id).first
        highest_permission = user.highest_permission(@project)

        if !user_exists || highest_permission < AccessLevel::WRITE
          render json: {error: 'uploader does not have access to this project'}.to_json, status: :ok
        else
          head :no_content
        end
      else
        render json: {error: 'only harvester can check uploader permissions'}.to_json, status: :forbidden
      end
    end
  end

  ## PUT /audio_recordings/1.json
  #def update
  #  @audio_recording = AudioRecording.find(params[:id])
  #
  #  respond_to do |format|
  #    if @audio_recording.update_attributes(params[:audio_recording])
  #      format.json { head :no_content }
  #    else
  #      format.json { render json: @audio_recording.errors, status: :unprocessable_entity }
  #    end
  #  end
  #end
  #
  ## DELETE /audio_recordings/1.json
  #def destroy
  #  @audio_recording = AudioRecording.find(params[:id])
  #  @audio_recording.destroy
  #
  #  add_archived_at_header(@audio_recording)
  #
  #  respond_to do |format|
  #    format.json { no_content_as_json }
  #  end
  #end

  # this is called by the harvester once the audio file is in the correct location
  def update_status
    update_status_user_check
  end

  private

  def update_status_user_check
    # auth is checked manually here - not sure if this is necessary or not
    if current_user.blank?
      render json: {error: 'not logged in'}.to_json, status: :unauthorized
    elsif current_user.has_role? :harvester
      update_status_params_check
    else
      render json: {error: 'only harvester can check uploader permissions'}.to_json, status: :forbidden
    end
  end

  def update_status_params_check
    if @audio_recording.blank?
      render json: {error: "Could not find Audio Recording with id #{params[:id]}"}.to_json, status: :not_found
    elsif !params[:audio_recording].include?(:file_hash)
      render json: {error: 'Must include file hash'}.to_json, status: :unprocessable_entity
    elsif @audio_recording.file_hash != params[:audio_recording][:file_hash]
      render json: {error: 'Incorrect file hash'}.to_json, status: :unprocessable_entity
    elsif !params[:audio_recording].include?(:uuid)
      render json: {error: 'Must include uuid'}.to_json, status: :unprocessable_entity
    elsif @audio_recording.uuid != params[:audio_recording][:uuid]
      render json: {error: 'Incorrect uuid'}.to_json, status: :unprocessable_entity
    elsif !params[:audio_recording].include?(:status)
      render json: {error: 'Must include status'}.to_json, status: :unprocessable_entity
    else
      update_status_available_check
    end
  end

  def update_status_available_check
    new_status = params[:audio_recording][:status].to_sym
    if AudioRecording::AVAILABLE_STATUSES_SYMBOLS.include?(new_status)
      update_status_audio_recording(new_status)
    else
      render json: {error: "Status #{new_status} is not in available status list #{AVAILABLE_STATUSES_SYMBOLS}."}.to_json, status: :unprocessable_entity
    end
  end

  def update_status_audio_recording(status)
    @audio_recording.status = status
    if @audio_recording.save!
      head :no_content
    else
      render json: @audio_recording.errors, status: :unprocessable_entity
    end
  end

  def match_existing_or_create_new(params)
    match = AudioRecording.where(
        original_file_name: params[:audio_recording][:original_file_name],
        file_hash: params[:audio_recording][:file_hash],
        recorded_date: Time.zone.parse(params[:audio_recording][:recorded_date]).utc,
        data_length_bytes: params[:audio_recording][:data_length_bytes],
        media_type: params[:audio_recording][:media_type],
        duration_seconds: params[:audio_recording][:duration_seconds].round(4),
        site_id: params[:audio_recording][:site_id],
        status: 'aborted'
    )

    if match.count == 1
      found = match.first
      found.status = :new
      found
    else
      AudioRecording.new(params[:audio_recording])
    end
  end

end
