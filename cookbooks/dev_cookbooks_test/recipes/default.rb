#
# Cookbook Name:: rightlink_test
# Recipe:: rs_tag_query_check
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.
#

# Check that  rs_tag --query works as expected:
# (1) for RightLink 5.9 (and <) - tag_list parameter should be quoted if it contains spaces, 
# no possibility to use tag with spaces in value;
# (2) for RightLink 6.0 - instead of the previous tag_list user should provide array if tags, 
# if any tag contains spaces it should be quoted.
#

powershell "test PowerShell" do 
  source <<-EOH
   # script 
   $rightlink_path = wmic process get ExecutablePath | Select-string "RightLinkService.exe"
   $rightlink_version = (get-command $rightlink_path | select -first 1).FileVersionInfo | % {$_.FileVersion}
   Write-output "RightLink version = $rightlink_version"
   Write-Output "=== FAIL === TEST"
   import-module "C:\\Program\ Files\ (x86)\\RightScale\\RightLink\\sandbox\\ruby\\lib\\ruby\\gems\\1.9.1\\gems\\right_link-6.0.3\\lib\\chef\\windows\\bin\\ChefNodeCmdlet.dll"
   get-chefnode -Path ""
   help Get-ChefNode
   $kernelOS = get-chefnode kernel, os
   Write-Output "$kernelOS"
   set-chefnode my_str "hello world"
   set-chefnode my_bool -BooleanValue $TRUE
   help Get-CurrentResource
   help Set-NewResource
   help Get-NewResource
   help Set-CurrentResource
   help Get-NextAction

  EOH

end
