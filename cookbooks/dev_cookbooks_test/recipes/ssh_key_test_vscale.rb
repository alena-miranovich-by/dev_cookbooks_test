#
# Cookbook Name:: rightlink_test
# Recipe:: ssh_key_test_vscale
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Verifies that sshkey found in /var/spool/cloud/meta-data exists in /root/.ssh/authorized_keys file

require '/var/spool/cloud/meta-data'
metadata   = "/var/spool/cloud/meta-data.dict"
auth_keys  = "/root/.ssh/authorized_keys"
vscale_key = "VS_SSH_PUBLIC_KEY" 
test_state = node[:ssh_test][:ssh_public_key_expected]

unless node[:platform] == 'windows'
ruby_block "Verify that ssh-key exists in authorized_keys" do
  block do
		# Check input: if it's false - to not run recipe at all"
#    if test_state == 'false'
 #     Chef::Log.info "Will not run test-case, because of input is set to false"
 #   else 
    # Get the ssh-key defined in meta-data file
    metadata_hash = Hash[File.read(metadata).split("\n").map{|i| i.split("=")}] rescue nil

#    unless metadata_hash.nil?
      if metadata_hash.has_key?(vscale_key)
        ssh_key = metadata_hash[vscale_key]
      else
        Chef::Log.error "=== FAIL === There is no such key #{vscale_key} in #{metadata} file!"
        exit 100
      end
 #   else
#      Chef::Log.error "=== FAIL === Cannot read #{metadata} file"
 #     exit 101
  #  end

   # Chef::Log.info "SSH_KEY for test purposes: #{ssh_key}"
   if  ENV.key?("VS_SSH_PUBLIC_KEY") 
     ssh_key = ENV.key("VS_SSH_PUBLIC_KEY")
   end
    # Check that founded ssh_key exists in authorized_keys file
    if File.open(auth_keys, 'r').lines.any?{|line| line.include?("#{ssh_key}")}
      Chef::Log.info "=== PASSED === vScale ssh-key exists in #{auth_keys} and verified with #{metadata}."
    else 
      Chef::Log.error "=== FAIL === vScale ssh-key doesn't exist in #{auth_keys} file!"
      exit 102
    end
    #end
  end   
  not_if do test_state == 'false' end

end
end
