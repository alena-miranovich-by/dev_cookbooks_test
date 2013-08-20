#!/usr/bin/ruby
levels = ["info","debug", "warn", "fatal", "error"]

#verification of setting cookbook log level
#cookbook_fail=0
#agent_fail=0
levels.each do |val|
        system "rs_log_level -l #{val}"
        system "rs_log_level | grep -i #{val}"
        if $? == 0
                puts "===PASS=== cookbook log level set successully"
        else
                puts "===FAIL=== cookbook log hasn't been set"
#                cookbook_fails += 1
		exit 101
        end
        system "rs_log_level --agent -l #{val}"
        system "rs_log_level --agent | grep -i #{val}"
        if $? == 0
                puts "===PASS=== agent log level set successfully"
        else
                puts "===FAIL=== agent log level hasn't been set"
#                agent_fail += 1
		exit 102
        end
end
#if cookbook_fail > 1 && agent_fail > 1
#        puts "===PASS=== log_levels works correctly"
#else
#        puts "===FAIL=== log_levels not working correctly"
#        puts "cookbook fails - #{cookbook_fail}"
#        puts "agent fails - #{agent_fail}"
#        exit 100
#end

