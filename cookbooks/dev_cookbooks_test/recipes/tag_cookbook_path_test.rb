
COOKBOOK_PATH = "/root/my_cookbooks"
TAG = "rs_agent_dev:cookbooks_path=#{COOKBOOK_PATH}/cookbooks"

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

log "============ tag_cookbook_path_test =============="

ruby_block "Query for cookbook path" do
  block do
    Chef::Log.info("Checking server collection for tag...")
    unless tag_exists?(TAG).empty?
      Chef::Log.info("  Tag found!")
      node.default[:devmode_test][:loaded_custom_cookbooks] = true
    else
      Chef::Log.info("  No tag found -- set and reboot!")
    end
  end
end

# if not, add tag to instance and...
unless node[:devmode_test][:loaded_custom_cookbooks]
  `rs_tag --add #{TAG}`
end

# ...copy test cookbooks to COOKBOOK_PATH, then...
ruby_block "copy this repo" do
  block do 
    Chef::Log.info "Rebooting so coobook_path tag will take affect."
    FileUtils.mkdir("#{COOKBOOK_PATH}")
    FileUtils.cp_r("#{File.dirname(__FILE__)}", "#{COOKBOOK_PATH}")
#ruby "copy this repo" do
 # not_if do node[:devmode_test][:loaded_custom_cookbooks] end
 # code <<-EOH
 #   Chef::Log.info "Rebooting so coobook_path tag will take affect."
 #   ::FileUtils.mkdir("#{COOKBOOK_PATH}")
 #   ::FileUtils.cp_r("#{::File.join(File.dirname(__FILE__), "..", "..", "..","*")}", "#{COOKBOOK_PATH}")
 # EOH
  end
  not_if do node[:devmode_test][:loaded_custom_cookbooks] end
end

#TODO: add a reboot count check and fail if count > 3

# Reboot, if not set
## lame switch for windows vs linux because the Window shutdown.exe is not always accessible
case node[:platform]
  when "windows"
    powershell "Powershell reboot" do
      source 'restart-computer -Force'
      not_if do node[:devmode_test][:loaded_custom_cookbooks] end
    end
  else
    execute "Rebooting so breakpoint tag will take affect." do
      command "init 6"
      not_if do node[:devmode_test][:loaded_custom_cookbooks] end
    end
end

log "TODO: Check that were using local cookbook repo (somehow)"
