# This file was auto-generated by lib/slack/web/api/tasks/generate.rake

module Slack
  module Web
    module Api
      module Types
        class Group
          attr_accessor :id
          attr_accessor :name
          attr_accessor :is_group
          attr_accessor :created
          attr_accessor :creator
          attr_accessor :is_archived
          attr_accessor :members
          attr_accessor :topic
          attr_accessor :purpose

          def initialize(attrs = {})
            attrs.each_pair do |k, v|
              send("#{k}=", v)
            end if attrs
          end
        end
      end
    end
  end
end