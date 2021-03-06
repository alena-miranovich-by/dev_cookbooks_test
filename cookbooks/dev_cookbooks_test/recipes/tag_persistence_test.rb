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
      unless tag_exists?(TAG).empty?
        sleep 1
        count += 1
        Chef::Log.info "Tag still exists after #{count/60} minutes." if (count % 60 == 0)
      else 
        Chef::Log.info "Tag doesn't exist" 
        exit 0
      end
    end
  end
end
  
