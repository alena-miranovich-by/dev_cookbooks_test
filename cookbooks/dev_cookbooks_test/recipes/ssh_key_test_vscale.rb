#
# Cookbook Name:: rightlink_test
# Recipe:: ssh_key_test_vscale
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#
# Verifies that sshkey found in /var/spool/cloud/meta-data exists in /root/.ssh/authorized_keys file

unless node[:platform] == 'windows' || cloud.strip! != "vscale"
  require '/var/spool/cloud/meta-data'

  auth_keys  = "/root/.ssh/authorized_keys"
  test_state = node[:ssh_test][:ssh_public_key_expected]
  cloud = `cat /etc/rightscale.d/cloud`

  ruby_block "Verify that ssh-key exists in authorized_keys" do
    block do
      # Get vScale ssh-key value and verify it with authorized_keys file
      if ENV.key?("VS_SSH_PUBLIC_KEY")
        ssh_key = ENV["VS_SSH_PUBLIC_KEY"]

        # Check that founded ssh_key exists in authorized_keys file
        if File.open(auth_keys, 'r').lines.any?{|line| line.include?("#{ssh_key}")}
          Chef::Log.info "=== PASSED === vScale ssh-key exists in #{auth_keys} and verified with meta-data."
        else
          Chef::Log.error "=== FAIL === vScale ssh-key doesn't exist in #{auth_keys} file!"
          exit 102
        end

      else
        Chef::Log.info "=== FAIL === VS_SSH_PUBLIC_KEY environment variable is not exists!"
        exit 101
      end
    end
    not_if do test_state == 'false' end
  end
end

