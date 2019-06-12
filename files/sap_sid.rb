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

Ohai.plugin :Sap do
  provides 'sap'
  depends 'kernel/machine', 'kernel'
  depends 'platform_family'
  depends 'ipaddress', 'network/interfaces'
  depends 'filesystem'

  ############################# find network aliases #############################
  # These methods are all used to collect the network aliases                    #
  ################################################################################

  def getips
    array = []
    network[:interfaces].each do |_interface, properties_array|
      properties_array['addresses'].each do |address, address_info|
        next unless address_info['family'] == 'inet' # Only get IPv4 addresses
        array << address
      end
    end
    array
  end

  def getalias(ip)
    dns_name_cmd = "nslookup #{ip} | grep \"name =\" | awk '{print $4}'"
    shell_out(dns_name_cmd).stdout.chomp
  end

  def aliasnames
    alias_names = {}
    ips = getips
    ips.each do |ip|
      next if ip == ipaddress || ip =~ /^127.0.0.\d/ # skip the primary IP, because it doesn't have an alias, its just the hostname
      alias_names[ip] = getalias(ip)
    end
    alias_names
  end

  ################################# SID Methods ##################################
  # These methods are all used to collect the SIDs from differente locations on  #
  # Windows and Linux systems.  In addition to collecting the SIDs, they also    #
  # need to be validated to ensure that they are currently active, and not part  #
  # of an old installtion.                                                       #
  ################################################################################
  # method to extract platform from the system
  def win?
    platform_family.include?('indows')
  end

  # return sid depending on the platform
  def ret_sid
    win? ? win_sid : valid_sid
  end

  # return sid on linux hosts
  def sid_linux
    cmd = "ls -d /sapmnt/*" # do a ls with directories to get /sapmnt/ABC pattern
    cmd += "| awk -F / '{print $3}'" # Print only the possible SID on the system.
    shell_out(cmd).stdout.split("\n")
  end

  # validate the sid on linux hosts if exitstatus is == 0 for disp+work command
  # if command is not present exitstatus != 0 and we are not passing that SID
  # since disp+work is not a valid command on <sid>adm user
  def valid_disp_plus_work(sid)
    cmd = "su #{sid.downcase}adm -l -c 'disp+work' 2>/dev/null"
    exit_stat = shell_out(cmd).exitstatus
    exit_stat == 0
  end

  # validation of user administrator for database
  def valid_sid
    array = []
    sid_linux.each do |sid|
      check = sid.chomp.downcase << 'adm'
      cmd = "cat /etc/passwd | awk -F : '$1==\"#{check}\" {print $1}'" # validate sid on folders with admin user in passwd file
      sid_array = shell_out(cmd).stdout.chomp # run command and removing unwanted charso
      array.push(sid) if sid_array.eql?(check) && valid_disp_plus_work(sid) # push the matching sid's to array
    end
    array
  end

  # This method eliminates duplicated SID's and removes not vaid sid.
  def win_sid
    check_sid_windows_reg & check_sid_windows_serv & check_sid_windows_drv
  end

  def check_sid_windows_reg
    require 'win32/registry'
    access = Win32::Registry::KEY_READ
    key_name = 'SOFTWARE\\SAP' # registry key path to search
    ret_array = []
    Win32::Registry::HKEY_LOCAL_MACHINE.open(key_name, access) do |reg_key|
      reg_key.each_key do |key, _v|
        next if key =~ /TDC|SAP|HostControl|DAA|GOS/ # skipping known patterns
        ret_array.push(key) if key =~ /^[A-Z][A-Z|0-9][A-Z|0-9]$/ # pushing matching sid's patterns like UIP to array
      end
    end
    ret_array
  end

  def check_sid_windows_serv
    ret_array = []
    sap_array = []
    cmd = 'powershell.exe -Command "Get-Service *sap* | select-object -Property DisplayName'
    sap_services = shell_out(cmd).stdout
    sap_services = sap_services.delete(' ').split(/\r\n/) # removing \r\n patterns from string
    sap_services.each do |sap_strg| # Fill the sap_array with valid instance names
      sap_array << sap_strg if sap_strg =~ /^SAP[A-Z][A-Z|0-9][A-Z|0-9]_[0-9][0-9]$/ # adding SAP<SID>_00 pattern to array
    end
    sap_array.each do |sid| # extract the sid from the instance name
      ret_array << sid.split('SAP').last.split(/_[0-9][0-9]/).first # split <SID> from string
    end
    ret_array.uniq
  end

  def check_sid_windows_drv
    ret_array = []
    cmd0 = "Get-ChildItem #{find_data_disk_win}/usr/sap | Select-Object -Property Name"
    cmd = "powershell.exe -Command \"#{cmd0}\"" # command to get the SID from folders
    output = shell_out(cmd).stdout
    folders = output.delete(' ').split(/\r\n/) # removing return and new line from the string
    folders.each do |sid_folder|
      ret_array << sid_folder if sid_folder =~ /^\D\w\w$/ # constructing the array to return SID's
    end
    ret_array.uniq
  end

  ####################### Instance number & type Methods #######################
  # These methods are used to collect the instance number of the SID's, also   #
  # the type of the instance if it is JAVA, ABAP or DUALSTACK (DS)             #
  ##############################################################################

  def getips
    array = []
    network[:interfaces].each do |_interface, properties_array|
      properties_array['addresses'].each do |address, address_info|
        next unless address_info['family'] == 'inet' # Only get IPv4 addresses
        array << address
      end
    end
    array
  end

  # method to extract DATA disk from windows systems.
  def find_data_disk_win
    data_disk = ''
    if win?
      filesystem.to_a.each do |fs_letter, _fs_properties| # this will iterate trough each letter of the aphabeth
        next unless ::Dir.exist?("#{fs_letter}/usr/sap") # will skipp all directories but /usr/sap/<SID>
        data_disk = fs_letter
      end
    end
    data_disk # return a letter A-Z on win, or '' on nix
  end

  # avoiding duplicated code since this is used a few times
  def usr_sap_path(sid)
    mypath = find_data_disk_win
    mypath += "/usr/sap/#{sid.upcase}"
    mypath
  end

  # Method to extract system type; ABAP, JAVA or DualStack (DS)
  def system_type_lookup(sid)
    system_type, ci_instance_number = ''
    sid_usr_dir = usr_sap_path(sid)
    sub_folders = ::Dir.entries(sid_usr_dir)
    sub_folders.each do |sub_dir|
      if sub_dir =~ /^DVEBMGS\d{1,2}/ # Matches strings that start with DVEBMGS followed by 2 digits
        ci_instance_number = sub_dir[-2..-1] # Grab the central instance number while we're here
        system_type = ::Dir.exist?("#{sid_usr_dir}/#{sub_dir}/j2ee") ? 'DS' : 'ABAP' # if DVEBMGS78/j2ee exist is dualstack
      elsif sub_dir =~ /^J\d{1,2}/ # if there is a folder that start with J and has two more digits like J16
        ci_instance_number = sub_dir[-2..-1]
        system_type = 'JAVA' # Then system_type = java
      end
    end
    [system_type, ci_instance_number]
  end

  # Method to extract instance number and type from folder names like (A)SCS##
  def instance_number_lookup(sid)
    sid_usr_dir = usr_sap_path(sid)
    if ::Dir.exist?(sid_usr_dir)
      sub_folders = ::Dir.entries(sid_usr_dir)
      sub_folders.each do |sub_folder|
        return [sub_folder[-2..-1], 'ASCS_Instance_Number'] if sub_folder =~ /ASCS(.*)/
        return [sub_folder[-2..-1], 'SCS_Instance_Number'] if sub_folder =~ /SCS(.*)/
      end
    end
    ['', '']
  end

  ##################################### DB type ################################
  # These methods are used to collect the instance number of the SID's, also   #
  # the type of the instance if it is JAVA, ABAP or DUALSTACK (DS)             #
  ##############################################################################

  # Method to collect the the administrator user for the database in the system
  # for linux hosts
  def get_nix_db_type(sid)
    shell_out("su #{sid.downcase}adm -l -c 'env | grep dbms_type | cut -d'=' -f2' || ''").stdout.chomp || ''
  end

  # in windows hosts
  def get_db_user_prof_reg(sid)
    # actual command to collect the user string (possibly better way to get users on Windows.)
    cmd = "powershell.exe -Command \"Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList\\*'| Select-Object -Property PSChildName, ProfileImagePath\"|findstr #{sid.downcase}adm"
    sidadm_user_string = shell_out(cmd).stdout
    sidadm_user_string.split(' ')[0] # Get everything before 1st space
  end

  # method to extract the type of database from the profile obtained in the
  # get_db_user_prof_reg method
  def get_win_db_type(sid)
    cmd = "powershell.exe -Command \"Get-ItemProperty -Path 'Registry::HKEY_USERS\\#{get_db_user_prof_reg(sid)}\\Environment'| Select-Object -Property DBMS_TYPE\""
    shell_out(cmd).stdout.split[2] # Drop the headers from the output
  end

  # Get DB in different ways depending on platform
  def ret_db(sid)
    win? ? get_win_db_type(sid) : get_nix_db_type(sid)
  end

  ##############################################################################
  # Helpers for the validate in PFL method
  def pfl_properties(sid, key)
    properties = { 'sys_type' => { lookup_item: system_type_lookup(sid), search_base: 'system/type = ' },
                   'db_type' => { lookup_item: ret_db(sid).downcase, search_base: 'dbtype = ' } }
    properties[key]
  end

  def corrupt_pfl?(file_name) # Checks if the DEFAULT.PFL for the sid is readable and valid
    ::File.exist?(file_name) &&
      ::File.read(file_name).match('Default Profile DEFAULT')
  end

  # Method to verify system_type_lookup is right in DEFAULT.PFL
  def validate_in_default_pfl(sid, value)
    profile_file = "#{usr_sap_path(sid)}/SYS/profile/DEFAULT.PFL" # path to file DEFAULT.PFL
    pfl_props = pfl_properties(sid, value)
    to_validate = pfl_props[:lookup_item]
    profile_search_string = pfl_props[:search_base] + to_validate
    return to_validate if !corrupt_pfl?(profile_file) && ::File.read(profile_file).match(profile_search_string)
    'Bad PFL'
  end

  ###########################################

  ### method to find central instance number
  def ci_instance_number(sid)
    ci = nil
    sid_usr_dir = usr_sap_path(sid)
    sub_directories = ::Dir.entries(sid_usr_dir) # setting /usr/sap/SID path
    sub_directories.each do |sub_dir|
      ci = sub_dir[-2..-1] if sub_dir =~ /^DVEBMGS\d{1,2}/ # searching foder pattern DVEBMGS09
    end
    ci
  end

  ## Method to find data in SAP system profile
  def find_in_profile(sid, matcher)
    kernel = ''
    cmd = win? ? "#{usr_sap_path(sid)}/SYS/exe/uc/NTAMD64/disp+work" : "su #{sid.downcase}adm -l -c 'disp+work'" # command depending if it is windows or linux
    cleanner = win? ? "\r\n" : "\n" # cleaning output depending on OS
    line_array = shell_out(cmd).stdout.split(cleanner)
    line_array.each do |line|
      next unless line =~ matcher # wanted line, kernel release      751
      kernel = line.split(' ')[-1] # select last element of the string, 751
    end
    kernel
  end

  collect_data(:default) do
    sap(Mash.new)
    sap[:SID] = ret_sid
    ret_sid.each do |sid|
      instance_number, type = instance_number_lookup(sid)
      sap[sid.upcase] = {
        type => instance_number,
        'dbtype' => ret_db(sid),
        'system_type' => system_type_lookup(sid)[0],
        'CI_Instance_Number' => system_type_lookup(sid)[1],
        'kernel_release' => find_in_profile(sid, /^kernel release/),
        'patch_number' => find_in_profile(sid, /^patch number/),
        'kernel_make_variant' => find_in_profile(sid, /^kernel make variant/),
      }
      sap[:aliasnames] = aliasnames
    end
  end
end

