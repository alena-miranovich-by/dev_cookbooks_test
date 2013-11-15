#
# Cookbook Name:: rightlink_test
# Recipe:: 
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
    tag3 = "test-tag_without_spaces"
    unless node[:platform] == 'windows'
    #linux
    rightlink_version = `cat /etc/rightscale.d/rightscale-release`
    if (rightlink_version.include? '5.9')
      expected_output = ':tags=>["user:name=tester", "test-tag", "with", "spaces", "test-tag_without_spaces"'
      result =`rs_tag --query '#{tag1} #{tag2} #{tag3}' -v`
      puts result

      if (result.include? expected_output)
        chef::Log.info("5.9 cool")
      else
        Chef::Log.info("5.9 not cool")
      end
    elsif (rightlink_version.include? '6.0')
      expected_output = ':tags=>["user:name=tester", "test-tag with spaces", "test-tag_without_spaces"'
      result =`rs_tag --query #{tag1} '#{tag2}' #{tag3} -v`
      puts result

      if (result.include? expected_output)
        Chef::Log.info("6.0 cool")
      else
        Chef::Log.info("6.0 not cool")
      end
    end
    else
   #windows
      expected_output = ':tags=>["user:name=tester", "test-tag", "with", "spaces", "test-tag_without_spaces"'
      result =`rs_tag --query '#{tag1} #{tag2} #{tag3}' -v`
      puts result

      if (result.include? expected_output)
        Chef::Log.info("windows 5.9 cool")
      else
        Chef::Log.info("windows 5.9 not cool")
      end

    end
  end
end

