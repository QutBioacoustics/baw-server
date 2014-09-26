require 'tasks/run_worker'

require 'csv'

namespace :baw_workers do

  desc 'Enqueue audio recording file checks using Resque'
  task :enqueue_audio_file_checks, [:settings_file, :csv_file] => [:init_worker] do |t, args|

    index_to_key_map = {
        id: 0,
        uuid: 1,
        recorded_date: 2,
        duration_seconds: 3,
        sample_rate_hertz: 4,
        channels: 5,
        bit_rate_bps: 6,
        media_type: 7,
        data_length_bytes: 8,
        file_hash: 9,
        original_file_name: 10
    }

    # load csv file
    CSV.foreach(args.csv_file, {headers: true, return_headers: false}) do |row|

      # get values from row, put into hash that matches what check action expects
      audio_params = index_to_key_map.inject({}) do |hash, (k, v)|
        hash.merge( k.to_sym => row[k.to_s] )
      end

      # special case for original_format
      # get original_format from original_file_name
      original_file_name = audio_params.delete(:original_file_name)
      original_format = original_file_name.blank? ? '' : File.extname(original_file_name).trim('.','')
      audio_params[:original_format] = original_format

      # get original_format from media_type
      media_type_mapping = {
          'audio/mpeg' => 'mp3',
          'audio/wav' => 'wav',
          'audio/x-ms-wma' => 'wma',
          'audio/x-wav' => 'wav',
          'audio/x-wv' => 'wv',
          'video/x-ms-asf' => 'asf',

      }
      audio_params[:original_format] = media_type_mapping[audio_params[:media_type]] if audio_params[:original_format].blank?

      # enqueue
      BawWorkers::Action::AudioFileCheckAction.enqueue(audio_params)
    end


  end

end