module VagrantPlugins
  module Fsevents
    # Place to store messages that will be seen by the user
    class Alerter
      # Alert the user to a successful folder watch start
      def watching(machine, rel_path)
        machine.ui.info("fsevents: Watching #{rel_path}")
      end

      def make_event_change_string(change_event)
        word = 'Changed' if change_event.type == :modified
        word = 'Added' if change_event.type == :added
        word = 'Removed' if change_event.type == :removed

        "fsevents: #{word}: #{change_event.relative_path}"
      end

      def events(change_events)
        return if change_events.empty?

        alert_lines = change_events.map do |change_event|
          make_event_change_string(change_event)
        end

        alert = alert_lines.join("\n")

        change_events[0].watch[:machine].ui.info(alert)
      end
    end
  end
end
