#
directory '/data'
bind 'tcp://0.0.0.0:3000'
pidfile '/tmp/puma.pid'
state_path '/tmp/puma.state'
workers 4
preload_app!
environment 'production'

daemonize false
# Allow for `touch tmp/restart.txt` to force puma to restart the app
#plugin :tmp_restart

# Activate the puma control application, mapping location in the nginx config
activate_control_app 'unix:///tmp/pumactl.sock'
