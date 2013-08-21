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
msg = ["test_message_with_info_cookbook_and_info_log_level",
                "test_message_with_info_cookbook_and_warn_log_level",
                "test_message_with_info_cookbook_and_error_log_level",
                "test_message_with_info_cookbook_and_fatal_log_level",
                "test_message_with_debug_cookbook_and_info_log_level",
                "test_message_with_debug_cookbook_and_debug_log_level",
                "test_message_with_debug_cookbook_and_warn_log-level",
                "test_message_with_debug_cookbook_and_error_log_level",
                "test_message_with_debug_cookbook_and_fatal_log_level",
                "test_message_with_warn_cookbook_and_fatal_log_level",
                "test_message_with_warn_cookbook_and_error_log_level",
                "test_message_with_warn_cookbook_and_warn_log_level",
                "test_message_with_fatal_cookbook_and_fatal_log_level",
                "test_message_with_error_cookbook_and_fatal_log_level",
                "test_message_with_error_cookbook_and_error_log_level"]

levels.each do |lvl|

	array.each do |val|
		log "test_message_with_#{lvl}_cookbool_level_and_#{val}_log_level" do
			level val.to_sym
		end
	end
end
