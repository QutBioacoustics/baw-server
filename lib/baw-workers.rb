require 'active_support/all'
require 'logger'
require 'baw-audio-tools'
require 'resque'

require 'baw-workers/version'

module BawWorkers
  autoload :MediaAction, 'baw-workers/media_action'

  Resque.redis = Settings.resque.connection

end
