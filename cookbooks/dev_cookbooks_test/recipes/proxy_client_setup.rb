SERVER_TAG = "test:proxy_ip"
COLLECTION_NAME = "my_proxy_server"
$NEW_TAG = ""

log "============ Set Client Proxy =============="

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

=begin
log "Verify tag exists"
wait_for_tag SERVER_TAG do
  collection_name COLLECTION_NAME
end

log "Query servers for server proxy..."
server_collection COLLECTION_NAME do
  tags SERVER_TAG
end
=end

ruby_block "Find tag" do
  block do
    Chef::Log.info("Checking server collection for tag...")
    #h = node[:server_collection][COLLECTION_NAME]
    #tags = h[h.keys[0]]
    #Chef::Log.info("Tags:#{tags}")
    #result = tags.select { |s| s =~ /#{SERVER_TAG}/ }
    #unless result.empty?
    if tag_exists?(SERVER_TAG)
      Chef::Log.info("  Tag found!  Found #{result}")
      server_ip=String.new(result[0])
      server_ip[0,SERVER_TAG.length+1]=""
      $NEW_TAG = "rs_agent:http_proxy=#{server_ip}"
      add_tag($NEW_TAG) 
#      `rs_tag --add "#{$NEW_TAG}"`
    else
      Chef::Log.info("  No tag found")
    end
  end
end
