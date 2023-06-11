require 'async'
require 'fiber'
require 'socket'

scheduler = Async::Scheduler.new
Fiber.set_scheduler scheduler

port = (ARGV[0] || 9090).to_i
server = TCPServer.new('127.0.0.1', port)

Fiber.schedule do
  loop do
    client = server.accept

    Fiber.schedule do
      client.recv(1024)
      client.send("HTTP/1.1 204 No Content\r\nConnection: close\r\n\r\n", 0)
      client.close
    end
  end
end
