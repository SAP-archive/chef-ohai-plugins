################################################################################
# Copyright 2019 SAP                                                           #
#                                                                              #
# Licensed under the Apache License, Version 2.0 (the "License");              #
# you may not use this file except in compliance with the License.             #
# You may obtain a copy of the License at                                      #
#                                                                              #
#   http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                              #
# Unless required by applicable law or agreed to in writing, software          #
# distributed under the License is distributed on an "AS IS" BASIS,            #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.     #
# See the License for the specific language governing permissions and          #
# limitations under the License.                                               #
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
