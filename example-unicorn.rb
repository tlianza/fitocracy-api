@dir = ENV['APP_HOME']

# Set the working application directory
# working_directory "/path/to/your/app"
working_directory @dir

# Unicorn PID file location
# pid "/path/to/pids/unicorn.pid"
pid "#{@dir}/tmp/pids/unicorn.pid"

# Path to logs
stderr_path "#{@dir}/log/unicorn.log"
stdout_path "#{@dir}/log/unicorn.log"

# Unicorn socket
# listen "/tmp/unicorn.[app name].sock"
# listen "#{@dir}/tmp/unicorn.fitocracy-api.sock", :backlog => 64
listen "127.0.0.1:8080"

# Number of processes
# worker_processes 4
worker_processes 2

# Time-out
timeout 30