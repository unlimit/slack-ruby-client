module Slack
  module RealTime
    class Socket
      attr_accessor :url
      attr_accessor :socket

      def initialize(url)
        @url = url
        @socket = OpenSSL::SSL::SSLSocket.new TCPSocket.new URI(@url).host, 443
        @socket.connect
      end

      def write(*args)
        socket.write(*args)
      end

      def send_data(data)
        @ws.send(data) if @ws
      end


      def disconnect!
        @ws.close if @ws
      end

      def connected?
        !@socket.nil?
      end


      protected

      def close(_event)
        @ws = nil
      end

    end
  end
end
