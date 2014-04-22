# check static ip assigning

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

network_adapter = node[:check_static_ip][:network_adapter]
test_state = node[:check_static_ip][:test_enabled]

Chef::Log.info "==================== check_static_ip recipe started ===================="

ruby_block "check static IP" do 
  block do
    public_ipv4 = node[:cloud][:public_ipv4] 
    private_ipv4 = node[:cloud][:local_ipv4] 
    Chef::Log.info "public #{public_ipv4} and private #{private_ipv4}"
 
     # in case when public/private ip value is not string but array (clouds like Google)
    if public_ipv4.is_a? Array
      public_ipv4 = public_ipv4[0].to_s
    end
    if private_ipv4.is_a? Array
      private_ipv4 = private_ipv4[0].to_s
    end

    public_ips = node[:cloud][:public_ips]  
    private_ips = node[:cloud][:private_ips]
    Chef::Log.info "private ips #{private_ips} and public ips #{public_ips}."

    if platform?('windows')
      load File.join(::Dir::COMMON_APPDATA, "Rightscale", "spool", "cloud", "meta-data.rb")
    else
      require '/var/spool/cloud/meta-data'
    end

    case network_adapter

    when 'private'
      if ENV.key?(IP0_ADDR)
        ip = ENV[IP0_ADDR]
        if is_private? ip
          if private_ipv4 == ip
            Chef::Log.info "=== PASS === Current Private IP is the same as in meta-data."
          elsif private_ips
            if private_ips.include?(ip)
              Chef::Log.info "=== WARN === Current Private IP is '#{private_ipv4}'. IP from metadata ('#{ip}') is not set as current, but it exists in private_ips array: #{private_ips}."
            else
              raise "=== FAIL === Current Private IP ('#{private_ipv4}') is not the same as static IP from meta-data ('#{ip}')."
            end
          end
        else
          raise "=== FAIL === ip from meta-data is not private. Please make sure that input for test is provided correctly"
        end
      else
        raise "=== FAIL === there is no #{IP0_ADDR} key in meta-data"
      end

     when 'public'
       if ENV.key?(IP0_ADDR)
         ip = ENV[IP0_ADDR]
         unless is_private? ip
           if public_ipv4 == ip
             Chef::Log.info "=== PASS === Current Public IP is the same as in meta-data."
           elsif public_ips
             if public_ips.include?(ip)
               Chef::Log.info "=== WARN === Current Public IP is '#{public_ipv4}'. IP from metadata ('#{ip}') is not set as current, but it exists in public_ips array: #{public_ips}."
             else
               raise "=== FAIL === Current Public IP ('#{public_ipv4}') is not the same as static IP from meta-data ('#{ip}')."
             end
           end
         else
           raise "=== FAIL === ip from meta-data is not public. Please make sure that input for test is provided correctly."
         end
       else
         raise "=== FAIL === there is no #{IP0_ADDR} key in meta-data"
       end

 when 'both'
     Chef::Log.info "both bloc"
       if (ENV.key?(IP0_ADDR) && ENV.key?(IP1_ADDR))
         for i in [ IP0_ADDR, IP1_ADDR ]
           ip = ENV[i]
           if is_private? ip
           # ip is private
             if private_ipv4 == ip
               Chef::Log.info "=== PASS === Current Private IP is the same as in meta-data."
             elsif private_ips
               if private_ips.include?(ip)
                 Chef::Log.info "=== WARN === Current Private IP is '#{private_ipv4}'. IP from metadata ('#{ip}') is not set as current, but it exists in private_ips array: #{private_ips}."
               else
                 raise "=== FAIL === Current Private IP ('#{private_ipv4}') is not the same as static IP from meta-data ('#{ip}')."
               end
             end

           else
           # ip is public
             if public_ipv4 == ip
               Chef::Log.info "=== PASS === Current Public IP is the same as in meta-data."
             elsif public_ips
               if public_ips.include?(ip)
                 Chef::Log.info "=== WARN === Current Public IP is '#{public_ipv4}'. IP from metadata ('#{ip}') is not set as current, but it exists in public_ips array: #{public_ips}."
               else
                 raise "=== FAIL === Current Public IP ('#{public_ipv4}') is not the same as static IP from meta-data ('#{ip}')."
               end
             end
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
