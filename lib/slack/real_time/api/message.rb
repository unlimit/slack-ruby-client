module Slack
  module RealTime
    module Api
      module Message
        #
        # Sends a message to a channel.
        #
        # @option options [channel] :channel
        #   Channel to send message to. Can be a public channel, private group or IM channel. Can be an encoded ID, or a name.
        # @option options [Object] :text
        #   Text of the message to send. See below for an explanation of formatting.
        def message(options = {})
          throw ArgumentError.new('Required arguments :channel missing') if options[:channel].nil?
          throw ArgumentError.new('Required arguments :text missing') if options[:text].nil?
          send_json({ type: 'message', id: next_id }.merge(options))
        end

        private

        def next_id
          @next_id ||= 0
          @next_id += 1
        end
      end
    end
  end
end