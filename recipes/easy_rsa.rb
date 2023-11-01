#
# Cookbook:: openvpn-easyrsa
# Recipe:: server
#
# Copyright:: 2023, Eugen Mayer
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


package 'easy-rsa'

directory '/etc/openvpn/easy-rsa' do
  owner 'root'
  group node['root_group']
  mode  '0755'
end

link '/etc/openvpn/easy-rsa/easyrsa' do
  to '/usr/share/easy-rsa/easyrsa'
  action :create
end

key_dir  = node['openvpn']['easyrsa']['key_dir']
ca_crt  = node['openvpn']['easyrsa']['signing_ca_cert']
dh  = node['openvpn']['easyrsa']['dh']
crl  = node['openvpn']['easyrsa']['crl']
server_csr  = node['openvpn']['easyrsa']['server_csr']
server_cert  = node['openvpn']['easyrsa']['server_cert']

execute 'easyrsa-init-pki' do
  cwd "/etc/openvpn/easy-rsa/"
  command './easyrsa init-pki'
  not_if { ::File.exist?("#{key_dir}") }
end

template "#{key_dir}/vars" do
  source "vars.erb"
  owner 'root'
  group node['root_group']
  mode  '0755'
end

org = node['openvpn']['key']['ca_common_name']
execute 'easyrsa-initca' do
  cwd "/etc/openvpn/easy-rsa/"
  command "EASYRSA_BATCH=1 EASYRSA_DN='org' EASYRSA_REQ_CN='#{org}' ./easyrsa build-ca nopass"
  not_if { ::File.exist?("#{ca_crt}") }
end

execute 'easyrsa-dh' do
  cwd "/etc/openvpn/easy-rsa/"
  command './easyrsa gen-dh'
  not_if { ::File.exist?("#{dh}") }
end

execute 'easyrsa-crl' do
  cwd "/etc/openvpn/easy-rsa/"
  command './easyrsa gen-crl'
  not_if { ::File.exist?("#{crl}") }
end

execute 'easyrsa-crl' do
  cwd "/etc/openvpn/easy-rsa/"
  command './easyrsa gen-req server nopass --batch'
  not_if { ::File.exist?("#{crl}") }
end

# TODO: we could use ./easyrsa build-server-full server nopass batch
#  to create the req and the cert in one go
execute 'easyrsa-server-csr' do
  cwd "/etc/openvpn/easy-rsa/"
  command './easyrsa gen-req server nopass batch'
  not_if { ::File.exist?("#{server_csr}") }
end
execute 'easyrsa-server-crt' do
  cwd "/etc/openvpn/easy-rsa/"
  command './easyrsa sign-req server server batch'
  not_if { ::File.exist?("#{server_cert}") }
end




