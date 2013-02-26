#!/usr/bin/env ruby

require 'rubygems'
require 'net/ssh'
require 'fog'
require 'yaml'

require './config.rb'
 # Net::SSH.start('puppet.hp8.us', 'surma') do |ssh|
 # 	output = ssh.exec!("hostname")
 # 	puts output
 # 	stdout = ""
 # 	ssh.exec!("ls -la /home/surma") do |channel, stream, data|
 # 		stdout << data if stream == :stdout
 # 	end

# end
credentials = YAML.load_file('./aws_ec2keys.yml')
puts credentials.inspect

# The key data is pulled from the config.rb file in the local directory.  
# That is then passed to Fog to create a new connection to AWS.  
connection = Fog::Compute.new(
    :provider => @aws_provider,
    :region => @aws_region,
    :aws_access_key_id => @aws_access_key_id,
    :aws_secret_access_key => @aws_secret_access_key
    )

my_instance_data = Hash.new
connection.servers.each do |server|
	my_instance_data[server.id] = {pub_ipaddr: server.public_ip_address, 
								  state: server.state,
	                              pub_server_name: server.dns_name, 
	                              priv_ipaddr: server.private_ip_address,
	                              tags: server.tags
	                              }
end

puts my_instance_data

connection.servers.all.table([:id, :state, :dns_name, :public_ip_address, :private_ip_address, :tags])
# my_servers

#pull a white list of servers
def server_white_list (white_list_fname)
	puts "#{white_list_fname}"
end

def state_data (server_list)
	puts "#{server_list}"
end

def shutdown_instance(my_inst_id)
	puts "My instance_id is #{my_inst_id}"

end
