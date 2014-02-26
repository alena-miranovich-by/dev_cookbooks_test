#
# Cookbook Name:: rightlink_test
# Recipe:: ohai_plugin_test
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Write values that our custom ohai plugins should provide
# This will fail if our plugins are not loaded
# Added expected_network_adapter input to set what network adapter
# should we expected to find. Available options: 'both', 'private', 'public'.
# Choose 'both' fo instances with public and private adapters (like EC2)
# or choose 'public' or 'private' for instances 
# where there is only one network adapter. 
# This test also checks is private IP is private and public IP is public
#

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

template_path = ::File.join(::Dir.tmpdir, "ohai_values.log")
template "/tmp/ohai_values.log" do
  path template_path
  source "ohai_values.erb"
  action :create
end

output_file template_path

# Check that chef is not using sandboxed ruby -- this is fixed by our custom ruby provider
ruby_block "ruby_bin should not point to sandbox" do
  block do
    unless node[:platform] == 'windows'
      test_failed = ( node[:languages][:ruby][:ruby_bin] =~ /sandbox/ )
      raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'ruby_bin' value points to sandbox: #{node[:languages][:ruby][:ruby_bin]}" if test_failed
      Chef::Log.info("=== PASS === Recipe: ohai_plugin_test DESCRIPTION: ruby_bin should not point to sandbox")
    end
  end
end

# Check that chef is not using sandboxed gems -- this is fixed by our custom ruby provider
ruby_block "gems_dir should not point to sandbox" do
  block do
    unless node[:platform] == 'windows'
      test_failed = ( node[:languages][:ruby][:gems_dir] =~ /sandbox/ )
      raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'gems_dir' value points to sandbox: #{node[:languages][:ruby][:gems_dir]}" if test_failed
      Chef::Log.info("=== PASS === Recipe: ohai_plugin_test DESCRIPTION: gems_dir should not point to sandbox")
    end
  end
end

# Check that Cloud Plugins are not null
ruby_block "cloud plugins should not be null" do
  block do
   # Get plugin values
   # There is a chase where the OS and provider will not return an IP
   # This is a reminder to come back and add this check.
   provider = node[:cloud][:provider]
   platform = node[:platform]
   platform_version = node[:platform_version]
   public_ipv4 = node[:cloud][:public_ipv4] #v5.8 only and cloud dependant
   public_hostname = node[:cloud][:public_hostname] #v5.8 only and cloud dependant
   local_ipv4 = node[:cloud][:local_ipv4] #v5.8 only and cloud dependant
   local_hostname = node[:cloud][:local_hostname] #v5.8 only and cloud dependant

   Chef::Log.info "public_ipv4=#{public_ipv4}" #v5.8 only and cloud dependant
   Chef::Log.info "public_hostname=#{public_hostname}" #v5.8 only and cloud dependant
   Chef::Log.info "local_ipv4=#{local_ipv4}" #v5.8 only and cloud dependant
   Chef::Log.info "local_hostname=#{local_hostname}" #v5.8 only and cloud dependant
   Chef::Log.info "provider=#{provider}"
   Chef::Log.info "platform=#{platform}"
   Chef::Log.info "platform_version=#{platform_version}"

   begin
       if node[:cloud][:public_ips]
           public_ip = node[:cloud][:public_ips][0]
           private_ip = node[:cloud][:private_ips][0]
       end
   rescue NoMethodError => e
       public_ip = node[:cloud][:public_ip][0]
       private_ip = node[:cloud][:private_ip][0]
   end

   # Verify provider is not null
   if provider.nil? || provider.empty?
       raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'provider plugin null'" 
   end

   # Verify that cloud specific node exists
   if node.attribute?(provider)
     Chef::Log.info("=== PASS === node[:#{provider}] exists.")
   else
     fail("=== FAIL === node[:#{provider}] doesn't exist.")
   end

   # Get input expected_network_adapter and verify network adapters accordingly
   network_adapter = node[:ohai_plugin_test][:expected_network_adapter]

   is_private_ip = Proc.new { |ip|
     is_private = false
     # check if provided ip is valid ipv4 address
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
   }

   case network_adapter
   when 'both' 
     if public_ip.nil? || public_ip.empty?
       raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'public_ip plugin null'"
     elsif private_ip.nil? || private_ip.empty?
       raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'private_ip plugin null'"
     end
     raise "=== FAIL === Public IP #{public_ipv4} is private." if is_private_ip.call(public_ipv4)
     raise "=== FAIL === Private IP #{local_ipv4} is not private." unless is_private_ip.call(local_ipv4)
   when 'public'
     raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'public_ip plugin null'" if public_ip.nil? || public_ip.empty?     
     raise "=== FAIL === Public IP #{public_ipv4} is private." if is_private_ip.call(public_ipv4)
   when 'private'
     raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'private_ip plugin null'" if private_ip.nil? || private_ip.empty?
     raise "=== FAIL === Private IP #{local_ipv4} is not private." unless is_private_ip.call(local_ipv4)
   else
     Chef::Log.info "Input has not expected value: #{network_adapter}."
     Kernel::abort("Input was not set correctly: test was not completed.")
   end
   
   Chef::Log.info("=== PASS === Recipe: ohai_plugin_test DESCRIPTION: Cloud Plugins")

  end
