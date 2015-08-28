class AnalysisJob < ActiveRecord::Base
  extend Enumerize

  # ensures that creator_id, updater_id, deleter_id are set
  include UserChange

  belongs_to :creator, class_name: 'User', foreign_key: :creator_id, inverse_of: :created_analysis_jobs
  belongs_to :updater, class_name: 'User', foreign_key: :updater_id, inverse_of: :updated_analysis_jobs
  belongs_to :deleter, class_name: 'User', foreign_key: :deleter_id, inverse_of: :deleted_analysis_jobs

  belongs_to :script, inverse_of: :analysis_jobs
  belongs_to :saved_search, inverse_of: :analysis_jobs
  has_many :projects, through: :saved_searches

  # add deleted_at and deleter_id
  acts_as_paranoid
  validates_as_paranoid

  # store progress as json in a text column
  # this stores jason in the form
  # { queued: 5, working: 10, successful: 4, failed: 3, total: 22}
  serialize :overall_progress, JSON

  # association validations
  validates :script, existence: true
  validates :saved_search, existence: true
  validates :creator, existence: true

  # attribute validations
  validates :name, presence: true, length: {minimum: 2, maximum: 255}, uniqueness: {case_sensitive: false}
  validates :custom_settings, :overall_progress, presence: true
  # overall_count is the number of audio_recordings/resque jobs. These should be equal.
  validates :overall_count, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :overall_duration_seconds, presence: true, numericality: {only_integer: false, greater_than: 0}
  validates :started_at, :overall_status_modified_at, :overall_progress_modified_at,
            presence: true, timeliness: {on_or_before: lambda { Time.zone.now }, type: :datetime}

  # job status values - completed just means all processing has finished, whether it succeeds or not.
  AVAILABLE_JOB_STATUS_SYMBOLS = [:new, :preparing, :processing, :suspended, :completed]
  AVAILABLE_JOB_STATUS = AVAILABLE_JOB_STATUS_SYMBOLS.map { |item| item.to_s }

  AVAILABLE_JOB_STATUS_DISPLAY = [
      {id: :new, name: 'New'},
      {id: :preparing, name: 'Preparing'},
      {id: :processing, name: 'Processing'},
      {id: :suspended, name: 'Suspended'},
      {id: :completed, name: 'Completed'},
  ]

  enumerize :overall_status, in: AVAILABLE_JOB_STATUS, predicates: true

  def self.filter_settings
    {
        valid_fields: [:id, :name, :description, :script_id, :saved_search_id, :created_at, :creator_id, :updated_at, :updater_id],
        render_fields: [:id, :name, :description, :script_id, :saved_search_id, :created_at, :creator_id, :updated_at, :updater_id],
        text_fields: [],
        custom_fields: lambda { |analysis_job, user|
          analysis_job_hash = {}

          saved_search =
              SavedSearch
                  .where(id: analysis_job.saved_search_id)
                  .select(*SavedSearch.filter_settings[:render_fields])
                  .first

          analysis_job_hash[:saved_search] = saved_search
          analysis_job_hash[:saved_search_id] = saved_search.nil? ? nil : saved_search.id

          script =
              Script
                  .where(id: analysis_job.script_id)
                  .select(*Script.filter_settings[:render_fields])
                  .first

          analysis_job_hash[:script] = script
          analysis_job_hash[:script_id] = script.nil? ? nil : script.id

          [analysis_job, analysis_job_hash]
        },
        controller: :audio_events,
        action: :filter,
        defaults: {
            order_by: :name,
            direction: :asc
        },
        field_mappings: [],
        valid_associations: [
            {
                join: SavedSearch,
                on: AnalysisJob.arel_table[:saved_search_id].eq(SavedSearch.arel_table[:id]),
                available: true
            },
            {
                join: Script,
                on: AnalysisJob.arel_table[:script_id].eq(Script.arel_table[:id]),
                available: true
            }
        ]
    }
  end

  # Create payloads from audio recordings extracted from saved search.
  # @param [User] user
  # @return [Array<Hash>] payloads
  def saved_search_items_extract(user)
    user = Access::Core.validate_user(user)

    # execute associated saved_search to get audio_recordings
    audio_recordings_query = self.saved_search.audio_recordings_extract(user)

    command_format = self.script.executable_command.to_s
    file_executable = ''
    copy_paths = nil
    config_string = self.custom_settings
    job_id = self.id

    # create one payload per each audio_recording
    payloads = []
    audio_recordings_query.find_each(batch_size: 1000) do |audio_recording|
      payloads.push(
          {
              command_format: command_format,
              file_executable: file_executable,
              copy_paths: copy_paths,
              config_string: config_string,
              job_id: job_id,

              uuid: audio_recording.uuid,
              id: audio_recording.id,
              datetime_with_offset: audio_recording.recorded_date.iso8601(3),
              original_format: audio_recording.original_format_calculated
          })
    end

    payloads
  end

  # Enqueue payloads representing audio recordings from saved search to asnc processing queue.
  # @param [User] user
  # @return [Array<Hash>] payloads
  def enqueue_items(user)
    payloads = saved_search_items_extract(user)

    results = []

    payloads.each do |payload|

      result = nil
      error = nil

      begin
        result = BawWorkers::Analysis::Action.action_enqueue(payload)
      rescue => e
        error = e
        Rails.logger(self.to_s) { e }
      end

      results.push({payload: payload, result: result, error: error})
    end

    results
  end

end
