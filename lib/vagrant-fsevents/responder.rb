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

        events_to_sync = watches.map do |_, watch|
          events = ChangeEvents.make(mods, adds, removes, watch)
          add_locks(remove_locked_events(select_by_relevance(events)))
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

      # Filters out events still in their change deadzone
      def remove_locked_events(events)
        events.select do |event|
          if @recently_changed[event.relative_path] >= Time.now.to_f
            @logger.change_too_soon(event.relative_path)
            next
          end

          true
        end
      end

      # Adds deadzone locks for given events
      def add_locks(events)
        lock_duration = Time.now.to_f + 2 + (0.02 * events.length)
        @alerter.events(events)
        events.each do |event|
          @recently_changed[event.relative_path] = lock_duration
        end
        events
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
          sync_command = "touch -a '#{changed_files.join("' '")}'"

          unless delete_events.empty?
            deleted_files = delete_events.map(&:full_path_on_guest)
            sync_command += "; rm -rf '#{deleted_files.join("' '")}'"
          end

          machine.communicate.execute(sync_command)
        end
      end

      # Clear any stored change events from runs older than two seconds
      def clear_expired_change_locks
        @recently_changed.each do |rel_path, time|
          @recently_changed.delete(rel_path) if time < Time.now.to_f
        end
      end
    end
  end
end
