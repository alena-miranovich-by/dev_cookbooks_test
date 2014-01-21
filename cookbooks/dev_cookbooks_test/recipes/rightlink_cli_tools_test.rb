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
# NOTE: ONLY FOR LUNUX!
# Requires rightlink_test::rightlink_cli_test_recipe recipe to be added

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

UUID = node[:rightscale][:instance_uuid]
TEST_RECIPE = "dev_cookbooks_test::rightlink_cli_test_recipe"

ruby_block "Test help and version options of RightLink CLI tools" do
  block do
    @rl_tools = [ "rs_connect", "rs_log_level", "rs_reenroll", "rs_run_recipe", "rs_run_right_script",
             "rs_shutdown", "rs_tag", "rs_thunk", "rs_state" ]
    rl_version = get_rightlink_version
    Chef::Log.info("RightLink version is #{rl_version}")
    @rl_tools.push("rs_config") if rl_version.match('^6.*$')

    @rl_tools.each do |tool|
      result = is_cmd_works?([tool, "--version"].join(' '))
      fail("=== FAILED: #{tool} --help works incorrectly === See output: \n #{result}") unless result.include?(tool)
      result = is_cmd_works?([tool,"--version"].join(' '))
      fail("=== FAILED: #{tool} --version prints incorrect RightLink version. === See output: \n #{result}") unless result.include?(rl_version.rstrip)
    end
    Chef::Log.info("=== PASSED === --help and --version options are verified for RightLink tools #{@rl_tools.inspect}")
  end
  not_if { platform?('windows') }
end

template_path = ::File.join(::Dir.tmpdir, "parameters.json")
template "/tmp/parameters.json" do
  path template_path
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
    result = is_cmd_works?("rs_run_recipe -n '#{TEST_RECIPE}' -j /tmp/parameters.json -v")
    fail("=== FAILED === it's impossible to run recipe with --json option") unless result.include?("Request processed successfully")
#    result.include?("Request processed successfully") ? Chef::Log.info(" === PASSED === request has been sent to run recipe. Please check audit entries to verify that test-recipe has been run.") : fail("=== FAILED === it's impossible to run recipe with --json option")

    #--audit_period PERIOD_IN_SECONDS
#    result = is_cmd_works?("rs_run_right_script -n '#{TEST_RECIPE}' -a '10'")
#    fail("=== FAILED === --audit_period option doesn't work correctly.") if result.include?("Failed")

#    result = `rs_run_recipe -n '#{TEST_RECIPE}' -a 10`
#    fail("=== FAILED === --audit_period option doesn't work correctly.") if result.include?("Failed")

    # --recipient_tags TAG_LIST
    result = is_cmd_works?("rs_run_recipe -n '#{TEST_RECIPE}' -r 'tag1 tag2' -v")
    fail("=== FAILED === --recipeint_tags have not been parsed correctly") unless result.include?(':tags=>["tag1", "tag2"]')
#    result.include?(':tags=>["tag1", "tag2"]') ? Chef::Log.info("=== PASSED === --recipient_tags have been parsed correctly") : fail("=== FAILED === --recipeint_tags have not been parsed correctly")
  end
end

ruby_block "Test rs_tag tool" do
  block do
    # ===== rs_tag =====
    # rs_tag -a and rs_tag -q already validated by other scripts (BTW, will it a good idea to gather them togerher?
    # rs_tag -l -e -f
    result = is_cmd_works?("rs_tag -l -e -f json")
    original = get_server_tags
    fail("=== FAILED === rs_tag -l doesn't work correctly. See output: \n #{result}") unless original = result 
#    if (original = result) 
#      Chef::Log.info("=== PASSED === rs_tag -l works correctly")
#    else 
#      Chef::Log.info("=== FAILED === rs_tag -l doesn't work correctly. See output: \n #{result}")
#      fail("rs_tag -l not verified")
#    end
    # rs_tag -r 
    tag = "rightlink_cli:test=tag_to_remove"
    `rs_tag -a #{tag}`
    sleep(3)
    if (tag_exists?(tag, UUID)) 
      result = is_cmd_works?("rs_tag -r #{tag}")
      tag_exists?(tag, UUID) ? fail("Tag has not been removed") : Chef::Log.info("Tag has been removed successfully.")
    else 
      fail("=== FAILED === rs_tag -a didn't add a tag")
    end
    # rs_tag -t 
    result = is_cmd_works?("rs_tag -l -t 0")
    fail("=== FAILED === rs_tag -t option doesn't work as expected") unless result.include?("Timed out waiting for agent reply")
#    result.include?("Timed out waiting for agent reply") ? Chef::Log.info("=== PASSED === rs_tag -t option works correctly") : fail("=== FAILED === rs_tag -t option doesn't work as expected")
  end
  not_if { platform?('windows') }
end


