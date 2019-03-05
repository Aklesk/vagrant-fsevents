module VagrantPlugins
  module Fsevents
    # Logic for paths to watch and ignore
    class Paths
      attr_reader :watch
      attr_reader :ignore

      def initialize
        @watch = {}
        @ignore = []
      end

      def process(machine, folders)
        add_folders_to_watch(machine, folders)
        add_folders_to_ignore(folders)
      end

      # Populates `@watch` attribute from a single VM instance
      def add_folders_to_watch(machine, folders)
        folders.values.each do |folder|
          folder.each do |id, opts|
            next unless active_for_folder? opts[:fsevents]

            hostpath = File.expand_path(opts[:hostpath], machine.env.root_path)
            hostpath = Vagrant::Util::Platform.fs_real_path(hostpath).to_s

            # Avoid creating a nested directory
            hostpath += '/' unless hostpath.end_with?('/')

            @watch[hostpath] = { id: id, machine: machine, opts: opts }
          end
        end
      end

      # Populates `@ignore` attribute from a single VM instance
      def add_folders_to_ignore(folders)
        folders.values.each do |folder|
          folder.values.each do |opts|
            next unless active_for_folder?(opts[:fsevents])

            Array(opts[:exclude]).each do |pattern|
              @ignore << exclude_to_regexp(pattern.to_s)
            end
          end
        end
      end

      # This is REALLY ghetto, but its a start. We can improve and
      # keep unit tests passing in the future.
      def exclude_to_regexp(exclude)
        exclude = exclude.gsub('**', '|||GLOBAL|||')
        exclude = exclude.gsub('*', '|||PATH|||')
        exclude = exclude.gsub('|||PATH|||', '[^/]*')
        exclude = exclude.gsub('|||GLOBAL|||', '.*')

        Regexp.new(exclude)
      end

      # checks to ensure that a path watch is not completely disabled
      def active_for_folder?(options)
        (
          (options == true) || (
            options.respond_to?(:include?) &&
            (
              options.include?(:modified) ||
              options.include?(:added) ||
              options.include?(:removed)
            )
          )
        )
      end
    end
  end
end
