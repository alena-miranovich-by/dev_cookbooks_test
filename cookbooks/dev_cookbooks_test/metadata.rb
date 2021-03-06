name             'dev_cookbooks_test'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures dev_cookbooks_test'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.1'

recipe "dev_cookbooks_test::default", "test"
recipe "dev_cookbooks_test::check_log_level", "test"
recipe "dev_cookbooks_test::ssh_key_test_vscale", "Test to verify that the sshkey found in /var/spool/cloud/meta-data exists in /root/.ssh/authorizedkeys file"
recipe "dev_cookbooks_test::nat_test", "NAT test"
recipe "dev_cookbooks_test::rs_config_tool", "rs_config test"
recipe "dev_cookbooks_test::rightlink_cli_tools_test", "Test to verify RightLink CLI tools available options. Only for RL 5.9.5+"
recipe "dev_cookbooks_test::rightlink_cli_test_recipe", "Additional recipe-helper to test rightlink cli tool"
recipe "dev_cookbooks_test::ohai_plugin_test", "ohai"
recipe "dev_cookbooks_test::rs_ohai_output_test", "rs_ohai output"
recipe "dev_cookbooks_test::proxy_client_setup", "??"
recipe "dev_cookbooks_test::rs_tag_query_test", "rs_tag"
recipe "dev_cookbooks_test::soft_reboot_test", "soft_Reboot"
recipe "dev_cookbooks_test::tag_break_point_test", "???"
recipe "dev_cookbooks_test::tag_cookbook_path_test", "???"
recipe "dev_cookbooks_test::tag_persistence_test", "??"
recipe "dev_cookbooks_test::core_env_test", "core env test"
recipe "dev_cookbooks_test::check_static_ip", "check static IP"

attribute "ohai_plugin_test/expected_network_adapter",
  :display_name => "Network Adapters Expected",
  :description => "What network adaptors should we expected to find. choose both for instances with both a public and private adapters -- like one EC2.",
  :required => "recommended",
  :default => "both",
  :choice => [ "public","private","both" ],
  :recipes => [ "dev_cookbooks_test::ohai_plugin_test" ]

attribute "ssh_test/ssh_public_key_expected",
  :display_name => "Input ssh_public_key expected",
  :description => "True/False to execute test-case. Works only for Linux OS and vScale cloud.",
  :recipes => [ "dev_cookbooks_test::ssh_key_test_vscale" ],
  :default => "false",
  :type => "string"

attribute "nat_test/nat_routes_expected",
  :display_name => "Input NAT_routes_expected",
  :description => "Set true or false to enable or disable NAT routes. Works only for vScale cloud (Linux and Windows).",
  :required => "recommended",
  :defaul => "false", 
  :recipes => [ "dev_cookbooks_test::nat_test" ],
  :type => "string"

attribute "cli_test/param",
  :display_name => "test param to provide it by json file",
  :description => "Do not set manually this field. It should be provided by json file",
  :recipes => ["dev_cookbooks_test::rightlink_cli_test_recipe" ]


attribute "check_static_ip/network_adapter",
  :display_name => "Network Adapter to check static IP",
  :description => " Provide network adapter to be checked: private/public or both. (both - where are both public and private adapters)",
  :required => "recommended",
  :default => "both",
  :choice => [ "public","private","both" ],
  :recipes => [ "dev_cookbooks_test::check_static_ip" ]

attribute "check_static_ip/test_enabled",
  :display_name => "Parameter to enable/disable the test",
  :description => "Set true or false to enable or disalbe the test",
  :required => "recommended",
  :default => "false",
  :choice => [ "false", "true"],
  :recipes => [ "dev_cookbooks_test::check_static_ip" ]

