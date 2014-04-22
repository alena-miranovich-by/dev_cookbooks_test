#
# Cookbook Name:: rightlink_test
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.


module RightlinkTester
  module Utils 

    TIMEOUT = 2 * 60
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
      tags_list.gsub(/\n/, " ").split(",")
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
                done = true unless tag_exists?(tag).empty?
              else
                done = true if tag_exists?(tag).empty?
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
      if tags.is_a? Array
        tags.each do |t| 
          if t.include?(tag)
            found_tag = t
          end
        end
      else 
        fail("ERROR: list of tags is not Array as it was expected")
      end
      return found_tag.gsub(/\n/, "").gsub(/\"/, "").strip
    end

    # Gets system log path depends on platform
    # @return [String] path - system log path
    # 
    def get_system_log
      if platform?('windows')
        Chef::Log.info "#{Dir.glob("C:/ProgramData/RightScale/log/rs-instance*.log")}"
     return Dir.glob("C:/ProgramData/RightScale/log/rs-instance*.log").max_by { |f| File.mtime(f)}

#        return Dir.glob("C:/ProgramData/RightScale/log/rs-instance*.log")[0]
      else 
        File.exists?("/var/log/syslog") ? "/var/log/syslog" :  "/var/log/messages" 
      end
    end

    # Checks system log for specific line or message
    # @param [String] line - provide line to verify on existance as regexp
    # (e.g /string to find/) with escaping all specific characters
    # @return [bool] exists - returns true if provided line exists in system log, otherwise returns false
    #
    def check_for_the_message (line) 
      File.readlines(get_system_log).grep(line).any? 
    end


    def is_private? (ip)
      is_private = false
      if ip.is_a? Array
        ip = ip[0].to_s
      end

      if ip =~ /^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/
        private_regexp = /\A(10\.|192\.168\.|172\.1[6789]\.|172\.2.\.|172\.3[01]\.)/
        # check if provided ip is private
        if ip =~ private_regexp
          is_private = true
        end
      else
        fail("Provided IP address is not valid: #{ip}")
      end
     is_private
    end

  end
end

