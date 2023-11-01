# openvpn-easyrsa Cookbook

[![ci](https://github.com/EugenMayer/openvpn/actions/workflows/ci.yml/badge.svg)](https://github.com/EugenMayer/openvpn/actions/workflows/ci.yml)
[![Cookbook Version](https://img.shields.io/cookbook/v/openvpn.svg)](https://supermarket.chef.io/cookbooks/openvpn)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

Installs openvpn and easy-rsa and uses the latter to configure the ca, server, dh and all the other bits,
so you can start the server right away.

Using easy-rsa you can also add user-certificates fairly easy - `./easy-rsa build-client-full client1`.

The layout and deployment also offers an integration with the Certificate/User management tool https://github.com/flant/ovpn-admin

If you upgrade from the sous-chef `openvpn` cookbook or consider so, read the CHANGELOG.md - we have massive changes
and you will need to start your pki from scratch - there is no other upgrade path.

# Easy-rsa

You can use easy-rsa after the deployment to run any renewals or easy-rsa specific commands in

```bash
cd /etc/openvpn/easy-rsa
./easy-rsa show-ca
./easy-rsa gen-crl

# create a client certificate
./easy-rsa build-client-full client1
```

# Ovpn-Admin

The layout deployed by this cookbook and the compliance against easy-rsa offers a sleek integration with https://github.com/flant/ovpn-admin - a GUI to maintain, add and revoke user certificates (and download the client config).

You need to configure this variables to be compatible out of the box

```
EASYRSA_PATH=/etc/openvpn/easy-rsa/pki
OVPN_INDEX_PATH=/etc/openvpn/easy-rsa/pki/index.txt
```

# Attributes

These attributes are set by the cookbook by default.

- `node['openvpn']['client_cn']` - The client's Common Name used with the `openvpn::client` recipe (essentially a standalone recipe) for the client certificate and key.
- `node['openvpn']['type']` - Valid values are 'client' (currently a work in progress), 'server' or 'server-bridge'. Default is 'server' and it will create a routed IP tunnel, and use the 'tun' device. 'server-bridge' will create an ethernet bridge and requires a tap0 device bridged with the ethernet interface, and is beyond the scope of this cookbook.
- `node['openvpn']['subnet']` - Used for server mode to configure a VPN subnet to draw client addresses. Default is 10.8.0.0, which is what the sample OpenVPN config package uses.
- `node['openvpn']['netmask']` - Netmask for the subnet, default is 255.255.0.0.
- `node['openvpn']['gateway']` - FQDN for the VPN gateway server. Default is `node['fqdn']`.
- `node['openvpn']['push_routes']` - Array of routes to to push to clients (as `push` statements) in the server.conf, e.g. '192.168.0.0 255.255.255.0'. Default is empty.
- `node['openvpn']['push_options']` - Array of options to push to clients in the server.conf, e.g. [["dhcp-option DNS", ["8.8.8.8"]]]. Default is empty.
- `node['openvpn']['configure_default_server']` - Boolean. Set this to false if you want to create all of your "conf" files with the LWRP.
- `node['openvpn']['git_package']` - Boolean. Whether to use the `openvpn-git` package (Arch Linux only, default false).
- `node['openvpn']['server_verification']` - Server certificate verification directive, can be anything mentioned [in official doc](https://openvpn.net/index.php/open-source/documentation/howto.html#mitm). By default `nil`.
- `node['openvpn']['config']['local']` - IP to listen on, defaults to `node['ipaddress']`
- `node['openvpn']['config']['proto']` - Valid values are 'udp' or 'tcp', defaults to 'udp'.
- `node['openvpn']['config']['port']` - Port to listen on, defaults to '1194'.
- `node['openvpn']['config']['log']` - Server log file. Default /var/log/openvpn.log
- `node['openvpn']['config']['script-security']` - Script Security setting to use in server config. Default is 1\. The "up" script will not be included in the configuration if this is 0 or 1\. Set it to 2 to use the "up" script.

The following attributes are used to populate the `easy-rsa` vars file. Defaults are the same as the vars file that ships with OpenVPN.

- `node['openvpn']['key']['ca_expire']` - In how many days should the root CA key expire - `CA_EXPIRE`.
- `node['openvpn']['key']['expire']` - In how many days should certificates expire - `KEY_EXPIRE`.
- `node['openvpn']['key"]['size']` - Default key size, set to 2048 if paranoid but will slow down TLS negotiation performance - `KEY_SIZE`.

The following are for the default values for fields place in the certificate from the vars file. Do not leave these blank.

- `node['openvpn']['key']['country']` - `KEY_COUNTRY`
- `node['openvpn']['key']['province']` - `KEY_PROVINCE`
- `node['openvpn']['key']['city']` - `KEY_CITY`
- `node['openvpn']['key']['org']` - `KEY_ORG`
- `node['openvpn']['key']['email']` - `KEY_EMAIL`

The following lets you specify the message digest used for generating certificates by OpenVPN

- `node['openvpn']['key']['message_digest']` - Default is `sha256` for a high-level of security.

The CRL will be generated, and refreshed automatically, allowing you to
revoke certificates

- `node['openvpn']['key']['crl_expire']` - In how many days should the CRL expire? Will be refreshed after half of this time

Configure a shared tls key - will be located at `/etc/openvpn/easy-rsa/pki/ta.key`

- `node['openvpn']['tls']['generate_tls_shared_key']` - set to true to configure a shared tls key (tls-auth)

## Recipes

### `openvpn::default`

Installs the OpenVPN package only.

### `openvpn::install`

Installs the OpenVPN package only.

### `openvpn::server`

Installs and configures OpenVPN as a server. Installs easy-rsa and configures all needed certificates for the server.

### `openvpn::service`

Manages the OpenVPN system service (there is no need to use this recipe directly in your run_list).

### Usage

Create a role for the OpenVPN server. See above for attributes that can be entered here.

```ruby
name "openvpn"
description "The server that runs OpenVPN"
run_list("recipe[openvpn::server]")
override_attributes(
  "openvpn" => {
    "gateway" => "vpn.example.com",
    "subnet" => "10.8.0.0",
    "netmask" => "255.255.0.0",
    "key" => {
      "country" => "US",
      "province" => "CA",
      "city" => "SanFrancisco",
      "org" => "Fort-Funston",
      "email" => "me@example.com"
    }
  }
)
```

**Note**: If you are using a Red Hat EL distribution, the EPEL repository is automatically enabled by Chef's `recipe[yum::epel]` to install the openvpn package.

To push routes to clients, add `node['openvpn']['push_routes]` as an array attribute, e.g. if the internal network is 192.168.100.0/24:

```ruby
override_attributes(
  "openvpn" => {
    "push_routes" => [
      "192.168.100.0 255.255.255.0"
    ]
  }
)
```

To push other options to clients, use the `node['openvpn']['push_options']` attribute and set an array of hashes or strings. For example:

```ruby
override_attributes(
  "openvpn" => {
    "push_options" => {
      "dhcp-option" => [
        "DOMAIN domain.local",
        "DOMAIN-SEARCH domain.local"
      ],
      "string-option" => "string value"
    }
  }
)
```

This will render a config file that looks like:

```ruby
push "dhcp-option DOMAIN domain.local"
push "dhcp-option DOMAIN-SEARCH domain.local"
push "string-option string value"
```

This cookbook also provides an 'up' script that runs when OpenVPN is started. This script is for setting up firewall rules and kernel networking parameters as needed for your environment. Modify to suit your needs, upload the cookbook and re-run chef on the openvpn server. For example, you'll probably want to enable IP forwarding (sample Linux setting is commented out). The attribute `node['openvpn']["script_security"]` must be set to 2 or higher to use this otherwise openvpn server startup will fail.

#S Resources

### openvpn_config

Given a hash of config options it writes out individual openvpn config files.

If you don't want to use the default "server.conf" from the default recipe, set `node['openvpn']["configure_default_server"]` to false, then use this resource to configure things as you like.

#### Example

.pem files should be provided before (e.g.: `cookbook_file`)

```ruby
openvpn_conf 'myvpn' do
  config({
    'client' => '',
    'dev' => 'tun',
    'proto' => 'tcp',
    'remote' => '1.2.3.4 443',
    'cipher' => 'AES-128-CBC',
    'tls-cipher' => 'DHE-RSA-AES256-SHA',
    'auth' => 'SHA1',
    'nobind' => '',
    'resolv-retry' => 'infinite',
    'persist-key' => '',
    'persist-tun' => '',
    'ca' => "/etc/openvpn/myvpn/ca.pem",
    'cert' => "/etc/openvpn/myvpn/cert.pem",
    'key' => "/etc/openvpn/myvpn/key.pem",
    'comp-lzo' => '',
    'verb' => false,
    'auth-user-pass' => "/etc/openvpn/myvpn/login.conf",
  })
end

# for systemd based systems
service 'openvpn@myvpn' do
  action [:start, :enable]
end
```

## Customizing Server Configuration

To further customize the server configuration, there are two templates that can be modified in this cookbook.

- templates/default/server.conf.erb
- templates/default/server.up.sh.erb

The first is the OpenVPN server configuration file. Modify to suit your needs for more advanced features of [OpenVPN](http://openvpn.net). The second is an `up` script run when OpenVPN starts. This is where you can add firewall rules, enable IP forwarding and other OS network settings required for OpenVPN. Attributes in the cookbook are provided as defaults, you can add more via the openvpn role if you need them.

## SSL Certificates

Some of the easy-rsa tools are copied to /etc/openvpn/easy-rsa to provide the minimum to generate the certificates using the default and users recipes. We provide a Rakefile to make it easier to generate client certificate sets if you're not using the data bags above. To generate new client certificates you will need `rake` installed (either as a gem or a package), then run:

```shell
cd /etc/openvpn/easy-rsa
source ./vars
easyrsa show-ca
```

# Credits

The work here is based on https://github.com/sous-chefs/openvpn
See all the old contributors, bakers and sponsors there.
