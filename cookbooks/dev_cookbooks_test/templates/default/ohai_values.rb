
======================================
= RightScale dependent Ohai Attributes
======================================

== Ruby Plugin
ruby_bin: <%= node[:languages][:ruby][:ruby_bin] %>
gems_dir: <%= node[:languages][:ruby][:gems_dir] %>

== Cloud Plugin
provider  : <%= node[:cloud][:provider] %>
<% if (node[:cloud][:public_ips]) # Checking for public_ips instead of Chef version %>
public_ip : <%= node[:cloud][:public_ips][0] %>
private_ip: <%= node[:cloud][:private_ips][0] %>
<% else %>
public_ip : <%= node[:cloud][:public_ip][0] %>
private_ip: <%= node[:cloud][:private_ip][0] %>
<% end %>


