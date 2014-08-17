require 'spec_helper'
require 'fakeredis'

describe 'baw_workers:setup_worker' do
  include_context 'rake_tests'
  include_context 'rspect_output_files'

  context 'rake task' do

    it 'runs the setup task for bg worker' do

      store_pid_file = Settings.resque.background_pid_file
      Settings.resque['background_pid_file'] = './tmp/resque_worker.pid'

      run_rake_task(rake_task_name, default_settings_file)

      expect(resque_output_log_content).to include("===> Using settings file #{default_settings_file}")
      expect(resque_output_log_content).to include('===> Polling queues example.')
      expect(resque_output_log_content).to include('===> Log level: 1.')
      expect(resque_output_log_content).to include('===> Polling every 5 seconds')
      expect(resque_output_log_content).to include('===> Running in background with pid file ./tmp/resque_worker.pid.')

      Settings.resque['background_pid_file'] = store_pid_file
    end

    it 'runs the setup task for fg worker' do

      store_pid_file = Settings.resque.background_pid_file
      Settings.resque['background_pid_file'] = nil

      run_rake_task(rake_task_name, default_settings_file)

      expect(rspec_stdout_content).to include("===> Using settings file #{default_settings_file}")
      expect(rspec_stdout_content).to include('===> Polling queues example.')
      expect(rspec_stdout_content).to include('===> Log level: 1.')
      expect(rspec_stdout_content).to include('===> Polling every 5 seconds')
      expect(rspec_stdout_content).to include('===> Running in foreground.')

      Settings.resque['background_pid_file'] = store_pid_file
    end
  end
end
