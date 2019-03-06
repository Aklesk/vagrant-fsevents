require_relative 'changeEvents'

module VagrantPlugins
  module Fsevents
    # Defines how to respond to a change event
    class Responder
      def initialize(logger, alerter)
        @logger = logger
        @alerter = alerter
        @recently_changed = Hash.new { |hash, key| hash[key] = 0 }
      end

      # This is the main callback that responds to a change detection event
      def callback(watches, mods, adds, removes)
        @logger.callback_start(mods, adds, removes)

        clear_expired_change_locks

        events_to_sync = watches.map do |watch_path, watch|
          events = ChangeEvents.make(mods, adds, removes, watch_path, watch)
          process_deadzone(select_by_relevance(events))
        end

        forward_events_to_vms(events_to_sync.flatten)
      rescue StandardError => e
        @logger.error("#{e}: #{e.message}")
      end

      # Return the callback as a proc that can be passed to the listener
      def callback_proc
        method(:callback).to_proc
      end

      # Filters out events whose path or type don't match their watch
      def select_by_relevance(events)
        events.select do |event|
          next unless event.path.start_with?(event.watch_path)

          watch = event.watch[:opts][:fsevents]
          (watch == true || watch.includes?(event.type))
        end
      end

      # Updates deadzones state, and filters out events still in deadzones
      def process_deadzone(events)
        events.select do |event|
          if @recently_changed[event.relative_path] >= (Time.now.to_i - 2)
            @logger.change_too_soon(event.relative_path)
            next
          end

          # Add lock for future deadzone checking
          @recently_changed[event.relative_path] = Time.now.to_i
          @alerter.event(event)
          true
        end
      end

      def group_events_by_machine(events)
        machine_hash = Hash.new { |hash, key| hash[key] = [] }
        events.each { |event| machine_hash[event.watch[:machine]] << event }
        machine_hash
      end

      # Action events that have been bound to a watch and passed checks
      def forward_events_to_vms(ungrouped_events)
        group_events_by_machine(ungrouped_events).each do |machine, events|
          changed_files = events.map(&:full_path_on_guest)
          delete_events = events.select { |event| event.type == :removed }
          machine.communicate.execute("touch -a '#{changed_files.join("' '")}'")

          next if delete_events.empty?

          deleted_files = delete_events.map(&:full_path_on_guest)
          machine.communicate.execute("rm -rf '#{deleted_files.join("' '")}'")
        end
      end

      # Clear any stored change events from runs older than two seconds
      def clear_expired_change_locks
        @recently_changed.each do |rel_path, time|
          @recently_changed.delete(rel_path) if time < (Time.now.to_i - 2)
        end
      end
    end
  end
end
