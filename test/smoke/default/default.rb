################################################################################
# SPDX-FileCopyrightText: 2019 SAP
#                                                                              #
# SPDX-License-Identifier: Apache-2.0
################################################################################

describe file('/tmp/kitchen/ohai/plugins/installed_applications.rb') do
  it { should exist }
  its('content') { should match /Copyright 2019 SAP/ }
end

describe file('/tmp/kitchen/ohai/plugins/sap_sid.rb') do
  it { should exist }
  its('content') { should match /Copyright 2019 SAP/ }
end
