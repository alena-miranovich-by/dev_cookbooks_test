#
# Cookbook Name:: rightlink_test
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.


module RightlinkTester
  module Utils 
    # Creates new Utils object.

    # Gets RightLink version 
    #
    # @return [String] version of installed RightLink on the instance
    #
    def get_rightlink_version
      rightlink_version = ""
      unless node[:platform] == 'windows'
        # get RightLink version under Linux platform
        rightlink_version = `cat /etc/rightscale.d/rightscale-release`
      else
        Chef::Log.info("Platform is Windows - don't know which version.")
      end
      rightlink_version
    end  

    # Gets server tags collection
    # @param [String] uuid - UUID of this server
    # @return [Array] - tags collection
    #
    def get_server_tags (uuid) 
      tags_hash = node[:server_collection][uuid]
      tags_hash[tags_hash.keys[0]]
    end

    # Checks if tag exists or not
    # @param [String] tag
    # @param [String] uuid - UUID of the server
    # @return [bool] true if tag exists, false if tag doesn't exist
    #
    def tag_exists?(tag, uuid)
      tags = get_server_tags(uuid)
      result = tags.select { |s| s == tag }
      result.empty? ? false : true
    end


    # Checks if provided command work or not at all and returns output
    # @param [String] command
    # @return [String] output of the result of executing this command
    #
    def is_cmd_works? (command)
      output = `#{command}`
      if ($?.success?)
        Chef::Log.info("=== #{command} works ===")
      else
        Chef::Log.info("=== FAILED === #{command} doesn't work.\n #{output}")
        fail("#{command} doesn't work")
      end
      output
    end



  end
end

