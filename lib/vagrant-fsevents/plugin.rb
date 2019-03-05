begin
  require 'vagrant'
rescue LoadError
  raise 'The vagrant-fsevents plugin must be run within Vagrant.'
end

if Vagrant::VERSION < '1.7.3'
  raise <<-ERROR
    The vagrant-fsevents plugin is only compatible with Vagrant 1.7.3+. If you can't
    upgrade, consider installing an old version of vagrant-fsnotify with:
    $ vagrant plugin install vagrant-fsnotify --plugin-version 0.0.6.
  ERROR
end

module VagrantPlugins
  module Fsevents
    # Class to instantiate the plugin
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-fsevents'

      command 'fsevents' do
        require_relative 'main'
        Main
      end
    end
  end
end
