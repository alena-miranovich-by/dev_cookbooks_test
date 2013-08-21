#
# Cookbook Name:: dev_cookbooks_test
# Recipe:: check_cookbook_and_agent_log_levels
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#verification of setting cookbook log level
#cookbook_fail=0
#agent_fail=0
levels = ["info", "debug", "warn", "error", "fatal"]
array = ["debug", "info","warn", "error", "fatal"]

levels.each do |lvl|

	array.each do |val|
		log "test_message_with_#{lvl}_cookbook_level_and_#{val}_log_level" do
			level val.to_sym
		end
	end
end
