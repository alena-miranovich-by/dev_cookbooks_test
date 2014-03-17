#
# Cookbook Name:: rightlink_test
# Recipe:: rs_config_tool
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Test will work only on Linux OS
# Verifies rs_config CLI tool: changing decommission_timeout value, disabling other features:
# managed_login_enable, motd_update, package_repositories_freeze. 
# Reboot will be performed two times during test-case: 
# first one to apply all changes and the second one to reset values to default.
# During executing test-case tags could be set:
# rs_config_test:ready_for_test=true - means that all features values changed and ready to be tested
# rs_config_test:ready_for_test-false - means that all features have been verified, test-case will not run again.

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

log "============ rs_config_tool test started =============="

TAG = "rs_config_test:ready_for_test=true"
TAG_DONE = "rs_config_test:ready_for_test=false"
DECOM_TIMEOUT_FEATURE = "decommission_timeout"
MANAGED_LOGIN_FEATURE = "managed_login_enable"
MOTD_UPD_FEATURE = "motd_update"
REPO_FREEZE_FEATURE = "package_repositories_freeze"
MOTD_SYSTEM_PATH = "/etc/motd"
MOTD_MSG_ORIGINAL = "/tester/motd_original"
#MOTD_MSG_TEST = "/tester/rs_config_motd"
MOTD_MSG_TEST = "rs_config_motd"
TIMESTAMP = "/tester/timestamp"
TEST_MESSAGE = "rs_config test message"

test_dir = if platform?('windows')
  "C:\\tester"
else 
  "/tester"
end

directory "#{test_dir}" do
  action :create
end

template_path = ::File.join(test_dir, MOTD_MSG_TEST)
template "#{template_path}" do
  source "rs_config_motd.erb"
  action :create
end

ruby_block "test" do
block do 
timestamp = Time.now.to_i
      `echo "#{timestamp}" > #{TIMESTAMP}`
      `logger "#{TEST_MESSAGE} #{timestamp}"`

end
end

ruby_block "Verifies rs_config tool" do
  block do
    # before changes:
    if (tag_exists?(TAG).empty? and tag_exists?(TAG_DONE).empty?)
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
      File.exists?("/etc/motd.tail") ? MOTD_SYSTEM_PATH = "/etc/motd.tail" : MOTD_SYSTEM_PATH = "/etc/motd"
      FileUtils.cp(MOTD_SYSTEM_PATH, MOTD_MSG_ORIGINAL)
      # Overwrite motd file to test motd
      FileUtils.cp(MOTD_MSG_TEST, MOTD_SYSTEM_PATH)

      # ============= 4. Repositories freeze ==================
      # Disable package_repositories_freeze feature
      `rs_config --set #{REPO_FREEZE_FEATURE} false`
      $?.success? ? Chef::Log.info("Repositories freeze feature was disabled.") : fail("Repo_freeze feature was not disabled. Something went wrong.")

      # Add tag to perform verification on next boot
      `rs_tag -a "#{TAG}"`
      # Get timestamp and put with test message to system logs
      timestamp = Time.now.to_i
      `echo "#{timestamp}" > #{TIMESTAMP}`
      `logger "#{TEST_MESSAGE} #{timestamp}"`
      # reboot the instance
      Chef::Log.info("Reboot the instance...")
      `rs_shutdown --reboot -i`
    # after reboot with applying changes
     elsif (!tag_exists?(TAG).empty? and tag_exists?(TAG_DONE).empty?)
       # reset values to default
      `rs_config --set #{MANAGED_LOGIN_FEATURE} on`
      `rs_config --set #{MOTD_UPD_FEATURE} on`
      `rs_config --set #{REPO_FREEZE_FEATURE} on`
      `rs_config --set #{DECOM_TIMEOUT_FEATURE} 180`
      Chef::Log.info("All features have been set to default values. To apply changes reboot is required.")
      # ========== Decommission timeout feature =================
      Chef::Log.info("Tag #{TAG} exists. Checking for the message in system logs..")
      # define existing system logs depends on distribution
      File.exists?("/var/log/syslog") ? system_log = "/var/log/syslog" : system_log = "/var/log/messages"
      `cat #{system_log} | grep 'Failed to decommission in less than 0 minutes, forcing shutdown'`
      $?.success? ? Chef::Log.info("==== PASSED ==== Decommission_timeout feature verified.") : fail("==== FAILED ==== System log doesn't contain decommission message.")

      # ===== Managed_login_enable, MOTD_update, package_repositories_freeze ====
      timestamp = File.open(TIMESTAMP) {|f| f.readline}
      fl = 0
      File.open(system_log, "r").each_line do |line|
        if fl != 1
          # find for certain string "test started"
          if line.include? "#{TEST_MESSAGE} #{timestamp.rstrip}"
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
      Chef::Log.info("=== PASSED === managed_login and repo_freeze features are verified.")

      # ======= MOTD_update ======
      # compare test MOTD message with current in /etc/motd. Files should identical
      File.exists?("/etc/motd.tail") ? MOTD_SYSTEM_PATH = "/etc/motd.tail" : MOTD_SYSTEM_PATH = "/etc/motd"
      FileUtils.compare_file(MOTD_MSG_TEST, MOTD_SYSTEM_PATH) ? Chef::Log.info("===PASSED=== Test and current system MOTD messages are identical.") : fail("=== FAILED === Test and current system MOTD messages are different.")

      Chef::Log.info("=== PASSED rs_config test === All features are verified")
      `rs_tag -a "#{TAG_DONE}"`
      # reboot the instance to reset parameters
      Chef::Log.info("Reboot the instance...")
      `rs_shutdown --reboot -i`
    end

  end    
  not_if { platform?('windows') || !get_rightlink_version.match('^6.*$') }
end

log "============ rs_config_tool test finished ============"

