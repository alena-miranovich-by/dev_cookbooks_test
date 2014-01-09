#
# Cookbook Name:: rightlink_test
# Recipe:: rs_config_tool
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Verifies rs_config CLI tool: decommission timeout feature. 
# Verifies possibility to set user defined decommission timeout and 
# checks that necessary message exists in system logs (Linux only)
# Reboot will be performed during the test-case.
#

UUID = node[:rightscale][:instance_uuid]
UUID_TAG = "rs_instance:uuid=#{UUID}"

log "Add instance UUID as a tag: #{UUID_TAG}"
right_link_tag UUID_TAG

log "Verify UUID tag exists"
wait_for_tag UUID_TAG do
  collection_name UUID
end

log "Query servers for the instance tags..."
server_collection UUID do
  tags UUID_TAG
end

log "============ rs_config_tool test started =============="

# Check query results to check if rs_config tag was set and verify decommission message
ruby_block "Verify decommission_timeout feature" do
 block do
  #Check if tag exists
  tag = "rs_config_test:decom_timeout=true"
  Chef::Log.info("Checking server collection for the #{tag} tag...")
  h = node[:server_collection][UUID]
  tags = h[h.keys[0]]
  Chef::Log.info("Tags: #{tags.inspect}")
  result = tags.select { |s| s == tag }

  if result.empty? 
    decom_timeout = 1   
    `rs_config --set decommission_timeout #{decom_timeout}`
    if $?.success?
      timeout = `rs_config --get decommission_timeout`
      if timeout.rstrip.eql?(decom_timeout.to_s)
        Chef::Log.info("Decommission_timeout was set to #{decom_timeout} seconds.")
        # set tag to perform verification after reboot
        `rs_tag -a "#{tag}"`
        # perform reboot 
        `rs_shutdown -r -i`
      else
        fail("Decommission timeout was not set correctly and it set to #{timeout} instead of #{decom_timeout}.")
      end
    else
      fail("Decommission_timeout was not set. Something went wrong.")
    end
  else 
    # there is no system logs under Windows like it is on Linux OS.
    unless platform?('windows')
      Chef::Log.info("Tag #{tag} exists. Checking for the message in system logs..")
      File.exists?("/var/log/syslog") ? system_log = "/var/log/syslog" : system_log = "/var/log/messages"
      `cat #{system_log} | grep 'Failed to decommission in less than 0 minutes, forcing shutdown'`
      if ($?.success?)
        Chef::Log.info("==== PASS ==== Decommission_timeout feature verified.")
      else
        fail("==== FAIL ==== System log doesn't contain decommission message.")
      end
    else
        Chef::Log.info("Tag #{tag} exists. Nothing to do.")
    end
  end
 end
end

log "============ rs_config_tool test finished ============"
