require_relative 'server'
require 'logger'


MAX_THREADS  = 4
STUDENT_ID   = 'a04dcb0fee025f2b48663ba413d0b8d481db11b65b254d41e3611b834c17d6d5'
DEFAULT_PORT = 2000
port_number = ARGV[0] || DEFAULT_PORT

Thread.current['id'] = 0

# Make a logger
logger = Logger.new('log/server.log')
logger.formatter = proc do |severity, datetime, progname, msg|
  "#{severity} [#{Time.now.strftime('%H:%M:%S')}] T#{Thread.current['id']}: #{msg}\n"
end
logger.info 'made logger'

require 'open-uri'
remote_ip = open('http://whatismyip.akamai.com').read
logger.info "remote_ip: #{remote_ip}"

# Make server
server = Server.new(logger, STUDENT_ID)
server.run(port_number, MAX_THREADS)

