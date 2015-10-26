require 'socket'
require 'thread'
require 'open-uri'


class Server
  def initialize(logger, student_id)
    @logger     = logger
    @student_id = student_id
    @local_ip = local_ip
    @remote_ip = open('http://whatismyip.akamai.com').read
    logger.info "remote_ip: #{@remote_ip}"
    info 'initialized'
  end

  def run(port_number, max_threads, host='0.0.0.0')
    @running = true
    @port = port_number
    work_q = Queue.new
    @socket = TCPServer.new(host, port_number)

    info "listening on http://#{local_ip}:#{port_number}"    

    # Starts server
    threads = (0...max_threads).map do |i|
      Thread.current['id'] = i
      info "starting thread: #{i}"
      Thread.new do
        begin   
          while @running
            if work_q.length > 0
              client = work_q.pop
              handle_request(client)
            else
              sleep(0.05)
            end
          end
        rescue ThreadError
          puts 'oopps ThreadError...'
          puts ThreadError
        end
      end
    end;
    info 'all threads started'
    while @running
      begin
        work_q.push(@socket.accept)
      rescue IOError
        # Socket closed by kill function
        puts 'Closed'
      end
    end

    # Wait for threads to join
    threads.map(&:join)
    puts 'Byeee :)'
  end

  def info(msg)
    puts msg
    @logger.info msg
  end

  def handle_request(client)
    puts 'handle_request'
    data = client.gets # Read 1st line from socket
    # data = client.read # Read all data

    if data.start_with?("HELO")
      text = helo(data, client)
    elsif data == "KILL_SERVICE\n"
      text = kill(data, client)
    else
      text = unknown_message(data, client)
    end
    # Force delay
    sleep(0.5)
    client.puts text
    client.close
  end
    
  # Handle different requests
  def helo(data, client)
    info "received HELO"
    text = "#{data}IP:#{@remote_ip}\nPort:#{@port}\nStudentID:#{@student_id}\n"
    info "returning: '#{text}'"
    return text
  end
  def unknown_message(data, client)
    text = "Unknown message[#{data.length}]: '#{data}'"
    info text
    info "returning: '#{text}'"
    return text
  end
  def kill(data, client)
    info "Killing"
    @running = false
    @socket.close
    text = "Server closing\n"
    info "returning: '#{text}'"
    return text
  end

  def local_ip
    orig = Socket.do_not_reverse_lookup  
    Socket.do_not_reverse_lookup = true # turn off reverse DNS resolution temporarily
    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1 # googles ip
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
end
