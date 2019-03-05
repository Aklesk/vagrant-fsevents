module VagrantPlugins
  module Fsevents
    # Place to store messages that will be seen by the user
    class Alerter
      # Alert the user to a successful folder watch start
      def watching(machine, rel_path)
        machine.ui.info("fsevents: Watching #{rel_path}")
      end

      def event(event)
        word = 'Changed' if event.type == :modified
        word = 'Added' if event.type == :added
        word = 'Removed' if event.type == :removed

        event.watch[:machine].ui.info(
          "fsevents: #{word}: #{event.relative_path}"
        )
      end
    end
  end
end
