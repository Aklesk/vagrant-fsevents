# vagrant-fsevents

Activatable filesystem change forwarding to your [Vagrant][vagrant] VM.

## Problem this solves

When developing inside [VirtualBox][virtualbox]-based VMs with synced folders,
filesystem events in the host system do not propagate to processes running inside
the VM. This causes difficulty for some development environments, particularly
when using packagers such as Webpack, as they do not update/rebuild in response
to editor changes.

There are a number of partial solutions in the wild, but none are perfect in all
circumstances. This project builds on [`vagrant-fsnotify`][vagrant-fsnotify] by
@adrienkohlbecker to provide a simple on-demand, low resource, and highly
transparent solution. It is particularly effective for a standard development
VM which is used widely by multiple teams where perhaps only a few people even
need filesystem event forwarding, and it's not desirable to have an always-on
solution that hogs system resources.

## Mechanism

`vagrant-fsevents` runs a process listening for filesystem changes on the host
that affect shared folders, and forwards them to the VM as shell commands such
as `touch` (and `rm`, as appropriate) using Vagrant's VM administration API.

## Caveats

Inconveniently, while filesystem events are not properly forwarded into the VM,
they're forwarded back out without issue, so every time this plugin triggers an
update in the VM, a second filesystem event is fired in the host system. To
prevent the obvious infinite-loop issue this could cause, a minimum 2-second
per-file dead-zone is used after each update event (with additional time for
updates with many files changed)

This is unfortunately only a partial solution, and large filesystem changes such
as checking out another git branch can still cause issues such as infinite
notification loops and accidental creation of blank files that should have been
removed. However, these issues are usually minor, easily fixed via git, and can
be entirely avoided by killing the monitor process before major changes.

## Installation

`vagrant-fsevents` is a [Vagrant][vagrant] plugin and can be installed by
running:

```console
$ vagrant plugin install vagrant-fsevents
```

[Vagrant][vagrant] version 1.7.3 or greater is required.

## Usage

### Basic setup

In `Vagrantfile` synced folder configuration, add the `fsevents: true`
option. For example, in order to enable `vagrant-fsevents` for the the default
`/vagrant` shared folder, add the following:

```ruby
config.vm.synced_folder ".", "/vagrant", fsevents: true
```

When the guest virtual machine is up, run the following:

```console
$ vagrant fsevents
```

This starts the long running process that captures filesystem events on the host
and forwards them to the guest virtual machine.

### Multi-VM environments

In multi-VM environments, you can specify the name of the VMs targeted by
`vagrant-fsevents` using:

```console
$ vagrant fsevents <vm-name-1> <vm-name-2> ...
```

### Excluding files

To exclude files or directories from being watched, you can add an `:exclude`
option, which takes an array of strings (matched as a regexp against relative
paths):

```ruby
config.vm.synced_folder ".", "/vagrant", fsevents: true,
                                         exclude: ["path1", "some/directory"]
```

This will exclude all files inside the `path1` and `some/directory`. It will
also exclude files such as `another/directory/path1`.

### Including files

By default, the entire directory tree of the synced folder on the host machine
is watched. However, there are potential [issues with symlinks][symlink-issues]
that can arise from this approach, so until a more robust fix is in place you
can work around symlink issues by overriding the default watch path(s) with the
`:include` option. This takes an array of strings (as relative paths) to folders
which must exist when the watch begins (no regexp support), and replaces the
default synced_folder path with these individual folder paths.

```ruby
config.vm.synced_folder ".", "/vagrant", fsevents: true,
                                         include: ["./src"]
```

This will watch only the files inside `src`, ignoring all other files and
folders in the synced path.

### Guest path override

If your actual path on the VM is not the same as the one in `synced_folder`, for
example when using [`vagrant-bindfs`][vagrant-bindfs], you can use the
`:override_guestpath` option:

```ruby
config.vm.synced_folder ".", "/vagrant", fsevents: true,
                                         override_guestpath: "/real/path"
```

This will forward a notification on `./myfile` to `/real/path/myfile` instead of
`/vagrant/myfile`.

### Select filesystem events

By default, when the `:fsevents` key in the `Vagrantfile` is configured with
`true`, all filesystem events are forwarded to the VM (creation, modification,
and removal). If, instead, you want to select only some of those events to be
forwarded (e.g. you don't care about file removals), you can use an Array of
Symbols among the following options: `:added`, `:modified` and `:removed`.

For example, to forward only added files events to the default `/vagrant`
folder, add the following to the `Vagrantfile`:

```ruby
config.vm.synced_folder ".", "/vagrant", fsevents: [:added]
```

## Original work

This plugin was originally [`vagrant-fsnotify`][vagrant-fsnotify] by @adrienkohlbecker,
but was renamed to facilitate continued development.
This plugin used [`vagrant-rsync-back`][vagrant-rsync-back] by @smerill and the
[Vagrant][vagrant] source code as a starting point.

[vagrant]: https://www.vagrantup.com/
[virtualbox]: https://www.virtualbox.org/
[jekyll]: http://jekyllrb.com/
[guard]: http://guardgem.org/
[forwarding-file-events-over-tcp]: https://github.com/guard/listen#forwarding-file-events-over-tcp
[vagrant-bindfs]: https://github.com/gael-ian/vagrant-bindfs
[vagrant-rsync-back]: https://github.com/smerrill/vagrant-rsync-back
[vagrant-fsnotify]: https://github.com/adrienkohlbecker/vagrant-fsnotify
[symlink-issues]: https://github.com/guard/listen/wiki/Duplicate-directory-errors
