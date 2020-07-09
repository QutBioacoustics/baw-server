# frozen_string_literal: true

def emulate_resque_worker_with_job(job_class, job_args, opts = {})
  # see http://stackoverflow.com/questions/5141378/how-to-bridge-the-testing-using-resque-with-rspec-examples
  queue = opts[:queue] || 'test_queue'

  Resque::Job.create(queue, job_class, *job_args)

  emulate_resque_worker(queue, opts[:verbose], opts[:fork])
end

# from https://github.com/resque/resque/blob/1-x-stable/test/test_helper.rb
def without_forking
  orig_fork_per_job = ENV['FORK_PER_JOB']
  begin
    ENV['FORK_PER_JOB'] = 'false'
    yield
  ensure
    ENV['FORK_PER_JOB'] = orig_fork_per_job
  end
end

# Emulate a resque worker
# @param [String] queue
# @param [Boolean] verbose
# @param [Boolean] fork
# @return [Array] worker, job
# @param [String] override_class - specify to switch what type actually processes the payload at the last minute. Useful for testing.
def emulate_resque_worker(queue, verbose, fork, override_class = nil)
  queue ||= 'test_queue'

  worker = Resque::Worker.new(queue)
  worker.very_verbose = true if verbose

  job = nil

  if fork
    # do a single job then shutdown
    def worker.done_working
      super
      shutdown
    end

    # can't fork during tests
    without_forking do
      # start worker working, using interval of 0.5 seconds
      # see Resque::Worker#work
      worker.work(0.5) do |worker_job|
        job = worker_job
      end
    end

  else
    job = worker.reserve

    unless job.nil?
      job.payload['class'] = override_class if override_class
      finished_job = worker.perform(job)
      job = finished_job
    end
  end

  [worker, job]
end

class FakeJob
  def self.perform(*job_args)
    {
      job_args: job_args,
      result: Time.now
    }
  end
end
