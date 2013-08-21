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

levels.each do |val|
	log "test_msg with cookbook level #{val}" do
		level val.to_sym
	end
end
