#
# Cookbook:: openvpn-easyrsa
# Recipe:: server
#
# Copyright:: 2023, Eugen Mayer
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

include_recipe 'openvpn-easyrsa::enable_ip_forwarding'
include_recipe 'openvpn-easyrsa::install_bridge_utils' if node['openvpn']['type'] == 'bridge'
include_recipe 'openvpn-easyrsa::install'
include_recipe 'openvpn-easyrsa::easy_rsa'

# this recipe currently uses the bash resource, ensure it is installed
p = package 'bash' do
  action :nothing
end
p.run_action(:install)

# in the case the key size is provided as string, no integer support in metadata (CHEF-4075)
node.override['openvpn']['key']['size'] = node['openvpn']['key']['size'].to_i

key_dir  = node['openvpn']['easyrsa']['key_dir']

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

if node['openvpn']['tls']['generate_tls_shared_key'] == true
  tls_target_location = node['openvpn']['tls']['path']
  execute 'generate_ta' do
    command "openvpn --genkey secret #{tls_target_location}"
    action :run
    creates tls_target_location
  end
  node.override['openvpn']['config']['tls-auth'] = "#{tls_target_location} 0"
end

file "#{key_dir}/serial" do
  content '01'
  action :create_if_missing
end

require 'openssl'

openvpn_easyrsa_conf 'server' do
  notifies :restart, 'service[openvpn]'
  only_if { node['openvpn']['configure_default_server'] }
  action :create
end

include_recipe 'openvpn-easyrsa::service'
