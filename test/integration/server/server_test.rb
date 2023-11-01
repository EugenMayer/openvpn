# this is done in a similar fashion to
# https://github.com/xhost-cookbooks/openvpn/blob/master/recipes/service.rb

if (os[:family] == 'redhat' && os[:release].to_i < 8) ||
   (os[:name] == 'debian') ||
   (os[:name] == 'ubuntu') ||
   (os[:name] == 'amazon')
  describe service('openvpn@server') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end
elsif (os[:family] == 'redhat' && os[:release] >= '8') || os[:family] == 'fedora'
  describe service('openvpn-server@server') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end
else
  describe service('openvpn') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end
end

conf_location = if (os[:family] == 'redhat' && os[:release] >= '8') || os[:family] == 'fedora'
                  '/etc/openvpn/server/server.conf'
                else
                  '/etc/openvpn/server.conf'
                end

describe file("#{conf_location}") do
  its('content') { should include 'push "dhcp-option DOMAIN local"' }
  its('content') { should include 'push "dhcp-option DOMAIN-SEARCH local"' }
  its('content') { should include 'push "route 192.168.10.0 255.255.255.0"' }
  its('content') { should include 'push "route 10.12.10.0 255.255.255.0"' }
  its('content') { should include 'tls-auth /etc/openvpn/easy-rsa/pki/ta.key 0' }
end

describe command('openssl crl -in /etc/openvpn/easy-rsa/pki/crl.pem -noout -issuer') do
  its('stdout') do
    should match(/.*emailAddress.*=.*admin@foobar.com/)
    should match(/.*O.*=.*Fort Funston.*/)
    should match(/.*OU.*=.*Fort Funston.*/)
    should match(/.*CN.*=.*Our IT.*/)
  end
end

describe file('/etc/openvpn/easy-rsa/easyrsa') do
  it { should be_file }
end

describe file('/etc/openvpn/easy-rsa/pki/vars') do
  it { should be_file }
end

describe file('/etc/openvpn/easy-rsa/pki/dh.pem') do
  it { should be_file }
end

describe file('/etc/openvpn/easy-rsa/pki/crl.pem') do
  it { should be_file }
end

describe file('/etc/openvpn/easy-rsa/pki/ca.crt') do
  it { should be_file }
end

describe file('/etc/openvpn/easy-rsa/pki/private/ca.key') do
  it { should be_file }
end

describe file('/etc/openvpn/easy-rsa/pki/reqs/server.req') do
  it { should be_file }
end

describe file('/etc/openvpn/easy-rsa/pki/issued/server.crt') do
  it { should be_file }
end

describe file('/etc/openvpn/easy-rsa/pki/private/server.key') do
  it { should be_file }
end

describe file('/etc/openvpn/easy-rsa/pki/ta.key') do
  it { should be_file }
end

