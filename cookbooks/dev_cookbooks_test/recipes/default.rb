#
# Cookbook Name:: dev_cookbooks_test
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#git "/tmp/right_link" do
#  repository "https://github.com/rightscale/right_link.git"
#  reference "master"
#  action :sync
#end

levels = Array.new
levels = ["info","debug", "warn", "fatal", "error"]

levels.each |val| 
        log "test message with level ""#{val}" do
               level :#{val}
        end
end

