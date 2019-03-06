module VagrantPlugins
  module Fsevents
    # Methods that log to Vagrant's internal log for debugging
    class Logger < Log4r::Logger
      # Logs listening start messages
      def listening_with_adapter(adapter, paths, ignores)
        info("Listening to paths: #{paths.keys.sort.inspect}")
        info("Listening via: #{adapter}")
        info("Ignoring #{ignores.length} paths:")
        ignores.each do |ignore|
          info("  -- #{ignore}")
        end
      end

      # Logs when the file change callback is triggered
      def callback_start(mods, adds, removes)
        info('File change callback called!')
        info("  - Modified: #{mods.inspect}")
        info("  - Added: #{adds.inspect}")
        info("  - Removed: #{removes.inspect}")
      end

      # Logs when a path was changed too quickly and was ignored
      def change_too_soon(rel_path)
        info(
          "#{rel_path} was changed less than two seconds ago, skipping"
        )
      end
    end
  end
end
