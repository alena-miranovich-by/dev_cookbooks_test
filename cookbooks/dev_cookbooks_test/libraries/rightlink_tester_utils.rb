#
# Cookbook Name:: rightlink_test
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.


module RightlinkTester
  module Utils
    
    # Creates new Utils object. All helper methods should be here to avoid repeated code

    # Checks if provided tag exists in tags for the instance
    #
    # @param tag [String] is tag to be checked
    # @param uuid [String] is instance's UUID
    # 
    # @return [Hash] not empty if tag is found
    def tag_exists? (tag, uuid)
      Chef::Log.info("Checking server collection for the #{tag}..")
      tags_hash = node[:server_collection][uuid]
      tags = tags_hash[tags_hash.keys[0]]
      Chef::Log.info("Tags: #{tags.inspect}")
      result = tags.select { |s| s == tag }
    end

  end
end

