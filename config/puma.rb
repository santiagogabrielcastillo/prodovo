# config/puma.rb

# Threads configuration
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Worker timeout
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# === ESTA ES LA PARTE CRÍTICA PARA RAILWAY ===
# Railway requires binding to :: (IPv6) which also accepts IPv4 connections
# This ensures the app listens on all interfaces on the PORT env var
bind "tcp://[::]:#{ENV.fetch("PORT") { "3000" }}"
# =============================================

# Environment
environment ENV.fetch("RAILS_ENV") { "development" }

# Pidfile
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart
