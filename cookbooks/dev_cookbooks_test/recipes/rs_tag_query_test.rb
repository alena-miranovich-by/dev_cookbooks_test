#
# Cookbook Name:: rightlink_test
# Recipe:: rs_tag_query_test
#
# Copyright RightScale, Inc. All rights reserved. All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#

# Check that rs_tag --query works as expected:
# (1) for RightLink 5.9 (and <) - TAG_LIST parameter should be quoted if it contains spaces,
# no possibility to use tag with spaces in value;
# (2) for RightLink 6.0 - instead of the previous TAG_LIST user should provide array of tags,
# if tag contains spaces it should be quoted.
#

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

ruby_block "Verify rs_tag --query functionality" do
  block do
    tag1 = "user:name=tester"
    tag2 = "test-tag with spaces"
    tag3 = "test-tag_without_spaces"
    tag4 = "hello:world=hello everyone"
    
    rightlink_version = get_rightlink_version

#    unless node[:platform] == 'windows'
      # get RightLink version under Linux platform
 #     rightlink_version = get_rightlink_version
  #  else
      # get RightLink version under Windows platform
   #   version = `rs_tag --version`
    #  if (version.include? '6.')
     #   rightlink_version = '6.'
      #else
       # rightlink_version = '5.'
      #end
    #end

    Chef::Log.info("RightLink version is #{rightlink_version}")

    if rightlink_version.match('^6.*$')

      # in RightLink6 every tag should be quoted if it contains spaces, if it doesn't contain - no necessary to quote. 
      expected_output = ':tags=>["user:name=tester", "test-tag with spaces", "test-tag_without_spaces", "hello:world=hello everyone"]'
      # query option is TAG[s] (array), not TAGS_LIST
      result =`rs_tag --query #{tag1} "#{tag2}" #{tag3} "#{tag4}" -v`

      if (result.include? expected_output)

        Chef::Log.info("RightLink6 rs_tag works as expected. See output: \n #{result}")

      else

        Chef::Log.info("RightLink6 rs_tag doesn't work correctly. See output: \n #{result}")
        fail("Actual rs_tag --query output doesn't match to expected.")

      end

    else

      # in RightLink5 we can provide only TAGS_LIST; 
      # tag shouldn't have spaces, otherwise it will be interpretted incorrectly 
      expected_output = ':tags=>["user:name=tester", "test-tag", "with", "spaces", "test-tag_without_spaces", "hello:world=hello", "everyone"]'
      # query option is TAGS_LIST; every tag is delimited by spaces, query is quoted
      result =`rs_tag --query "#{tag1} #{tag2} #{tag3} #{tag4}" -v`

      if (result.include? expected_output)

        Chef::Log.info("RightLink5 rs_tag works as expected. See output: \n #{result}")

      else

        Chef::Log.info("RightLink5 rs_tag doesn't work correctly. See output: \n #{result}")
        fail("Actual rs_tag --query output doesn't match to expected.")

      end

    end

  end
end

