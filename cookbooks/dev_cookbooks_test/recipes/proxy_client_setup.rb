SERVER_TAG = "test:proxy_ip"
COLLECTION_NAME = "my_proxy_server"
$NEW_TAG = ""

log "============ Set Client Proxy =============="

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end


ruby_block "Find tag" do
  block do
    Chef::Log.info("Checking server collection for tag...")
    result = tag_exists?(SERVER_TAG)
    unless result.empty?
      Chef::Log.info("  Tag found!  Found #{result}")
      server_ip=String.new(result.split('=')[1])
      server_ip[0,SERVER_TAG.length+1]=""
      $NEW_TAG = "rs_agent:http_proxy=#{server_ip}"
      add_tag($NEW_TAG) 
    else
      Chef::Log.info("  No tag found")
    end
  end
end
