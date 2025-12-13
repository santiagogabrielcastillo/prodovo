# config/puma.rb

# Threads configuration
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Worker timeout
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# === ESTA ES LA PARTE CRÍTICA PARA RAILWAY ===
# Le decimos a Puma que escuche en 0.0.0.0 y en el puerto que Railway nos da.
port ENV.fetch("PORT") { 3000 }
# Por seguridad en Docker, a veces es necesario ser explícito:
bind "tcp://0.0.0.0:#{ENV.fetch("PORT") { "3000" }}"
# =============================================

# Environment
environment ENV.fetch("RAILS_ENV") { "development" }

# Pidfile
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart
