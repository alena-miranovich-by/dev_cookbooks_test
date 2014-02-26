#
# Cookbook Name:: rightlink_test
# Recipe:: tag_break_point_test
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Verifies break points in recipes

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

TAG = "rs_agent_dev:break_point=rightlink_test::tag_break_point_test_should_never_run"
#UUID = node[:rightscale][:instance_uuid]
#UUID_TAG = "rs_instance:uuid=#{UUID}"

log "============ tag_break_point_test =============="
=begin
log "Add instance UUID as a tag: #{UUID_TAG}"
right_link_tag UUID_TAG

log "Verify tag exists"
wait_for_tag UUID_TAG do
  collection_name UUID
end

log "Query servers for our tags..."
server_collection UUID do
  tags UUID_TAG
end
=end
# Check query results to see if we have our TAG set.
ruby_block "Query for breakpoint" do
  block do
    Chef::Log.info("Checking server collection for tag...")
#    h = node[:server_collection][UUID]
 #   tags = h[h.keys[0]]
  #  Chef::Log.info("Tags:#{tags}")
   # result = tags.select { |s| s == TAG }
    if tag_exists?(TAG)
#   unless result.empty?
      Chef::Log.info(" Tag #{TAG} found.")
      node.set[:devmode_test][:has_breakpoint] = true
      node.set[:devmode_test][:initial_pass] = false if node[:devmode_test][:initial_pass]
      node.set[:devmode_test][:disable_breakpoint_test] = true unless node[:devmode_test][:initial_pass]
    else
      Chef::Log.info(" No tag #{TAG} found -- set and reboot!")
    end
  end
end

## Set breakpoint if not set.
unless node[:devmode_test][:has_breakpoint] 
  `rs_tag --add #{TAG}`
#add_tag(TAG)
end

#right_link_tag TAG do
#  not_if do node[:devmode_test][:has_breakpoint] end
#end

#TODO: add a reboot count check and fail if count > 3

# Reboot, if not set
# lame switch for windows vs linux because the Window shutdown.exe is not always accessible
Chef::Log.info("Rebooting")
case node[:platform]
  when "windows"
    powershell "Powershell reboot" do
      source 'rs_shutdown -r -i'
      not_if do node[:devmode_test][:has_breakpoint] end
    end
  else
    execute "Rebooting so breakpoint tag will take affect." do
      command "init 6"
      not_if do node[:devmode_test][:has_breakpoint] end
    end
end

ruby_block "Wait for reboot" do
  not_if do node[:devmode_test][:has_breakpoint] end
  block do
    # don't continue running recipes while rebooting the system (especially not in
    # Windows). there currently is no better solution for this than to sleep after
    # requesting reboot.
    Chef::Log.info("Going to sleep pending system reboot.")
    reboot_timeout = 10 * 60
    end_time = Time.now + reboot_timeout
    while Time.now < end_time
      sleep 0.1  # need a busy loop for EM instead of sleeping for entire timeout or else other threads are blocked
    end
    raise "Expected system reboot did not occur after #{reboot_timeout / 60} minutes."
  end
end
