#!/usr/bin/env ruby

require 'rubygems'
require 'net/ssh'
require 'fog'

require './config.rb'
# Net::SSH.start('puppet.hp8.us', 'surma') do |ssh|
# 	output = ssh.exec!("hostname")
# 	puts output
# 	stdout = ""
# 	ssh.exec!("ls -la /home/surma") do |channel, stream, data|
# 		stdout << data if stream == :stdout
# 	end

# end

# The key data is pulled from the config.rb file in the local directory.  
# That is then passed to Fog to create a new connection to AWS.  
connection = Fog::Compute.new(
    :provider => @aws_provider,
    :region => @aws_region,
    :aws_access_key_id => @aws_access_key_id,
    :aws_secret_access_key => @aws_secret_access_key
    )

my_instance_ids = Hash.new
connection.servers.each do |server|
	my_instance_ids[server.id] = {pub_ipaddr: server.public_ip_address, 
								  state: server.state,
	                              pub_server_name: server.dns_name, 
	                              priv_ipaddr: server.private_ip_address,
	                              tags: server.tags
	                              }
end

puts my_instance_ids

connection.servers.all.table([:id, :state, :dns_name, :public_ip_address, :private_ip_address, :tags])
# my_servers