end

#Used to check if instance has rebooted
UUID = node[:rightscale][:instance_uuid]
UUID_TAG = "rs_instance:uuid=#{UUID}"

#Chef::Log.info "Query servers for our tags..."
#server_collection UUID do
#  tags UUID_TAG
#end

#Used to check for dev tags
TAG = "test:dev_check=true"
#COLLECTION_NAME = "tag_test"

#add_tag(TAG)
#right_link_tag TAG

#wait_for_tag TAG do
#  collection_name COLLECTION_NAME
#end

# Check that chef and ohai log levels are set to info
ruby_block "chef and ohai log levels are set to info" do
  block do
    
    add_tag(TAG)
    wait_for_tag(TAG, true)
 
    Chef::Log.info("Checking server collection for tag...")
    unless tag_exists?(UUID_TAG).empty?
      Chef::Log.info("Tag found!")  
    end  
    
=begin
    h = node[:server_collection][UUID]
    tags = h[h.keys[0]]
    unless tags.nil? || tags.empty?
      Chef::Log.info("Tags:#{tags}")
      result = tags.select { |s| s == UUID_TAG }
      unless result.empty?
        Chef::Log.info("Tag found!")
      end
    end
=end
    
    ohai_log_level = Ohai::Config[:log_level]
    chef_log_level = Chef::Log.logger.level

    Chef::Log.info("ohai_log_level = #{ohai_log_level}")
    Chef::Log.info("chef_log_level = #{chef_log_level}")

    unless tag_exists?("rs_agent_dev").empty?
=begin
    h = node[:server_collection]["tag_test"]
    tags = h[h.keys[0]]
    Chef::Log.info("Tags:#{tags}")
    result = tags.select { |s| s == "rs_agent_dev" }


    if result.empty?
=end
      Chef::Log.info("==Dev Tag found==")

      if "#{ohai_log_level}" != "1"
        Chef::Log.info("ohai_log_level = #{ohai_log_level}")
        raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: Ohai log level not set to info"
      end

      if  "#{chef_log_level}" != "info"
        Chef::Log.info("chef_log_level = #{chef_log_level}")
        raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: Chef log level not set to info"
      end
      Chef::Log.info("=== PASS === Recipe: ohai_plugin_test DESCRIPTION: Chef and Ohai log levels are set to info")

    else

      Chef::Log.info("==NO Dev Tag found==")
      
      if "#{ohai_log_level}" != "1"
        Chef::Log.info("ohai_log_level = #{ohai_log_level}")
        raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: Ohai log level not set to info"
      end

      if  "#{chef_log_level}" != "info"
        Chef::Log.info("chef_log_level = #{chef_log_level}")
        raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: Chef log level not set to info"
      end
      Chef::Log.info("=== PASS === Recipe: ohai_plugin_test DESCRIPTION: Chef and Ohai log levels are set to info")

    end

    Chef::Log.info "Add our instance UUID as a tag: #{UUID_TAG}"
    add_tag(UUID_TAG)
    Chef::Log.info "Verify tag exists"
    wait_for_tag(UUID_TAG, true)

  end
end
=begin
Chef::Log.info "Add our instance UUID as a tag: #{UUID_TAG}"
add_tag(UUID_TAG)
`rs_tag --add #{UUID_tag}`
#right_link_tag UUID_TAG

Chef::Log.info "Verify tag exists"
wait_for_tag UUID_TAG do
  collection_name UUID
end
=end
