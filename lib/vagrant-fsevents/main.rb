require 'listen'
require_relative 'errors'

module VagrantPlugins
  module Fsevents
    # Class containing the main plugin activities
    class Main < Vagrant.plugin('2', :command)
      include Vagrant::Action::Builtin::MixinSyncedFolders

      LOGGING_CONTEXT = 'vagrant::commands::fsevents'.freeze
      ADAPTER = Listen::Adapter.select.inspect.freeze

      # Main method for constructing the plugin
      def execute
        init_supporting_classes
        init_path_data
        log_listening_start_event
        print_watch_paths_to_console
        start_listening
      end

      # Instantiate supporting classes
      def init_supporting_classes
        @logger = VagrantPlugins::Fsevents::Logger.new LOGGING_CONTEXT
        @alerter = VagrantPlugins::Fsevents::Alerter.new
        @responder = VagrantPlugins::Fsevents::Responder.new @logger, @alerter
        @paths = VagrantPlugins::Fsevents::Paths.new
      end

      # Build list of paths to watch and ignore
      def init_path_data
        with_target_vms(command_line_argv) do |machine|
          unless machine.communicate.ready?
            raise Vagrant::Errors::VMNotCreatedError
          end

          @paths.process(machine, synced_folders(machine))
        end

        raise NothingToSyncError.new if @paths.watch.empty?
      end

      def self.synopsis
        'forwards filesystem events to virtual machine'
      end

      # Log that we've started listening
      def log_listening_start_event
        @logger.listening_with_adapter(ADAPTER, @paths.watch, @paths.ignore)
      end

      # Alert the user to the paths we're watching
      def print_watch_paths_to_console
        @paths.watch.each do |path, data|
          @alerter.watching(data[:machine], path)
        end
      end

      # Start the actual listener that will respond to file changes
      def start_listening
        listener = Listen.to(
          *@paths.watch.keys,
          ignore: @paths.ignore,
          &@responder.callback_proc.curry[@paths.watch]
        )

        create_interrupt_callback(listener)
      end

      # Create the callback that lets us know when we've been interrupted
      def create_interrupt_callback(listener)
        queue    = Queue.new
        callback = lambda do
          # This needs to execute in another thread because Thread
          # synchronization can't happen in a trap context.
          Thread.new { queue << true }
        end

        # Run the listener in a busy block so that we can cleanly
        # exit once we receive an interrupt.
        Vagrant::Util::Busy.busy(callback) do
          listener.start
          queue.pop
          listener.stop if listener.state != :stopped
        end

        0
      end

      # This parses the command line arguments passed by the user
      def command_line_argv
        parse_options OptionParser.new do |o|
          o.banner = 'Usage: vagrant fsevents [vm-name]'
          o.separator ''
        end
      end
    end
  end
end
