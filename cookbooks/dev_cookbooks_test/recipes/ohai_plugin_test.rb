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
#

# Check that Cloud Plugins are not null
ruby_block "cloud plugins should not be null" do
  block do
   # Get plugin values
   # There is a chase where the OS and provider will not return an IP
   # This is a reminder to come back and add this check.
   provider = node[:cloud][:provider]
   #platform = node[:platform]
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
       if node[:cloud][:public_ips][0]
           public_ip = node[:cloud][:public_ips][0]
           private_ip = node[:cloud][:private_ips][0]
       end
   rescue NoMethodError => e
       public_ip = node[:cloud][:public_ip][0]
       private_ip = node[:cloud][:private_ip][0]
   end

   # Verify they are not null
   if provider.nil? || provider.empty?
       raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'provider plugin null'" 
   end
   # Get input expected_network_adapter
   network_adapter = node[:ohai_plugin_test][:expected_network_adapter]

   case network_adapter
   when 'both' 
     if public_ip.nil? || public_ip.empty?
       raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'public_ip plugin null'"
     elsif private_ip.nil? || private_ip.empty?
       raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'private_ip plugin null'"
     end
   when "public"
     if public_ip.nil? || public_ip.empty?
       raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'public_ip plugin null'"
     end
   when "private"
     if private_ip.nil? || private_ip.empty?
       raise "=== FAIL === Recipe: ohai_plugin_test DESCRIPTION: ohai ruby plugin: 'private_ip plugin null'"
     end
   else
     Chef::Log.info "Input has not expected value: #{network_adapter}."
     Kernel::abort("Input was not set correctly: test was not completed.")
   end
   
   Chef::Log.info("=== PASS === Recipe: ohai_plugin_test DESCRIPTION: Cloud Plugins")

  end
end

