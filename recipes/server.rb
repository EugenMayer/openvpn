#
# Cookbook:: openvpn
# Recipe:: server
#
# Copyright:: 2009-2018, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'openvpn::enable_ip_forwarding'
include_recipe 'openvpn::install_bridge_utils' if node['openvpn']['type'] == 'bridge'
include_recipe 'openvpn::install'

include_recipe 'openvpn::easy_rsa'

# this recipe currently uses the bash resource, ensure it is installed
p = package 'bash' do
  action :nothing
end
p.run_action(:install)

# in the case the key size is provided as string, no integer support in metadata (CHEF-4075)
node.override['openvpn']['key']['size'] = node['openvpn']['key']['size'].to_i

key_dir  = node['openvpn']['easyrsa']['key_dir']

directory key_dir do
  owner 'root'
  group node['root_group']
  recursive true
  mode  '0700'
end

template '/etc/openvpn/server.up.sh' do
  source 'server.up.sh.erb'
  owner 'root'
  group node['root_group']
  mode  '0755'
  notifies :restart, 'service[openvpn]'
end

directory '/etc/openvpn/server.up.d' do
  owner 'root'
  group node['root_group']
  mode  '0755'
end

file "#{key_dir}/index.txt" do
  owner 'root'
  group node['root_group']
  mode  '0600'
  action :create
end

file "#{key_dir}/serial" do
  content '01'
  action :create_if_missing
end

require 'openssl'

openvpn_conf 'server' do
  notifies :restart, 'service[openvpn]'
  only_if { node['openvpn']['configure_default_server'] }
  action :create
end

include_recipe 'openvpn::service'
