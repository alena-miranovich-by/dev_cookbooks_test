#
# Cookbook Name:: rightlink_test
# Recipe:: rs_config_tool
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Verifies user defined decommission timeout functionality.
# Reboot will be performed during the test-case.
#

TAG = "rs_config:decom_timeout=true"
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
  Chef::Log.info("Checking server collection for the #{TAG} tag...")
  h = node[:server_collection][UUID]
  tags = h[h.keys[0]]
  Chef::Log.info("Tags: #{tags.inspect}")
  result = tags.select { |s| s == TAG }

  block do
    decom_timeout = 1

    `rs_config --set decommission_timeout #{decom_timeout}`
    if $?.success?
      Chef::Log.info("Decommission_timeout was set to #{decom_timeout} seconds.")
      # set tag to perform verification after reboot
      `rs_tag -a "#{TAG}"`
      # perform reboot 
      `rs_shutdown -r -i`
    else
      fail("Decommission_timeout was not set. Something went wrong")
    end


  end
  not_if do result.empty? end
end

