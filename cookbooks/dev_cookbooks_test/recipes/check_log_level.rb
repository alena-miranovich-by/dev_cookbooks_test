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

data_to_verify=["test_message_with_info_cookbook_and_info_log_level",
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


#check cookbook log level and logging process
levels.each do |val|
	system "rs_log_level -l #{val}"
	system "rs_log_level | grep -i #{val}"
	if $? == 0
                puts "===PASS=== cookbook log level set successully"
		system "echo '===PASS=== cookbook'"
        else
                puts "===FAIL=== cookbook log hasn't been set"
		system "echo '==fail==cookbook'"
                cookbook_fails += 1
	        exit 101
        end
	#check logging process:

	levels.each do |lvl|
		puts "#{lvl}"
		log "test-message to verify logging with #{val} cookbook level and #{lvl} log level" do
			level lvl.to_sym
		end
	end
	for path in '/var/log/messages' #'/var/log/syslog' 
		for msg in data_to_verify
			puts "#{msg}"
			system "cat #{path} | grep #{msg}"
			if $? == 0
				system "echo '==PASS=  exists'"
			else 
				system "echo '==FAIL== doesn't exist'"
			end
		end	
	end
end

#check agent log level 
#levels.each do |val|
#        system "rs_log_level --agent -l #{val}"
#        system "rs_log_level --agent | grep -i #{val}"
#        if $? == 0
#                puts "===PASS=== agent log level set successfully"
#        else
#                puts "===FAIL=== agent log level hasn't been set"
#                agent_fail += 1
#		exit 102
#        end
#end
#if cookbook_fail > 1 && agent_fail > 1
#        puts "===PASS=== log_levels works correctly"
#else
#        puts "===FAIL=== log_levels not working correctly"
#        puts "cookbook fails - #{cookbook_fail}"
#        puts "agent fails - #{agent_fail}"
#        exit 100
#end

