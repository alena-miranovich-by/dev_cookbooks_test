#
# Cookbook Name:: rightlink_test
# Recipe:: rs_config_tool
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Test will work only on Linux OS
# Verifies rs_config CLI tool: decommission timeout feature. 
# Verifies possibility to set user defined decommission timeout and 
# checks that necessary message exists in system logs (Linux only)
# Reboot will be performed during the test-case.
#

UUID = node[:rightscale][:instance_uuid]
UUID_TAG = "rs_instance:uuid=#{UUID}"
i
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

TAG = "rs_config_test:ready_for_test=true"
TAG_DONE = "rs_config_test:ready_for_test=false"
DECOM_TIMEOUT_FEATURE = "decommission_timeout"
MANAGED_LOGIN_FEATURE = "managed_login_enable"
MOTD_UPD_FEATURE = "motd_update"
REPO_FREEZE_FEATURE = "package_repositories_freeze"
MOTD_SYSTEM_PATH = "/etc/motd"
MOTD_MSG_ORIGINAL = "/tmp/motd_original"
MOTD_MSG_TEST = "/tmp/rs_config_motd"
TIMESTAMP = "tmp/timestamp"
TEST_MESSAGE = "rs_config test message"


# Checks if provided tag exists in tags for the instance
def tag_exists? (tag, uuid)
  Chef::Log.info("Checking server collection for the #{tag}..")
  tags_hash = node[:server_collection][uuid]
  tags = tags_hash[tags_hash.keys[0]]
  Chef::Log.info("Tags: #{tags.inspect}")
  result = tags.select { |s| s == tag }
end


require 'fileutils'
def copy_file (source, destination)
  FileUtils.cp source, destination
end

template "/tmp/rs_config_motd" do
  source "rs_config_motd.erb"
  mode 0440
  owner "root"
  group "root"
  action :create
end

ruby_block "Change features values" do
  block do
    unless platform?('windows')
      # =============== 1. Decommission timeout  =================
      # set decommission_timeout to very small value - 1 second
      decom_timeout = 1
      `rs_config --set #{DECOM_TIMEOUT_FEATURE} #{decom_timeout}`
      # check that decommission_timeout value has been set
      if $?.success?
        timeout = `rs_config --get #{DECOM_TIMEOUT_FEATURE}`
        timeout.rstrip.eql?(decom_timeout.to_s) ? Chef::Log.info("Decommission_timeout was set to #{decom_timeout} seconds.") : fail("Decommission timeout was not set correctly and it set to #{timeout} instead of #{decom_timeout}.")
      else
        fail("Decommission_timeout was not set. Something went wrong.")
      end

      # ============== 2. Managed_login_enable =================
      # disable managed_login feature
      `rs_config --set #{MANAGED_LOGIN_FEATURE} false`
      $?.success? ? Chef::Log.info("Managed_login_enable feature was disabled.") : fail("Managed_login_enable feature was not disabled. Something went wrong.")

      # ============== 3. MOTD_update feature =================
      # disable motd_update feature
      `rs_config --set #{MOTD_UPD_FEATURE} false`
      $?.success? ? Chef::Log.info("MOTD_update feature was disabled.") : fail("MOTD_update feature was not disabled. Something went wrong.")
      # save original MOTD file
      require 'fileutils'
      FileUtils.cp(MOTD_SYSTEM_PATH, MOTD_MSG_ORIGINAL)
      # Overwrite motd file to test motd
      FileUtils.cp(MOTD_MSG_TEST, MOTD_SYSTEM_PATH)

      # ============= 4. Repositories freeze ==================
      # Disable package_repositories_freeze feature
      `rs_config --set #{REPO_FREEZE_FEATURE} true`
      $?.success? ? Chef::Log.info("Repositories freeze feature was disabled.") : fail("Repo_freeze feature was not disabled. Something went wrong.")

      # Add tag to perform verification on next boot
      `rs_tag -a "#{TAG}"`
      # Get timestamp and put with test message to system logs
      require 'time'
      timestamp = Time.now.to_i
      `echo "#{timestamp}" > #{TIMESTAMP}`
      `logger "#{TEST_MESSAGE} #{timestamp}"`
      # reboot the instance
      `rs_shutdown --reboot -i`
    else 
      Chef::Log.info("Windows platform - will not run the test")
    end
    
  only_if do tag_exists?(TAG, UUID).empty? && tag_exists?(TAG_DONE, UUID).empty? end
  end
end


ruby_block "Verify features changes" do
  block do

    unless platform?('windows')
      # ========== Decommission timeout feature =================
      Chef::Log.info("Tag #{TAG} exists. Checking for the message in system logs..")
      # define existing system logs depends on distribution
      File.exists?("/var/log/syslog") ? system_log = "/var/log/syslog" : system_log = "/var/log/messages"
      `cat #{system_log} | grep 'Failed to decommission in less than 0 minutes, forcing shutdown'`
      $?.success? ? Chef::Log.info("==== PASS ==== Decommission_timeout feature verified.") : fail("==== FAIL ==== System log doesn't contain decommission message.")

      # ===== Managed_login_enable, MOTD_update, package_repositories_freeze ====
      require 'fileutils'
      timestamp = File.open(TIMESTAMP) {|f| f.readline}
      Chef::Log.info("#{timestamp.rstrip.inspect}")
      fl = 0
      File.open(system_log, "r").each_line do |line|
        if fl != 1
          # find for certain string "test started"
          if line.include? "#{TEST_MESSAGE} #{ts.rstrip}"
            fl = 1
          end
        else
          if line.include? "Managed login enabled"
            fail("=== FAILED === Managed login section exists in system log!")
          elsif line.include? "Configuring software repositories"
            fail("=== FAILED === Configuring software repositories section exists in system log!")
          end
        end
      end

      # ======= MOTD_update ======
      # compare original MOTD message with existing in /etc/motd - files must be different
      FileUtils.compare_file(MOTD_MSG_ORIGINAL, MOTD_SYSTEM_PATH) ? fail("=== FAIL === MOTD messages are identical") : Chef::Log.info("===PASSED=== MOTD messages are different as it was expected")
      
      Chef::Log.info("=== PASSED rs_config test === All features are verified")
    else
      Chef::Log.info("Windows platform - will not run this test")
    end
    `rs_tag -a "#{TAG_DONE}"`
     # reset values to default
     `rs_config --set #{MANAGED_LOGIN_FEATURE} on`
     `rs_config --set #{MOTD_UPD_FEATURE} on`
     `rs_config --set #{REPO_FREEZE_FEATURE} on`
     `rs_config --set #{DECOM_TIMEOUT_FEATURE} 180`
     # reboot the instance to reset parameters
     `rs_shutdown --reboot -i`

  only_if do tag_exists?(TAG_DONE, UUID).empty? end
  end
end


log "============ rs_config_tool test finished ============"
