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

Ohai.plugin(:InstalledApplications) do
  provides 'installed_applications'
  depends 'kernel/machine'
  depends 'platform'

  # There are several methods here that enable the detection of the installed
  # versions on Windows and Linux.

  def registered_applications(key_name = nil)
    if key_name.nil?
      arch_reg_search # this is only hit the 1st time
    else
      require 'win32/registry'
      access = Win32::Registry::KEY_READ

      ret_hash = {}
      Win32::Registry::HKEY_LOCAL_MACHINE.open(key_name, access) do |reg_key|
        ret_hash.merge!(app_info(reg_key))
        reg_key.each_key { |sub_key_name, _somethingimnotusing| ret_hash.merge!(registered_applications(key_name + '\\' + sub_key_name)) }
      end
      ret_hash
    end
  end

  def arch_reg_search
    installed = registered_applications('Software\Microsoft\Windows\CurrentVersion\Uninstall')
    installed.merge(registered_applications('Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')) if kernel[:machine].include?('64')
  end

  def app_info(key)
    reg_path = key.name
    reg_id = reg_path.split('\\')[-1]
    return {} if reg_id == 'Uninstall'
    registry_hash = { 'reg_id' => reg_id, 'reg_path' => reg_path }
    key.each do |name, _type, data|
      registry_hash.merge!(name => data)
    end
    title = reg_no_value(key, 'DisplayName') ? reg_id : key['DisplayName']
    { title => registry_hash }
  end

  def reg_no_value(key, value)
    # the registry_key class doen't return nil if a value is not present, this does...
    data = begin
            key[value]
          rescue
            nil
          end
    data.nil?
  end

  def rpm_packages
    cmd = 'rpm -qa'
    apps = shell_out(cmd).stdout
    packages = {}
    apps.each_line do |app|
      # => libssh2-1.4.3-10.el7_2.1.x86_64
      # Everything before the first digit-followed-by-a-dash, is the name
      name = app.split(/-\d/)[0]
      app = app.gsub(name, '')[1..-1] # => 1.4.3-10.el7_2.1.x86_64
      app = app.nil? ? ' ' : app

      # Everything before the 1st character is the version
      ver = app.split(/.[A-z]/)[0]
      app = app.gsub(ver, '')[1..-1] # => el7_2.1.x86_64
      app = app.nil? ? ' ' : app

      # Everything after the last '.' is the architecture
      arch = app.split('.')[-1].chomp
      app = app.chomp.gsub(arch, '')[0...-1] # => el7_2.1
      app = app.nil? ? ' ' : app

      # all that's left is the repo
      repo = app

      packages[name] = {}
      packages[name]['architecture'] = arch
      packages[name]['repo'] = repo
      packages[name]['version'] = ver
      packages[name]['detection'] = 'rpm'
    end
    packages
  end

  def apt_packages
    packages = {}
    cmd = 'apt list --installed'
    apps = shell_out(cmd).stdout
    apps.each_line do |app|
      next if app =~ /Listing/
      app = app.split
      app_info = app[0].split('/')
      name = app_info[0]
      packages[name] = {}
      packages[name]['providers'] = app_info[1].split(',')
      packages[name]['version'] = app[1]
      packages[name]['platform'] = app[2]
      packages[name]['state'] = app[3]
      packages[name]['detection'] = 'apt'
    end
    packages
  end

  def opt_apps
    ::Dir.entries('./opt') - ['.', '..']
  end

  def platform_packages
    case platform
    when 'windows'
      registered_applications
    when 'ubuntu'
      apt_packages
    when 'rhel', 'suse', 'redhat'
      rpm_packages
    end
  end

  collect_data(:default) do
    installed_applications Mash.new

    packages = platform_packages
    opt_apps.each { |app| packages[app] = { 'detection' => '/opt' } } unless platform == 'windows'

    packages.each do |name, info|
      installed_applications[name] = info
    end
  end
end
