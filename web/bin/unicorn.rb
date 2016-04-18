# This was taken pretty much verbatim from the sinatra recipe:
# http://recipes.sinatrarb.com/p/deployment/nginx_proxied_to_unicorn

@dir = File.dirname(File.absolute_path(__FILE__))
worker_processes 8
working_directory @dir
timeout 30

listen "/var/run/feronia/sockets/unicorn.sock", :backlog => 2048
#listen "http://127.0.0.1:5000"

pid "/var/run/feronia/pids/unicorn.pid"

stderr_path "/var/log/feronia/unicorn.stderr.log"
stdout_path "/var/log/feronia/unicorn.stdout.log"


