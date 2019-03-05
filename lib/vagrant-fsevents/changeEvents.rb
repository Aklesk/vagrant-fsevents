require_relative 'errors'

module VagrantPlugins
  module Fsevents
    # A single changed path string of a specified change type
    class ChangeEvents
      attr_reader :path
      attr_reader :type
      attr_reader :watch
      attr_reader :watch_path

      # Takes the output of a listen callback (as arrays of strings of
      # files split by type of change) and converts them into single events
      def self.make_from(modified, added, removed)
        change_events = []
        structure = { modified: modified, added: added, removed: removed }
        structure.each do |type, files|
          files.each { |path| change_events.push new(path, type) }
        end
        change_events
      end

      def initialize(path, type, watch_path = nil, watch = nil)
        @path = path
        @type = type
        @watch = watch
        @watch_path = watch_path
      end

      # Takes an unassigned event, and makes a copy localised to a single watch
      def bind_watch(watch_path, watch)
        self.class.new(@path, @type, watch_path, watch)
      end

      # Returns the relative path of an event
      def relative_path
        raise UnboundEventError unless @watch

        @path.sub(@watch_path, '')
      end

      def full_path_on_guest
        raise UnboundEventError unless @watch && @watch_path

        File.join(
          (@watch[:opts][:override_guestpath] || @watch[:opts][:guestpath]),
          relative_path
        )
      end
    end
  end
end
