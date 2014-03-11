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

Chef::Log.info "#{template_path}"

template "#{template_path}" do
  source "core_env.erb"
  path template_path
  action :create
end

output_file template_path

