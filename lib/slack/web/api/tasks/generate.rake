# largely from https://github.com/aki017/slack-ruby-gem
require 'json-schema'
require 'erubis'

namespace :slack do
  namespace :web do
    namespace :api do
      # update slack-api-docs from https://github.com/slackhq/slack-api-docs
      task :git_update do
        sh 'git submodule update --init --recursive'
        sh 'git submodule foreach git pull origin master'
      end

      task :update_endpoints do
        # methods
        puts 'Generating web API methods ...'
        FileUtils.rm_rf 'lib/slack/web/api/endpoints'
        FileUtils.mkdir_p 'lib/slack/web/api/endpoints'
        method_schema = JSON.parse(File.read('lib/slack/web/api/schema/method.json'))
        data = Dir.glob('lib/slack/web/api/slack-api-docs/methods/*.json').each_with_object({}) do |path, result|
          name = File.basename(path, '.json')
          prefix, name = name.split('.')
          result[prefix] ||= {}
          parsed = JSON.parse(File.read(path))
          JSON::Validator.validate(method_schema, parsed, insert_defaults: true)
          result[prefix][name] = parsed
        end

        method_template = Erubis::Eruby.new(File.read('lib/slack/web/api/templates/method.erb'))
        data.each_with_index do |(group, names), index|
          printf "%2d/%2d %10s %s\n", index, data.size, group, names.keys
          File.write "lib/slack/web/api/endpoints/#{group}.rb", method_template.result(group: group, names: names)
        end

        endpoints_template = Erubis::Eruby.new(File.read('lib/slack/web/api/templates/endpoints.erb'))
        File.write 'lib/slack/web/api/endpoints.rb', endpoints_template.result(files: data.keys)
      end

      task :update_types do
        # types, this needs https://github.com/slackhq/slack-api-docs/pull/39 to be merged to work
        puts 'Generating types ...'
        FileUtils.rm_rf 'lib/slack/web/api/types'
        FileUtils.mkdir_p 'lib/slack/web/api/types'
        data = Dir.glob('lib/slack/web/api/slack-api-docs/types/*.md').each_with_object({}) do |path, result|
          name = File.basename(path, '.md')
          md = File.read(path)
          json = md.match(/(?<json>\{.*\})/m)['json']
                 .gsub(/[\r\n\t]*/m, '')
                 .gsub('…', '')
                 .gsub('...', '')
                 .gsub(/\,[\s]*\]/, ']')
                 .gsub(/\,[\s]*\}/, '}')
          result[name] = JSON.parse(json)
        end

        type_template = Erubis::Eruby.new(File.read('lib/slack/web/api/templates/type.erb'))
        data.each_pair do |name, json|
          puts " #{name}"
          File.write "lib/slack/web/api/types/#{name}.rb", type_template.result(name: name, json: json)
        end

        types_template = Erubis::Eruby.new(File.read('lib/slack/web/api/templates/types.erb'))
        File.write 'lib/slack/web/api/types.rb', types_template.result(files: data.keys)
      end

      desc 'Update API.'
      task update: [:git_update, :update_endpoints, :update_types] do
        puts 'Done.'
      end
    end
  end
end
