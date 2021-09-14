# chef-ohai-plugins

When using Chef to manage your infrastructure, you may find that you need some
detailed information about the current state of machine's applications.  You
might also find that you'd like to be able to collect and analyse such data; for
example, one might want to list all the servers with a specific version of an
application.

When you are working with servers that have SAP systems installed, you may want
additional information about those systems, like their system IDs.

This repo contains custom ohai plugins to do just that; collect information
about installed applications and SAP systems.

[Ohai](https://docs.chef.io/ohai.html) is a tool that is used to collect system
configuration data, which is provided to the Chef Infra Client for use within
cookbooks. Ohai is run by the Chef Infra Client at the beginning of every Chef
run to determine system state.

[Chef Infra](https://docs.chef.io/chef_overview.html) is a powerful automation
platform that transforms infrastructure into code. Whether you’re operating in
the cloud, on-premises, or in a hybrid environment, Chef automates how
infrastructure is configured, deployed, and managed across your network, no
matter its size.

## Requirements

These plugins are for use with ohai.
[Ohai](https://rubygems.org/gems/ohai/versions/14.8.11) _can_ be installed
standalone, however it is more common that you'll use this as a part of the
[Chef Infra Client](https://downloads.chef.io/).

## Download and Installation

We've laid out this repo as a cookbook, so that you can use it to install the
plugins. If you'd like to distribute them manually, you'll find the plugins in
the root of the `/files/` directory.

1. Simply put the desired ohai plugins in your system's ohai directory
1. Use the Chef [ohai](https://supermarket.chef.io/cookbooks/ohai) cookbook to
install the plugins
1. Use this cookbook to install the plugins

## Available Plugins

### sap_sid

Not a BASIS consultant? Do not worry! This custom Ohai plugin will retrieve
every hidden detail of an SAP system installation.

Get insight into which support package, kernel release or even database you are
running on.

Give it a try, by running `>ohai -d ./files/ sap`

`sap_sid` exposes:

- System ID
- DB Platform: SAP HANA, IBM DB6, SAP MaxDB, Oracle
- System type: J2EE, ABAP or Dual Stack
- Central Instance number
- Kernel and patch level release along its kernel variant
- Alias names for the hosted SAP system

### installed_applications

Get the applications installed on your system, along with various metadata like
versions, install paths, and how the application was detected.

*NOTE*: Chef 14 includes `node['packages']` which provides _basic_ information
about the applications and packages. This is designed to give more details.

## Configuration

Though ohai plugins are not configurable, we do encourage any contributions to
these plugins that might make them more useful, so long as existing
functionality is maintained.

## Contributions

Contributions are welcomed, and encouraged.  Please use the below as a guideline
for your input.

1. Fork the cookbook
1. Document your planned change
1. Write your test criteria, and add a suite to the [kitchen](.kitchen.yml) file
if needed.
1. Write and test your changes
1. Submit a pull request 
1. Sit back and wait for your awesome code to be merged

## Support

If you require support, please reach out or raise an
[issue](https://github.com/SAP/chef-ohai-plugins/issues).

- [Dan-Joe Lopez](mailto:Dan-Joe.Lopez@sap.com)
- [Juan Carlos Martinez](mailto:Juan.Martinez01@sap.com)

## License

Copyright 2016-2021 SAP SE or an SAP affiliate company and chef-ohai-plugins contributors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Detailed information including third-party components and their licensing/copyright information is available [via the REUSE tool](https://api.reuse.software/info/github.com/SAP/chef-ohai-plugins-chef-cookbook).
