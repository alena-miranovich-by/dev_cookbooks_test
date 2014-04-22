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
 
    if public_ipv4.is_a? Array 
      public_ipv4 = public_ipv4[0].to_s
    end
    if private_ipv4.is_a? Array 
      private_ipv4 = private_ipv4[0].to_s
    end

    public_ips = node[:cloud][:public_ips]  
    Chef::Log.info "public ips #{public_ips}"
    private_ips = node[:cloud][:private_ips]
    Chef::Log.info "private ips #{private_ips}"

    if platform?('windows')
      load File.join(::Dir::COMMON_APPDATA, "Rightscale", "spool", "cloud", "meta-data.rb")
    else
      require '/var/spool/cloud/meta-data'
    end
 
    for i in 0..1
      key = "RS_IP"+i.to_s+"_ADDR"
      if ENV.key?(key)
        #exists
        ip = ENV[key]
        Chef::Log.info "from metadata ip#{i} addr is #{ip}"

        case network_adapter
        when 'private'       
          if private_ipv4 == ip
            Chef::Log.info "=== PASS === IP from metadata is '#{ip}'. Current private IP is the same: '#{private_ipv4}'."
          elsif private_ips
            if private_ips.include?(ip)
              Chef::Log.info "=== WARN === Current private IP is '#{private_ipv4}'. IP from metadata is '#{ip}' which is not set as current, but it exists in private_ips array: #{private_ips}."
            end
          else 
            raise "=== FAIL === Current private IP ('#{private_ipv4}') is not matched to static IP from metadata ('#{ip}'). Please check network settings."
          end

        when 'public' 
          if public_ipv4 == ip
            Chef::Log.info "=== PASS === IP from metadata is '#{ip}'. Current public IP is the same: '#{public_ipv4}'."
          elsif public_ips
            if public_ips.include?(ip)
              Chef::Log.info "=== WARN === Current public IP is '#{public_ipv4}'. IP from metadata is '#{ip}' which is not set as current public IP, but it exists in public_ips array: #{public_ips}."
            end
          else   
            raise "=== FAIL === Current public IP ('#{public_ipv4}') is not matched to static IP from metadata ('#{ip}'). Please check network settings."
          end

        when 'both' 
          if public_ipv4 == ip
            Chef::Log.info "=== PASS public === IP from metadata is '#{ip}'. Current public IP is the same: '#{public_ipv4}'."
          elsif public_ips
            if public_ips.include?(ip)
              Chef::Log.info "=== WARN public === Current public IP is '#{public_ipv4}'. IP from metadata is '#{ip}' which is not set as current public IP, but it exists in public_ips array: #{public_ips}."
            end
          else 
            # check if it is private
            if private_ipv4 == ip
              Chef::Log.info "=== PASS private === IP from metadata is '#{ip}'. Current private IP is the same: '#{private_ipv4}'."
            elsif private_ips
              if private_ips.include?(ip)
                Chef::Log.info "=== WARN private === Current private IP is '#{private_ipv4}'). IP from metadata is '#{ip}' which is not set as current private IP, but it exists in private_ips array: #{private_ips}."
              end
            else 
              raise "=== FAIL === Current public ('#{public_ipv4}') and private ('#{private_ipv4}') IPs are not matched to static IPs from metadata. Please check network settings."
            end
          end
        end
      end
    end
    Chef::Log.info "==================== check_static_ip recipe finished ===================="

  end
  not_if { test_state == 'false' || node[:cloud][:provider] != 'vsphere' || get_rightlink_version.match('^6.0.[0-2]$') }
end 

