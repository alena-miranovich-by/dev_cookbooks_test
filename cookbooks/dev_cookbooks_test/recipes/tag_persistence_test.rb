TAG = "rightlink:test=persistence"
#COLLECTION_NAME = "tag_persistence_check"

log "============ resource test: tag_persistence_check =============="

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end


#log "Add tag: #{TAG}"
#right_link_tag "#{TAG}"

#log "Verify tag exists"
#wait_for_tag TAG do
#  collection_name COLLECTION_NAME
#end

# 
# Now check every second that it still exists.
# This will run forever -- unless the tag gets lost
#
ruby_block "infinite loop checking persistence" do
  block do
    Chef::Log.info "Add tag: #{TAG}"
    add_tag(TAG)
    Chef::Log.info "Verify tag exists"
    wait_for_tag(TAG, true)

    count = 0
    while(1)
      tags = get_server_tags
      raise "ERROR: tags dissappeared!! #{tags}" if tags == nil
      sleep 1
      count += 1
      Chef::Log.info "Tag still exists after #{count/60} minutes." if (count % 60 == 0)
    end
=begin
    resrc = Chef::Resource::ServerCollection.new(COLLECTION_NAME)
    resrc.tags TAG
    provider = nil
    
    if (Chef::VERSION =~ /0\.9/) # provider signature changed in Chef 0.9
      provider = Chef::Provider::ServerCollection.new(resrc, @run_context)
    else 
      provider = Chef::Provider::ServerCollection.new(node, resrc)
    end

    count = 0
    while(1) 
      provider.send("action_load")
      h = node[:server_collection][COLLECTION_NAME]
      tags = h[h.keys[0]]
      raise "ERROR: tag disappeared!! #{h.to_hash.inspect}" if tags == nil
      sleep 1
      count += 1
      Chef::Log.info "  Tag still exists after #{count/60} minutes." if (count % 60 == 0)
    end
=end
  end
end
  
