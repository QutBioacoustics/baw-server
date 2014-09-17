module BawWorkers
  # Runs checks on original audio recording files.
  class AudioFileCheckAction

    # include common methods
    include BawWorkers::Common

    # Ensure that there is only one job with the same payload per queue.
    include Resque::Plugins::UniqueJob

    # a set of keys starting with 'stats:jobs:queue_name' inside your Resque redis namespace
    extend Resque::Plugins::JobStats

    # All methods do not require a class instance.
    class << self

      # Delay when the unique job key is deleted (i.e. when enqueued? becomes false).
      # @return [Fixnum]
      def lock_after_execution_period
        30
      end

      # Get the queue for this action. Used by `resque`.
      # @return [Symbol] The queue.
      def queue
        BawWorkers::Settings.resque.queues.maintenance
      end

      # Enqueue an audio file check request.
      # @param [Hash] audio_params
      # @return [Boolean] True if job was queued, otherwise false. +nil+
      #   if the job was rejected by a before_enqueue hook.
      def enqueue(audio_params)
        audio_params_sym = AudioFileCheck.validate(audio_params)
        Resque.enqueue(AudioFileCheckAction, audio_params_sym)
        BawWorkers::Settings.logger.info(self.name) {
          "Enqueued from AudioFileCheckAction #{audio_params}."
        }
      end

      # Perform work. Used by `resque`.
      # @param [Hash] audio_params
      # @return [Array<String>] existing paths after moves
      def perform(audio_params)
        audio_file_check = AudioFileCheck.new
        updated_existing = audio_file_check.modify(audio_params)

        log_file = Settings.paths.workers_log_file
        csv_name = File.basename(log_file, File.extname(log_file))
        csv_file = File.join(File.dirname(log_file), csv_name + '.csv')
        audio_file_check.write_csv(csv_file)

        updated_existing
      end

    end
  end
end