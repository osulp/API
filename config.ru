# This file is used by Rack-based servers to start the application.
#

# Initialize Honeycomb before everything else
require 'honeycomb-beeline'
Honeycomb.init

require_relative 'config/environment'

run Rails.application
