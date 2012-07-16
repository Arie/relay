load 'deploy' if respond_to?(:namespace) # cap2 differentiator
load 'config/deploy'
load 'config/recipes/relay_config'
load 'config/recipes/thin_config'
require "bundler/capistrano"
require 'capistrano_colors' unless ENV['COLORIZE_CAPISTRANO'] == 'off'

require "rvm/capistrano"                  # Load RVM's capistrano plugin.
