# frozen_string_literal:true
#

directory '/data'
bind 'tcp://0.0.0.0:3000'
pidfile '/tmp/puma.pid'
state_path '/tmp/puma.state'
workers 4
preload_app!
environment 'staging'

# Activate the puma control application, mapping location in the nginx config
activate_control_app 'unix:///tmp/pumactl.sock'
