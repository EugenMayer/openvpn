require 'spec_helper'

describe 'openvpn::server' do
  context 'When push_options & push_routes are set, on Ubuntu' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(step_into: ['openvpn_conf']) do |node|
        node.override['openvpn']['push_options'] = {
          'dhcp-options' => ['DOMAIN local',
                             'DOMAIN-SEARCH local'],
        }
        node.override['openvpn']['push_routes'] = [
          '192.168.10.0 255.255.255.0', '10.12.10.0 255.255.255.0'
        ]
      end.converge(described_recipe)
    end

    before do
      allow(::File).to receive(:mtime).with('/etc/openvpn/keys/index.txt').and_return(Time.now - 31 * 60 * 24)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'makes a server.conf from template with dhcp options' do
      expect(chef_run).to render_file('/etc/openvpn/server.conf')
        .with_content('push "dhcp-options DOMAIN local"')
      expect(chef_run).to render_file('/etc/openvpn/server.conf')
        .with_content('push "dhcp-options DOMAIN-SEARCH local"')
    end

    it 'makes a server.conf from template with multiple push routes' do
      expect(chef_run).to render_file('/etc/openvpn/server.conf')
        .with_content('push "route 192.168.10.0 255.255.255.0"')
      expect(chef_run).to render_file('/etc/openvpn/server.conf')
        .with_content('push "route 10.12.10.0 255.255.255.0"')
    end
  end
end
