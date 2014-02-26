#
# Cookbook Name:: rightlink_test
# Recipe:: rightlink_cli_tools_test
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.
#
# Test to verify that all RightLink command line tools works as expected for RightLink 5.9+
# Will check all tools except some of them which verified by other RightScripts and recipes.
# Requires rightlink_test::rightlink_cli_test_recipe recipe to be added

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

#UUID = node[:rightscale][:instance_uuid]
TEST_RECIPE = "dev_cookbooks_test::rightlink_cli_test_recipe"


ruby_block "Test help and version options of RightLink CLI tools" do
  block do
    @rl_tools = [ "rs_connect", "rs_log_level", "rs_reenroll", "rs_run_recipe", "rs_run_right_script",
             "rs_shutdown", "rs_tag", "rs_thunk", "rs_state" ]
    rl_version = get_rightlink_version
    Chef::Log.info("RightLink version is #{rl_version}")
    @rl_tools.push("rs_config") if rl_version.match('^6.*$')

    @rl_tools.each do |tool|
      result = is_cmd_works?([tool, "--help"].join(' '))
      fail("=== FAILED: #{tool} --help works incorrectly === See output: \n #{result}") unless result.include?(tool)
      result = is_cmd_works?([tool,"--version"].join(' '))
      fail("=== FAILED: #{tool} --version prints incorrect RightLink version. === See output: \n #{result}") unless result.include?(rl_version.rstrip)
    end
    Chef::Log.info("=== PASSED === --help and --version options are verified for RightLink tools #{@rl_tools.inspect}")
  end
end


test_dir = if platform?('windows') 
  "C:\\tester"
else 
  "/tester"
end

directory "#{test_dir}" do
  action :create
end

template "#{test_dir}/parameters.json" do
  source "parameters.erb"
  action :create
end

ruby_block "Test rs_run_right_script and rs_run_recipe tools" do
  block do 
    #  ==== rs_run_right_script/ recipe ====
    # --identity option will check with incorrect value
    result = `rs_run_right_script --identity 0 -v`
    fail("=== FAILED === Something went wrong. See output: \n #{result}") unless result.include?("Could not find RightScript 0")
    result = `rs_run_recipe -i 0 -v`
    fail("=== FAILED === Something went wrong. See output: \n #{result}") unless result.include?("Could not find recipe 0")

    # --json JSON_FILE
    result = is_cmd_works?("rs_run_recipe -n '#{TEST_RECIPE}' -j '#{test_dir}/parameters.json' -v")
    fail("=== FAILED === it's impossible to run recipe with --json option") unless result.include?("Request processed successfully")

    #--audit_period PERIOD_IN_SECONDS
#    result = is_cmd_works?("rs_run_right_script -n '#{TEST_RECIPE}' -a '10'")
#    fail("=== FAILED === --audit_period option doesn't work correctly.") if result.include?("Failed")

#    result = `rs_run_recipe -n '#{TEST_RECIPE}' -a 10`
#    fail("=== FAILED === --audit_period option doesn't work correctly.") if result.include?("Failed")

    # --recipient_tags TAG_LIST
    `rs_tag --add "test:ping=reciever"`
    result = is_cmd_works?("rs_run_recipe -n 'recipe1' --recipient_tags 'test:ping=reciever'")
    fail("=== FAILED === rs_run_recipe -n '#{TEST_RECIPE}' --recipient_tags 'test:ping=reciever' doesn't work") unless result.include?("Request processed successfully") 
    result = is_cmd_works?("rs_run_recipe -n '#{TEST_RECIPE}' -r 'tag1 tag2' -v")
    fail("=== FAILED === --recipient_tags have not been parsed correctly") unless result.include?(':tags=>["tag1", "tag2"]')
    Chef::Log.info("=== PASSED === rs_run_right_script / recipe will passed --identity, --recipient_tags and --json options.")
  end
end

ruby_block "Test rs_tag tool" do
  block do
    # ===== rs_tag =====
    # rs_tag -l -e -f
    result = is_cmd_works?("rs_tag -l -e -f json")
    fail("=== FAILED === rs_tag -l doesn't work correctly. See output: \n #{result}") unless $?.success? 
    # rs_tag -t 
    result = `rs_tag -l -t 0`
    fail("=== FAILED === rs_tag -t option doesn't work as expected") if $?.success?
    Chef::Log.info("=== PASSED === rs_tag --list options verified")
  end
end

