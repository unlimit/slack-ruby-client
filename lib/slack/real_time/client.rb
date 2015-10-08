module Slack
  module RealTime
    class Client
      class ClientNotStartedError < StandardError; end
      class ClientAlreadyStartedError < StandardError; end

      include Api::MessageId
      include Api::Ping
      include Api::Message
      include Api::Typing

      attr_accessor :web_client
      attr_accessor(*Config::ATTRIBUTES)

      def initialize(options = {})
        @callbacks = {}
        Slack::RealTime::Config::ATTRIBUTES.each do |key|
          send("#{key}=", options[key] || Slack::RealTime.config.send(key))
        end
        @token ||= Slack.config.token
        @web_client = Slack::Web::Client.new(token: token)
      end

      [:url, :team, :self, :users, :channels, :groups, :ims, :bots].each do |attr|
        define_method attr do
          @options[attr.to_s] if @options
        end
      end

      def on(type, &block)
        type = type.to_s
        @callbacks[type] ||= []
        @callbacks[type] << block
      end

      def init_driver
        fail ClientAlreadyStartedError if started?

        @options = web_client.rtm_start
        @socket = Slack::RealTime::Socket.new(@options['url'])


        @driver = WebSocket::Driver.client @socket
        @driver.on :open do |event|
          open(event)
        end

        @driver.on :error do |event|
          error(event)
        end

        @driver.on :close do |event|
          close(event)
        end

        @driver.on :message do |event|
          dispatch(event)
        end
        @driver.start
      end

      def start!
        init_driver
        loop do
          return if @closed
          data = @socket.socket.readpartial 4096
          next if data.nil? or data.empty?
          @driver.parse data
        end
      end

      def stop!
        fail ClientNotStartedError unless started?
        @closed = true
      end

      def started?
        @started || false
      end

      class << self
        def configure
          block_given? ? yield(Config) : Config
        end

        def config
          Config
        end
      end

      protected

      def send_json(data)
        fail ClientNotStartedError unless started?
        @driver.text(data.to_json)
      end
      
      def error(_event)
      end

      def open(_event)
        @started = true
      end

      def close(_event)
        @started = false
        @closed = true
      end

      def dispatch(event)
        return false unless event.data
        data = JSON.parse(event.data)
        type = data['type']
        return false unless type
        callbacks = @callbacks[type.to_s]
        return false unless callbacks
        callbacks.each do |c|
          c.call(data)
        end
        true
      end
    end
  end
end
