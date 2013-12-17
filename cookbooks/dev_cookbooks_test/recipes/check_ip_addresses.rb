#
# Cookbook Name:: rightlink_test
# Recipe:: check_ip_addresses
#
# Copyright RightScale, Inc. All rights reserved. All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Verify that private IP is private and public is public

# Get ip addresses and verify
ruby_block "verify private_ip is private and public_ip is public" do
  block do
    public_ipv4 = node[:cloud][:public_ipv4]
    private_ipv4 = node[:cloud][:local_ipv4]
    private_regexp = /\A(10\.|192\.168\.|172\.1[6789]\.|172\.2.\.|172\.3[01]\.)/

    unless public_ipv4.nil? || private_ipv4.nil?
      if public_ipv4 =~ private_regexp
        Chef::Log.error "=== FAIL === Public IP #{public_ipv4} is private."
        exit 101
      end
      unless private_ipv4 =~ private_regexp
        Chef::Log.error "=== FAIL === Private IP #{private_ipv4} is not private."
        exit 102
      end
    else
      public_ipv4.nil? ? Chef::Log.info("Public IP is null") : Chef::Log.info("Private IP is null")
    end
  end
end

