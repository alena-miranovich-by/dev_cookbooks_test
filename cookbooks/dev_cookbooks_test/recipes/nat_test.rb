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

require '/var/spool/cloud/meta-data'
#test_state = node[:nat_test][:nat_routes__expected]
cloud = `cat /etc/rightscale.d/cloud`

unless cloud.strip! != "vscale"
  ruby_block "Verify NAT routes got setup correctly" do
    block do
      routes_env = []
      routes_set = `ip route show`
      missed_routes = []
      # Get RS_NAT_ADDRESS
      if ENV.key?("RS_NAT_ADDRESS")
        @ip = ENV["RS_NAT_ADDRESS"]
      else
        Kernel::abort("RS_NAT_ADDRESS is not defined in meta-data. Will not run test")
      end
      # Get RS_NAT_RANGES from meta-data
      if ENV.key?("RS_NAT_RANGES")
        ranges = ENV["RS_NAT_RANGES"].split(",")
        
        # Parse to array [address, mask]
        ranges.each do |route|
          routes_env.push(route.split("/"))
        end
        Chef::Log.info("#{routes_env.inspect}")

        # Verify that every provided route got setup correctly on the instance
        routes_env.each do |route|
          # if mask is 32, it will not shown
          if route[1] == "32"
            Chef::Log.info("mask is 32")
            if routes_set.include? "#{route[0]} via #{@ip}"
              Chef::Log.info("Route #{route[0]} setup correctly")
            else
              missed_routes.push(route)
            end
          else 
            Chef::Log.info("mask is not 32")
            if routes_set.include? "#{route[0]}/#{route[1]} via #{ip}"
              Chef::log.info("Route #{route[0]} with #{route[1]} mask setup correctly")
            else
              missed_routes.push(route)
            end
          end
        end

      end
      fail("Routes have not been setup correctly. Missed routes: \n #{missed_routes.inspect}") unless missed_routes.empty?
    end
    not_if do test_state == 'false' end
  end
end
         
