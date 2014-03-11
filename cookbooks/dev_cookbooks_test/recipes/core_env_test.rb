#
# Cookbook Name:: rightlink_test
# Recipe:: core_env_test
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Verifies core site populates env values (instance_uuid,…)

template_path = ::File.join(::Dir.tmpdir, "core_env.log")

test_dir = if platform?('windows') 
  "C:\\tester"
else 
  "/tester"
end

directory "#{test_dir}" do
  action :create
end

template "#{test_dir}/core_env.log" do
  source "core_env.erb"
  path template_path
  action :create
end

output_file template_path

