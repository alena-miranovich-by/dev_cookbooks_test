#
# Cookbook Name:: rightlink_test
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.
#
#	Test to check if rs_ohai cloud and rs_ohai <cloud_name> is compatible to 
# correspondence original ohai plugin output
# Will not work on the following clouds: 

class Chef::Recipe
	include RightlinkTester::Ohai::Helper
  inlude RightlinkTester::Utils
end

@missing_clouds = [ "cloudstack", "azure", "softlayer", "vscale"]
@ohai           = "/opt/rightscale/sandbox/bin/ohai"
@rs_ohai        = "rs_ohai"
@cloud          = get_cloud_provider
@result         = 0

rl_version = get_rightlink_version

if rl_version.match('^6.*$')

 if @missing_clouds.include? @cloud
 # true => missing cloud
  # cloud is missing. Will not compare rs_ohai and sandboxed ohai output. 
  # Just check if rs_ohai contains necessary attributes
  cloud_attribute = get_node_attributes(@rs_ohai, "cloud")
  cloud_specific_attribute = get_node_attributes(@rs_ohai, @cloud)
  fail("=== FAILED === Cloud attribute is absent for #{@cloud} cloud!") if cloud_attribute.nil?
  fail("=== FAILED === #{@cloud} attribute is absent for #{@cloud} cloud!") if cloud_specific_attribute.nil? 
  Chef::Log.info("=== PASSED === cloud and #{@cloud} attributes are verified on existance")
 else 
 # false => supported cloud
  # current cloud is in list of supported clouds. It means that it should have the same values as sandboxed ohai plugin
  # 1. Verify that "cloud" output from rs_ohai has the same set of keys as from original ohai plugin
  option = "cloud"
  Chef::Log.info("rs_ohai #{option} verification started")
  results = compare_outputs(@ohai, @rs_ohai, option)
  if results.is_a? String # no_option parameter was set
	  Chef::Log.info("====FAILED==== #{results.to_s}")
	  @result += 1
  elsif results.is_a? Array
	  missed, mismatched, extra = results
	  if missed.empty? && mismatched.empty? && extra.empty?
		  Chef::Log.info("===PASSED==== rs_ohai #{option} verified")
	  else
		  unless missed.empty?
			  Chef::Log.info("=== FAILED === rs_ohai #{option} plugin missed necessary keys: #{missed}")
			  @result +=1
		  end
		  unless mismatched.empty?
			  Chef::Log.info("rs_ohai #{option} plugin has mismatched keys: #{mismatched}")
		  end
		  unless extra.empty?
			  Chef::Log.info("=== FAILED === rs_ohai #{option} has extra (unnecessary) keys: #{extra}")
			  @result +=1
		  end
	  end
  end

  # 2. Verify that "cloud specific" node is exists and compare output of rs_ohai and original ohai plugins
  option = get_cloud_provider
  Chef::Log.info("rs_ohai #{option} verification started")
  results = compare_outputs(@ohai, @rs_ohai, option)
  if results.is_a? Array
	  missed, mismatched, extra = results
	  if missed.empty? && mismatched.empty? && extra.empty?
		  Chef::Log.info("===PASSED==== rs_ohai #{option} verified")
	  else
		  @result +=1
		  unless missed.empty?
			  Chef::Log.info("=== FAILED === rs_ohai #{option} missed necessary keys: #{missed}")
		  end
		  unless mismatched.empty?
			  Chef::Log.info("=== FAILED === rs_ohai #{option} contains mismatched keys: #{mismatched}")
		  end
		  unless extra.empty?
			  Chef::Log.info("=== FAILED === rs_ohai #{opion} has extra keys: #{extra}")
		  end
    end
  elsif results.is_a? String
	  Chef::Log.info("==== FAILED ==== #{results.to_s}")
	  @result += 1
  end
  # if result is greater than 0 it means that at at least one of verification was failed
  if @result > 0
	  raise "=== TEST FAILED === outputs are not matched: see log above."
  end
 end
else
  Chef::Log.info("RightLink is not 6.0+. Will not run this test")
end

