# check static ip assigning

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

IP0_ADDR = "RS_IP0_ADDR"
IP1_ADDR = "RS_IP1_ADDR"


network_adapter = node[:check_static_ip][:network_adapter]
test_state = node[:check_static_ip][:test_enabled]

Chef::Log.info "==================== check_static_ip recipe started ===================="

ruby_block "check static IP" do 
  block do
    public_ipv4 = get_instance_public_ip
    private_ipv4 = get_instance_private_ip
    Chef::Log.info "public #{public_ipv4} and private #{private_ipv4}"
 
    public_ips = node[:cloud][:public_ips]  
    private_ips = node[:cloud][:private_ips]
    Chef::Log.info "private ips #{private_ips} and public ips #{public_ips}."

    load_metadata
    
    case network_adapter

    when 'private'
      if ENV.key?(IP0_ADDR)
        ip = ENV[IP0_ADDR]
        check_ip_to_be_expected private_ipv4, ip
      else
        raise "=== FAIL === there is no #{IP0_ADDR} key in meta-data"
      end

     when 'public'
       if ENV.key?(IP0_ADDR)
         ip = ENV[IP0_ADDR]
         check_ip_to_be_expected public_ipv4, ip
       else
         raise "=== FAIL === there is no #{IP0_ADDR} key in meta-data"
       end

     when 'both'
     Chef::Log.info "both block"
       if (ENV.key?(IP0_ADDR) && ENV.key?(IP1_ADDR))
         for i in [ IP0_ADDR, IP1_ADDR ]
           ip = ENV[i]
           if is_private? ip
             check_ip_to_be_expected private_ipv4, ip
           else
            check_ip_to_be_expected public_ipv4, ip
           end
         end
       else
         raise "=== FAIL=== there are no both static IPs: ip0 = '#{ENV[IP0_ADDR]}' and  ip1 = '#{ENV[IP1_ADDR]}' values in meta-data"
       end
     end

    Chef::Log.info "==================== check_static_ip recipe finished ===================="
 
  end
  not_if { test_state == 'false' || node[:cloud][:provider] != 'vsphere' || get_rightlink_version.match('^6.0.[0-1]$') }
end 

