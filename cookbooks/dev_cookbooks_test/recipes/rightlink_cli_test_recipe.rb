#
# Cookbook Name:: rightlink_test
# Recipe:: rightlink_cli_test_recipe.rb
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Additional recipe to test rightlink command line tool rs_run_recipe
#

node[:cli_test][:param].empty? ? Chef::Log.info("test message from test recipe") : Chef::Log.info("parameters from JSON file: #{node[:cli_test][:param]}")
