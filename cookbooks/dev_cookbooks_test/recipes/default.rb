#
# Cookbook Name:: rightlink_test
# Recipe:: rs_tag_query_check
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#

# Check that  rs_tag --query works as expected:
# (1) for RightLink 5.9 (and <) - tag_list parameter should be quoted if it contains spaces, 
# no possibility to use tag with spaces in value;
# (2) for RightLink 6.0 - instead of the previous tag_list user should provide array if tags, 
# if any tag contains spaces it should be quoted.
#

ruby_block "check rs_tag --query functionality" do
  block do
    tag1 = "user:name=tester"
    tag2 = "test-tag with spaces"
    tag3 = "test-tag_without_spaces"
    tag4 = "hello:world=hello everyone"
    unless node[:platform] == 'windows'
      # Linux
      rightlink_version = `cat /etc/rightscale.d/rightscale-release`
    else 
      # Windows
			vers = `rs_tag --version`
      Chef::Log.info("#{vers}")
      if (vers.include? '6.')
        rightlink_version = '6.'
      else
        rightlink_version = '5.'
      end 
      Chef::Log.info("#{rightlink_version}")
    end

    if (rightlink_version.include? '6.')

      expected_output = ':tags=>["user:name=tester", "test-tag with spaces", "test-tag_without_spaces", "hello:world=hello everyone"]'

      result =`rs_tag --query #{tag1} "#{tag2}" #{tag3} "#{tag4}" -v`
      puts result

      if (result.include? expected_output)

        Chef::Log.info("RightLink6 rs_tag works as expected. See output: \n #{result}")

      else

        Chef::Log.info("RightLink6 rs_tag doesn't work correctly. See output: \n #{result}")
        fail("Actual rs_tag --query output doesn't match to expected")

      end

    else

      # rightlink is not 6.0
      expected_output = ':tags=>["user:name=tester", "test-tag", "with", "spaces", "test-tag_without_spaces", "hello:world=hello", "everyone"]'

      result =`rs_tag --query "#{tag1} #{tag2} #{tag3} #{tag4}" -v`
      puts result

      if (result.include? expected_output)

        Chef::Log.info("RightLink5 rs_tag works as expected. See output: \n #{result}")

      else

        Chef::Log.info("RightLink5 rs_tag doesn't work correctly. See output: \n #{result}")
        fail("Actual rs_tag --query output doesn't match to expected.")

      end

    end

  end
end

