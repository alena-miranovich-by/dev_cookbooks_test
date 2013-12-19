#
# Cookbook Name:: rightlink_test
# Recipe:: nat_routes_test_vscale
#
# Copyright RightScale, Inc. All rights reserved. All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Verifies that RS_NAT_RANGES env got setup correctly. 
# Test has input nat_routes_expected with default 'false' value to disable test.
# Test could be applied only for vScale cloud on Linux and Windows machines.
#

test_state = node[:nat_test][:nat_routes_expected]
#require 'ipaddr'

if node[:platform] == 'windows'
  load File.join(::Dir::COMMON_APPDATA, "Rightscale", "spool", "cloud", "meta-data.rb")
else
  require '/var/spool/cloud/meta-data'
end

ruby_block "Verify NAT routes got setup correctly" do
  block do
    routes_env = []
    missing_routes = []

    # Get RS_NAT_ADDRESS
    if ENV.key?("RS_NAT_ADDRESS")
      @ip = ENV["RS_NAT_ADDRESS"]
    else
      Process::abort("RS_NAT_ADDRESS is not defined in meta-data. Will not run test")
    end
    # Get RS_NAT_RANGES from meta-data
    if ENV.key?("RS_NAT_RANGES")
      ranges = ENV["RS_NAT_RANGES"].split(",")
     
      # Parse to array [address, mask]
      ranges.each do |route|
        routes_env.push(route.split("/"))
      end

      cidr_to_netmask = Proc.new { |cidr| 
        mask = IPAddr.new('255.255.255.255').mask(cidr).to_s
        Chef::Log.info("#{mask} from proc")
        mask
      }

      unless node[:platform] == 'windows'
        @routes_set = `ip route show`
      else 
        @routes_set = `route print`
      end

      routes_env.each do |route|
        route_regex = if node[:platform] == 'windows'
                network = route[0]
                mask = cidr_to_netmask.call(route[1])
                /#{network}.*#{mask}.*#{@ip}/
              else
                /#{network}.*via.*#{@ip}/
              end
        matchdata = @routes_set.match(route_regex)
        if matchdata == nil
           missing_routes.push(route)
        else 
          Chef::Log.info("Route #{route[0]} matched")
        end
      end
    end
    unless missing_routes.empty?
      Process::abort("=== FAIL === Routes have not been setup correctly. Missing routes: \n #{missing_routes.inspect}")
    else
      Chef::Log.info("=== PASS === NAT routes test completed successfully. Range from ENV has been setup correctly.")
    end

  end
  not_if do test_state == 'false' end
end
       
