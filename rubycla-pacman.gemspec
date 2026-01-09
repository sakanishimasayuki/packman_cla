# frozen_string_literal: true

require_relative 'lib/pacman/version'

Gem::Specification.new do |spec|
  spec.name                  = 'rubycla-pacman'
  spec.version               = Pacman::VERSION
  spec.authors               = ['sanda']
  spec.summary               = 'Pacman-style game in Ruby with Gosu window.'
  spec.description           = 'Simple Pacman-like 2D game rendered via Gosu. Launch with `pacman`.'
  spec.files                 = Dir['lib/**/*', 'exe/*', 'README.md', 'config/maps/**/*.yaml']
  spec.bindir                = 'exe'
  spec.executables           = ['pacman']
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 2.7'
  # ランタイム依存は手動インストール推奨（MSYS2必要のため）
  # spec.add_runtime_dependency 'gosu', '>= 1.0'
end
