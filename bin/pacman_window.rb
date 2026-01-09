#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pacman/window_game'

Pacman::WindowGame.new.show
