# check static ip assigning

class Chef::Resource::RubyBlock
  include RightlinkTester::Utils
end

network_adapter = node[:check_static_ip][:network_adapter]
test_state = node[:check_static_ip][:test_enabled]

ruby_block "check static IP" do 
 block do
   public_ipv4 = node[:cloud][:public_ipv4] 
   private_ipv4 = node[:cloud][:local_ipv4] 
   Chef::Log.info "public #{public_ipv4} and private #{private_ipv4}"
 
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
       Chef::Log.info "#{ip} frommetadata is the same as current privaate IP"
     elsif private_ips
       if private_ips.include?(ip)
         Chef::Log.info "ip #{ip} from metadata has been successfully set as private static IP"
       end
     else 
      raise "ip from metadata is not set as private"
     end

    when 'public' 
      if public_ipv4 == ip
       Chef::Log.info "#{ip} frommetadata is the same as current public IP"
     elsif public_ips
       if public_ips.include?(ip)
         Chef::Log.info "ip #{ip} from metadata has been successfully set as public static IP"
       end
     else   
      raise "ip from metadata is not set as public"
     end

    when 'both' 
      if public_ipv4 == ip
         Chef::Log.info "ip #{ip} from metadata is the same as current public IP"
       elsif public_ips
         if public_ips.include?(ip)
           Chef::Log.info "ip #{ip} from metadata has been successfully set as static public IP"
         end
       else 
         # check if it is private
         if private_ipv4 == ip
           Chef::Log.info "#{ip} frommetadata is the same as current privaate IP"
         elsif private_ips
           if private_ips.include?(ip)
             Chef::Log.info "ip #{ip} from metadata has been successfully set as private static IP"
           end
         else 
          raise "ip from metadata is not set as private or static"
         end
       end
     end
  end
end

 end
 not_if { test_state == 'false' || node[:cloud][:provider] != 'vsphere' }
end 

