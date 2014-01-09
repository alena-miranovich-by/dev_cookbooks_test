#
# Cookbook Name:: rightlink_test
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.


module RightlinkTester
	module Ohai
		module Helper
			
			# Creates new Helper object.

			#
			# Gets attributes for specified node. Return nil if there is no such node
			#
			# @param plugin [String] is plugin command
			# @param node [String] is node to be populated
			#
			# @return [Hash] parsed JSON hash with node attributes 
			#
			def get_node_attributes (plugin, node)
				command = [plugin, node].join(" ")
				output = `#{command} 2>&1` # redirect output to catch 'missing attribute' error
				res = $?.success?
				if (res)
					output = `echo '#{output}' | grep -v WARN`
					output_json = JSON.load(output.strip!)
					
					hash_output = Hash.new
	
					if output_json.is_a? Hash
						hash_output = output_json.dup
					elsif
						output_json.is_a? Array
							output_json.each do |key, value|
								hash_output[key] = value
							end
					else
						raise "Could not convert ohai json to hash"
					end
					
					return hash_output
				end
			end
		 
			#
			# Gets differences between two hashes and outputs them to log
			#
			# @param h1 [Hash] original, correct hash
			# @param h2 [Hash] hash to be checked
			# 
			# @return [Array] Results -array of arrays with all missed, mismatched and extra keys
			#
			def get_differences(h1, h2)
				results = [missed = [], mismatched = [], extra = []]
				unless h1.nil? && h2.nil?
					h1.each do |k1, v1|
						if h2.has_key?(k1)
							if h2[k1] != v1
								mismatched.push(k1)
							end
							h2.delete(k1)
						else
							missed.push(k1)
						end
					end

					unless h2.empty?
						h2.each do |k2|
							extra.push(k2)
						end
					end

					return results
				end
			end
			
			#
			# Retrieves cloud provider name from cloud-file
			#
			# @return @cloud - name of cloud provider
			# 
			def get_cloud_provider
				cloud = `cat /etc/rightscale.d/cloud`
				cloud.strip!
				return cloud
			end

			#
			# Compares outputs of two plugins: original ohai and rs_ohai with appropriate option
			# 
			# @param orig_plugin [String] - original plugin, to which anoter plugin will be compared
			# @param verify_plugin [String] - plugin which will be checked to be compatible with original plugin
			# @param option [String] - option for plugins
			#
			# @return arrays: missed, mismatched and extra 
			#      or no_option if missing attribute error has been rescued
			# 
			def compare_outputs(orig_plugin, verify_plugin, option)
				results = [missed = [], mismatched = [], extra = []]
				rs_plugin = get_node_attributes(verify_plugin, option)
				ohai_plugin = get_node_attributes(orig_plugin, option)
				if ohai_plugin.nil?
					if rs_plugin.nil?
						return results # both hashed are nil => identical
					else
						return no_option = "rightscale plugin has this attribute when original doesn't"
					end
				else
					if rs_plugin.nil?
						return no_option = "rightscale plugin missing the attribute when original has this node"   
					else	
						results = get_differences(ohai_plugin, rs_plugin)
						return results
					end
				end

			end

		end
	end
end

