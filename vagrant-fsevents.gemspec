lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-fsevents/version'

Gem::Specification.new do |spec|
  spec.name           = 'vagrant-fsevents'
  spec.version        = VagrantPlugins::Fsevents::VERSION
  spec.authors        = ['Wolf Hatch']
  spec.email          = ['wolf@mechrus.com']
  spec.summary        = 'Forward filesystem change notifications '\
                        'to your Vagrant VM'
  spec.description    = 'Use vagrant-fsevents to forward filesystem '\
                        'change notifications to your Vagrant VM'
  spec.homepage       = 'https://github.com/Fendrian/vagrant-fsevents'
  spec.license        = 'MIT'

  spec.files          = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir         = 'exe'
  spec.executables    = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths  = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
