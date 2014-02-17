#
# Cookbook Name:: monitor
# Recipe:: _twiliosms_handler
#
# Adds a Twilio SMS handler.
#

sensu_gem 'twilio-ruby'
sensu_gem 'rest-client'

# Fetch the `mailer` handler script from the sensu/sensu-community-plugins repo.
url = 'https://raw.github.com/sensu/sensu-community-plugins/master/handlers/notification/twiliosms.rb'
remote_file '/etc/sensu/handlers/twiliosms.rb' do
  source url
  mode 0755
  only_if "curl -s -o /dev/null -w \"%{http_code}\" #{url} | grep 200"
end

# Fetch the sid, token and number from the `sensu/twiliosms` encrypted data bag.
search(:sensu, 'id:twiliosms') do |s|
  log 'Loaded sensu:twiliosms'
  bag = Chef::EncryptedDataBagItem.load('sensu', 'twiliosms')
  log bag.inspect

  sensu_snippet 'twiliosms' do
    content sid:    bag['sid'],
            token:  bag['token'],
            number: bag['number'],
            recipients: {
              '+447791503309' => {
                sensu_roles: ['all'],
                sensu_checks: [],
                sensu_level: 1
              }
            }
  end
end

# Create the `twiliosms` handler.
sensu_handler "twiliosms" do
  type "pipe"
  command "/etc/sensu/handlers/twiliosms.rb"
  severities %w( critical )
end
