#
# Cookbook Name:: rightlink_test
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.


module RightlinkTester
  module Utils 

    TIMEOUT = 4 * 60
    # Creates new Utils object.

    # Gets RightLink version (for RL5.9+ only) 
    # @return [String] version of installed RightLink on the instance
    #
    def get_rightlink_version
      rightlink_version = Gem::Specification.find_by_name("right_link").version.to_s
    end  

    # Gets server tags collection
    # @return [Array] - tags collection
    #
    def get_server_tags 
      tags_list = `rs_tag --list`
      # remove unnecessary \n from the tags list 
      tags_list.gsub(/\n/, " ")
    end

    # Checks if provided command work or not at all and returns output
    # @param [String] command
    # @return [String] output of the result of executing this command
    # @return [bool] returns false if command was not executed successfuly (doesn't work)
    #
    def is_cmd_works? (command)
      output = `#{command}`
      fail("#{command} doesn't work. see output: #{output}.") unless $?.success?
      output
    end

    # Sets tag to the server
    # @param [String] tag - the name of tag to be set
    #
    def add_tag (tag)
      `rs_tag --add "#{tag}"`
    end

    # Removes tag from the server
    # @param [String] tag - the name of tag to be removed
    #
    def remove_tag (tag)
      `rs_tag --remove "#{tag}"`
    end

    # Waits for tag to be removed or added during TIMEOUT
    # @param [String] tag - the name of tag to be checked for the state
    # @param [bool] should_exists - define state of tag to check: if true - check on tag existence, false - check that tag is absent
    # 
    def wait_for_tag (tag, should_exists)
      require 'timeout'
      done = false
        begin
          status = Timeout::timeout(TIMEOUT) do
            until done
              tags = get_server_tags
              if should_exists
                done = true if tags.include? "#{tag}"
              else
                done = true unless tags.include? "#{tag}"
              end
              unless done
                Chef::Log.info("Waiting for tag exists #{should_exists}. Retry in 10 seconds...")
                sleep 10
              end
            end
          end
       rescue Timeout::Error => e
       fail("=== ERROR === Timed out waiting for tag exists #{should_exists}")
     end
    end

    # Checks if tag exists.
    # It's also possible to provide only 'namespace:predicate'
    # @param [String] tag - the name of the tag to be checked
    # @return [String] found_tag - returns found tag if tag has been found, otherwise returns empty string
    # 
    def tag_exists? (tag)
      found_tag = ""
      tags = get_server_tags
      tags.any? do |t| 
        if s.include?(tag)
          found_tag = t
        end
      end
      return found_tag.gsub(/\n/, "").gsub(/\"/, "").strip
    end

  end
end

