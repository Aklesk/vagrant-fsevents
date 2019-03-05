require 'vagrant-fsevents/version'
require 'vagrant-fsevents/plugin'

module VagrantPlugins
  # Plugin core module
  module Fsevents
    lib_path = Pathname.new(File.expand_path('vagrant-fsevents', __dir__))
    autoload :Alerter, lib_path.join('alerter')
    autoload :Logger, lib_path.join('logger')
    autoload :Responder, lib_path.join('responder')
    autoload :Paths, lib_path.join('paths')
  end
end
