require 'yaml'
require 'logger'
require 'open-uri'
require 'rest_client'
require_relative './lib/watcher.rb'

Watcher.run
