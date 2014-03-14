#
# Cookbook Name:: rightlink_test
# Recipe:: soft_reboot_test
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Verifies soft reboot was performed 
# Note: Soft_reboot is performed only if rs_shutdown --reboot is executed (not OS reboot).
#
# This test requires the rs_agent_dev:reboot=rightlink_test_soft_reboot tag to be set on the server
# and a reboot performed. 
# It designed to work in conjunction with the 'RightLinkTester_RS_REBOOT_Check_Linux' RightScript, 
# please see the 'RightLink Package Tester for Linux' ServeTemplate for an example. 
# To run the test without the above RightScript:
# 1. Place this recipe in the boot scripts of your ServerTemplate. 
# 2. Tag your server with the 'rs_agent_dev:reboot=rightlink_test_soft_reboot' tag
# 3. Reboot the instance using the rs_shutdown command-line utility, i.e. 
# rs_shutdown --reboot --immediately
#
# If soft-reboot does not add the appropriate message to the log, this script will strand the server. 
#

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

TAG = "rs_agent_dev:reboot=rightlink_test_soft_reboot"

log "============ soft_reboot_test started =============="

# Check query results to see if we have TAG set and look for local facility message at system log
ruby_block "Query to look for local facility message only if soft_reboot tag was set" do
  block do
    
#    File.exists?("/var/log/syslog") ? system_log = "/var/log/syslog" : system_log = "/var/log/messages"
    Chef::Log.info("Checking server collection for the #{TAG} tag...")
    unless tag_exists?(TAG).empty? 
      Chef::Log.info("Soft_reboot tag found")
      if check_for_the_message("Initiate reboot using local (OS) facility")
      
			#output = `cat #{system_log} | grep 'Initiate reboot using local (OS) facility'`
			#if ($?.success?)
				Chef::Log.info("==== PASS ==== Soft_reboot verified")
			else
				raise("==== FAIL ==== System log doesn't contain necessary soft_reboot message")
			end
      remove_tag(TAG)
    else
      Chef::Log.info("No soft_reboot tag found - nothing to do")
    end
    
  end
end

log "============ soft_reboot_test finished ============"

