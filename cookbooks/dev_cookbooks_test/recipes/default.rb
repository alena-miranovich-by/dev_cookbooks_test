#
# Cookbook Name:: rightlink_test
# Recipe:: rs_tag_query_check
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#

# Check that chef is not using sandboxed ruby -- this is fixed by our custom ruby provider
ruby_block "check rs_tag --query functionality" do
  block do
    tag1 = "user:name=tester"
    tag2 = "test-tag with spaces"
    tag3 = "test-tag_without_ispaces"
    tag4 = "hello:world=hello everyone"
    unless node[:platform] == 'windows'
      # Linux
      rightlink_version = `cat /etc/rightscale.d/rightscale-release`
    else 
      # Windows
      rightlink_version = "" 
    end

    if (rightlink_version.include? '6.0')

      expected_output = ':tags=>["user:name=tester", "test-tag with spaces", "test-tag_without_spaces", "hello:world=hello everyone"]'

      result =`rs_tag --query #{tag1} '#{tag2}' #{tag3} '#{tag4}' -v`
      puts result

      if (result.include? expected_output)

        Chef::Log.info("RightLink6.0 rs_tag works as expected. See output: \n #{result}")

      else

        Chef::Log.info("RightLink6.0 rs_tag doesn't work correctly. See output: \n #{result}")
        fail("Actual rs_tag --query output doesn't match to expected")

      end

    elsif (rightlink_version.include? '5.9') 

      # rightlink is not 6.0
      expected_output = ':tags=>["user:name=tester", "test-tag", "with", "spaces", "test-tag_without_spaces", "hello:world=hello", "everyone"]'

      result =`rs_tag --query '#{tag1} #{tag2} #{tag3} #{tag4}' -v`
      puts result

      if (result.include? expected_output)

        Chef::Log.info("RightLink5.9 rs_tag works as expected. See output: \n #{result}")

      else

        Chef::Log.info("RightLink5.9 rs_tag doesn't work correctly. See output: \n #{result}")
        fail("Actual rs_tag --query output doesn't match to expected.")

      end

    end

  end
end

