module VagrantPlugins
  module Fsevents
    # Error indicating that there is no valid path to watch for changes
    class NothingToSyncError < Vagrant::Errors::VagrantError
      error_message %q(
        Nothing to sync.

        Note that the valid values for the `:fsevents' configuration key on
        `Vagrantfile' are either `true' (which forwards all kinds of filesystem
        events) or an Array containing symbols among the following options:
        `:modified', `:added' and `:removed' (in which case, only the specified
        filesystem events are forwarded).

        For example, to forward all filesystem events to the default `/vagrant'
        folder, add the following to the `Vagrantfile':

          config.vm.synced_folder ".", "/vagrant", fsevents: true

        And to forward only added files events to the default `/vagrant' folder,
        add the following to the `Vagrantfile':

          config.vm.synced_folder ".", "/vagrant", fsevents: [:added]

        Exiting...
      ).gsub(/^[ ]{8}/, '')
    end

    # Thrown if path info is accessed for an event that isn't bound to a watch
    class UnboundEventError < Vagrant::Errors::VagrantError
      error_message 'Incorrect usage of unbound internal event'
    end
  end
end
