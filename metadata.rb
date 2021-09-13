################################################################################
# SPDX-FileCopyrightText: 2019 SAP
#                                                                              #
# SPDX-License-Identifier: Apache-2.0
################################################################################

name             'sapohai'
maintainer       'SAP DevOps CoE'
maintainer_email 'Dan-Joe.Lopez@sap.com'
license          'Apache-2.0'
description      'Installs SAP\'s ohai plugins'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.1'

issues_url       'https://github.com/SAP/chef-ohai-plugins/issues' if respond_to?(:issues_url)
source_url       'https://github.com/SAP/chef-ohai-plugins' if respond_to?(:source_url)
chef_version     '>= 12' if respond_to?(:chef_version)

%w( redhat suse ubuntu windows ).each do |os|
  supports os
end

depends 'ohai', '~> 5.2'
