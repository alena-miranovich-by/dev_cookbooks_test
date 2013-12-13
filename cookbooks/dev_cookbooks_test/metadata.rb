name             'dev_cookbooks_test'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures dev_cookbooks_test'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.0'

recipe "dev_cookbooks_test::default", "test"
recipe "dev_cookbooks_test::check_log_level", "test"
recipe "dev_cookbooks_test::ssh_key_test_vscale", "Test to verify that the sshkey found in /var/spool/cloud/meta-data exists in /root/.ssh/authorizedkeys file"

attribute "ssh_test/ssh_public_key_expected",
  :display_name => "Input ssh_public_key expected",
  :description => "True/False to execute test-case. Works only for Linux OS and vScale cloud.",
  :recipes => [ "dev_cookbooks_test::ssh_key_test_vscale" ],
  :default => "false",
  :type => "string"


