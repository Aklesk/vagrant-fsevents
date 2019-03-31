require_relative 'errors'

module VagrantPlugins
  module Fsevents
    # A single changed path string of a specified change type
    class ChangeEvents
      attr_reader :path
      attr_reader :type
      attr_reader :watch
      attr_reader :sync_path
      attr_reader :watch_path
      attr_reader :relative_path
      attr_reader :full_path_on_guest

      # Takes the output of a listen callback (as arrays of strings of
      # files split by type of change) and converts them into single events
      # for a specific watch definition
      def self.make(mods, adds, removes, watch)
        change_events = []
        structure = { modified: mods, added: adds, removed: removes }
        structure.each do |type, files|
          files.each do |path|
            change_events.push new(path, type, watch)
          end
        end
        change_events
      end

      def initialize(path, type, watch)
        @path = path
        @type = type
        @sync_path = watch[:sync_path]
        @watch_path = watch[:watch_path]
        @watch = watch

        @relative_path = path.sub(sync_path, '')
        @full_path_on_guest = File.join(
          (watch[:opts][:override_guestpath] || watch[:opts][:guestpath]),
          @relative_path
        )
      end
    end
  end
end
