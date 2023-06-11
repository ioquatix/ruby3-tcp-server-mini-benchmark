#!/usr/bin/env ruby

require 'console'
require 'socket'

def measure(arguments, port)
  command = ["wrk", *arguments, "http://127.0.0.1:#{port}"]
  Console.logger.info("measure", Console::Event::Spawn.for(command))
  system(*command)
end

def wait_for(port)
  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  
  loop do
    begin
      TCPSocket.new("127.0.0.1", port).close
      break
    rescue Errno::ECONNREFUSED
      sleep 0.01
    end
  end

  return Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
end

def with_server(command, port)
  Console.logger.info "Starting server..."
  pid = Process.spawn("/usr/bin/env", "ruby", command, port.to_s)
  raise "Failed to start server!" unless Process.waitpid(pid, Process::WNOHANG).nil?
  startup_time = wait_for(port)
  Console.logger.info "Server started after #{Console::Clock.formatted_duration(startup_time)} with pid #{pid}..."
  yield
ensure
  if pid
    Console.logger.info "Killing process #{pid}..."
    kill_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    Process.kill("HUP", pid)
    Console.logger.info "Waiting for process #{pid} to die..."
    status = Process.waitpid(pid)
    kill_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - kill_time
    Console.logger.info "Process #{pid} exited with status #{status} after #{Console::Clock.formatted_duration(kill_duration)}."
  end
end

port = 9000

loop do
  with_server(ARGV[0], port) do
    measure(%w[-t1 -c1 -d1s], port)
  end
  port += 1
end

