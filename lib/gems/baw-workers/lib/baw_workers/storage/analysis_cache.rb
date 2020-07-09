# frozen_string_literal: true

require 'pathname'

module BawWorkers
  module Storage
    # Provides access to analysis cache storage.
    class AnalysisCache
      include BawWorkers::Storage::Common

      JOB_ID_SYSTEM = 'system'

      # Create a new BawWorkers::Storage::AnalysisCache.
      # @param [Array<String>] storage_paths
      # @return [void]
      def initialize(storage_paths)
        # array of top-level folder paths to store cached analysis results
        @storage_paths = storage_paths
        @separator = '_'
        @extension_indicator = '.'
      end

      # Get the file name
      # @param [Hash] opts
      # @return [String] file name for stored file
      def file_name(opts)
        validate_file_name(opts)

        BawWorkers::Validation.normalise_path(opts[:file_name], nil)
      end

      # Get file names
      # @param [Hash] opts
      # @return [Array<String>]
      def file_names(opts)
        [file_name(opts)]
      end

      # Construct the partial path to an analysis result file.
      # @param [Hash] opts
      # @return [String] partial path to analysis result file.
      def partial_path(opts)
        validate_job_id(opts)
        validate_uuid(opts)
        validate_sub_folders(opts)

        # ./<job_id>/<guid first 2 chars>/<full guid>/<subfolder(s)>/

        job_id = opts[:job_id].to_s.strip.downcase
        guid_chars = opts[:uuid][0, 2].downcase
        guid = opts[:uuid].downcase
        sub_folder = File.join(*opts[:sub_folders])

        partial_path = File.join(job_id, guid_chars, guid, sub_folder)

        BawWorkers::Validation.normalise_path(partial_path, nil)
      end

      # Construct the path to an analysis results root folder.
      # @param [Hash] opts
      # @return [String] path to analysis results root folder.
      def job_path(opts)
        validate_job_id(opts)

        # ./<job_id>

        job_id = opts[:job_id].to_s.strip.downcase

        partial_path = File.join(job_id)

        BawWorkers::Validation.normalise_path(partial_path, nil)
      end

      # Get all possible root paths for an analysis job.
      # @param [Hash] opts
      # @return [Array<String>]
      def possible_job_paths_dir(opts)
        # partial_path is implemented in each store.
        @storage_paths.map { |path| File.join(path, job_path(opts)) }
      end

      # Extract information from a file name.
      # @param [String] file_path
      # @return [Hash] info
      def parse_file_path(file_path)
        # check that file_path starts with one of the possible base directories
        base_dirs = possible_dirs
        base_dirs_matched = base_dirs.select { |base_dir| file_path.start_with?(base_dir) }
        if base_dirs_matched.size != 1
          raise ArgumentError, "Must start with one of '#{base_dirs.join('\', \'')}': #{file_path} "
        end

        # remove base dir from file_path
        relative_path = file_path.sub(base_dirs_matched.first, '')

        # clean file_path so it is more likely to match
        relative_path_clean = BawWorkers::Validation.normalise_path(relative_path, nil)

        # extract parts of path
        path_parts = Pathname(relative_path_clean).each_filename.to_a

        job_id = path_parts[0].to_i.to_s == path_parts[0].to_s ? path_parts[0].to_i : JOB_ID_SYSTEM

        opts = {
          job_id: job_id,
          uuid: path_parts[2],
          sub_folders: path_parts[3..-2],
          file_name: path_parts[-1]
        }

        validate_job_id(opts)
        validate_uuid(opts)
        validate_sub_folders(opts)
        validate_file_name(opts)

        opts
      end
    end
  end
end
