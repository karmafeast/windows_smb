# windows smb share management
# CAFS not supported in this implementation
# permission changes will delete and recreate the share - control your implementation
define windows_smb::manage_smb_share (
  $ensure = 'present',
  $smb_share_name                    = $title,
  $smb_share_directory               = undef,
  $smb_share_comments                = 'puppet generated smb share',
  $smb_share_concurrent_user_limit   = 0,
  $smb_share_cache                   = 'None',
  $smb_share_encrypt_data            = false,
  $smb_share_folder_enum_mode        = 'AccessBased',
  $smb_share_temporary               = false,
  $smb_share_access_full             = [],
  $smb_share_access_change           = [],
  $smb_share_access_read             = [],
  $smb_share_access_deny             = [],
  $smb_share_autoinstall_branchcache = false) {
  validate_re($ensure, '^(present|absent|purge)$', 'ensure must be one of \'present\', \'absent\', \'purge\'')
  validate_integer($smb_share_concurrent_user_limit, 4294967295, 0)
  validate_bool($smb_share_encrypt_data)
  validate_bool($smb_share_temporary)
  validate_bool($smb_share_autoinstall_branchcache)
  validate_re($smb_share_cache, '^(None|Manual|Programs|Documents|BrancheCache)$', 'smb_share_cache must be one of \'None\', \'Manual\', \'Programs\', \'Documents\', \'BrancheCache\''
  )
  validate_re($smb_share_folder_enum_mode, '^(AccessBased|Unrestricted)$', 'smb_share_folder_enum_mode must be one of \'AccessBased\', \'Unrestricted\''
  )
  validate_array($smb_share_access_full)
  validate_array($smb_share_access_change)
  validate_array($smb_share_access_read)
  validate_array($smb_share_access_deny)

  # TODO: take only UPNs due to potential for ambiguity on netbios\username in multi-domain environments

  # fail if no folder target for share or passed data in param is not a string
  if ($smb_share_directory == undef) {
    fail('smb_share_directory specified as undef')
  } else {
    validate_string($smb_share_directory)
  }

  if ($smb_share_comments == undef) {
    fail('explicit pass of undef as param smb_share_comments')
  } else {
    validate_string($smb_share_comments)
  }

  # if have assigned no permissions whatsoever then fail
  if (empty($smb_share_access_full) and empty($smb_share_access_change) and empty($smb_share_access_read) and empty(
  $smb_share_access_deny)) {
    fail('this module does not support creation of shares with no share permissions assigned, assign values to at least one of $smb_share_access_full, $smb_share_access_change, $smb_share_access_read, $smb_share_access_deny'
    )
  }

  # check for repeats, for share permissions there can be only one ACE per principal.
  if (empty($smb_share_access_full)) {
    $access_full_join          = ''
    $access_full_create_string = ''
  } else {
    if (!empty($smb_share_access_change)) {
      $smb_share_access_full.each |String $item| {
        if (member($smb_share_access_change, $item)) {
          fail("${item} member of smb_share_access_full and smb_share_access_change")
        }
      }
    }

    if (!empty($smb_share_access_read)) {
      $smb_share_access_full.each |String $item| {
        if (member($smb_share_access_read, $item)) {
          fail("${item} member of smb_share_access_full and smb_share_access_read")
        }
      }
    }

    if (!empty($smb_share_access_deny)) {
      $smb_share_access_full.each |String $item| {
        if (member($smb_share_access_deny, $item)) {
          fail("${item} member of smb_share_access_full and smb_share_access_deny")
        }
      }
    }

    $access_full_join          = join($smb_share_access_full, ',')
    $temp_full_access_str      = regsubst($access_full_join, '([,]+)', "\"\\1\"", 'G')
    $fixed_full_access_str     = "\"${temp_full_access_str}\""
    $access_full_create_string = " -FullAccess ${fixed_full_access_str}"
  }

  if (empty($smb_share_access_change)) {
    $access_change_join          = ''
    $access_change_create_string = ''
  } else {
    if (!empty($smb_share_access_full)) {
      $smb_share_access_change.each |String $item| {
        if (member($smb_share_access_full, $item)) {
          fail("${item} member of smb_share_access_change and smb_share_access_full")
        }
      }
    }

    if (!empty($smb_share_access_read)) {
      $smb_share_access_change.each |String $item| {
        if (member($smb_share_access_read, $item)) {
          fail("${item} member of smb_share_access_change and smb_share_access_read")
        }
      }
    }

    if (!empty($smb_share_access_deny)) {
      $smb_share_access_change.each |String $item| {
        if (member($smb_share_access_deny, $item)) {
          fail("${item} member of smb_share_access_change and smb_share_access_deny")
        }
      }
    }

    $access_change_join          = join($smb_share_access_change, ',')
    $temp_change_access_str      = regsubst($access_change_join, '([,]+)', "\"\\1\"", 'G')
    $fixed_change_access_str     = "\"${temp_change_access_str}\""
    $access_change_create_string = " -ChangeAccess ${fixed_change_access_str}"
  }

  if (empty($smb_share_access_read)) {
    $access_read_join          = ''
    $access_read_create_string = ''
  } else {
    if (!empty($smb_share_access_full)) {
      $smb_share_access_read.each |String $item| {
        if (member($smb_share_access_full, $item)) {
          fail("${item} member of smb_share_access_read and smb_share_access_full")
        }
      }
    }

    if (!empty($smb_share_access_change)) {
      $smb_share_access_read.each |String $item| {
        if (member($smb_share_access_change, $item)) {
          fail("${item} member of smb_share_access_read and smb_share_access_change")
        }
      }
    }

    if (!empty($smb_share_access_deny)) {
      $smb_share_access_read.each |String $item| {
        if (member($smb_share_access_deny, $item)) {
          fail("${item} member of smb_share_access_read and smb_share_access_deny")
        }
      }
    }

    $access_read_join          = join($smb_share_access_read, ',')
    $temp_read_access_str      = regsubst($access_read_join, '([,]+)', "\"\\1\"", 'G')
    $fixed_read_access_str     = "\"${temp_read_access_str}\""
    $access_read_create_string = " -ReadAccess ${fixed_read_access_str}"
  }

  if (empty($smb_share_access_deny)) {
    $access_deny_join          = ''
    $access_deny_create_string = ''
  } else {
    if (!empty($smb_share_access_full)) {
      $smb_share_access_deny.each |String $item| {
        if (member($smb_share_access_full, $item)) {
          fail("${item} member of smb_share_access_deny and smb_share_access_full")
        }
      }
    }

    if (!empty($smb_share_access_change)) {
      $smb_share_access_deny.each |String $item| {
        if (member($smb_share_access_change, $item)) {
          fail("${item} member of smb_share_access_deny and smb_share_access_change")
        }
      }
    }

    if (!empty($smb_share_access_read)) {
      $smb_share_access_deny.each |String $item| {
        if (member($smb_share_access_read, $item)) {
          fail("${item} member of smb_share_access_deny and smb_share_access_read")
        }
      }
    }

    $access_deny_join          = join($smb_share_access_deny, ',')
    $temp_deny_access_str      = regsubst($access_deny_join, '([,]+)', "\"\\1\"", 'G')
    $fixed_deny_access_str     = "\"${temp_deny_access_str}\""
    $access_deny_create_string = " -NoAccess ${fixed_deny_access_str}"
  }

  $create_string_permissions_suffix =
  "${access_full_create_string}${access_change_create_string}${access_read_create_string}${access_deny_create_string}"

  if ($smb_share_temporary) {
    $create_string_temporary_suffix = ' -Temporary'
  } else {
    $create_string_temporary_suffix = ''
  }

  if ($ensure == 'present') {
    exec { "ensure present - test-path ${smb_share_directory}":
      command   => "\$path = \"${smb_share_directory}\";if(! (test-path -path \$path)){write-host \"share target path \$(\$path) does not exist\";exit 1;}else{exit 0;}",
      unless    => "\$path = \"${smb_share_directory}\";if(! (test-path -path \$path)){write-host \"share target path \$(\$path) does not exist\";exit 1;}else{exit 0;}",
      provider  => powershell,
      logoutput => true,
    }

    if ($smb_share_cache == 'BranchCache') {
      if ($smb_share_autoinstall_branchcache) {
        exec { "check_BranchCache-${smb_share_name}":
          command   => "if((get-windowsfeature -name FS-BranchCache).installState.tostring() -eq \"Installed\"){exit 0;}if((Get-WindowsFeature -name FS-BranchCache).installState.tostring() -ne \"Available\"){write-output \"Windows feature FS-BranchCache not available...\";exit 1;}Add-WindowsFeature -name FS-BranchCache -confirm:\$false;",
          provider  => powershell,
          unless    => "if((get-windowsfeature -name FS-BranchCache).installState.tostring() -eq \"Installed\"){exit 0;}else{exit 1;}",
          require   => Exec["ensure present - test-path ${smb_share_directory}"],
          logoutput => true,
        }
      } else {
        exec { "check_BranchCache-${smb_share_name}":
          command   => "if((get-windowsfeature -name FS-BranchCache).installState.tostring() -eq \"Installed\"){exit 0;}else{write-output \"Windows feature FS-BranchCache not installed and smb_share_autoinstall_branchcache false...\";exit 1;}",
          provider  => powershell,
          unless    => "if((get-windowsfeature -name FS-BranchCache).installState.tostring() -eq \"Installed\"){exit 0;}else{exit 1;}",
          require   => Exec["ensure present - test-path ${smb_share_directory}"],
          logoutput => true,
        }

      }

      exec { "Create-${smb_share_name}":
        command   => "New-SmbShare -Name \"${smb_share_name}\" -Path \"${smb_share_directory}\" -CachingMode ${smb_share_cache} -ConcurrentUserLimit ${smb_share_concurrent_user_limit} -Description \"${smb_share_comments}\" -EncryptData \$${smb_share_encrypt_data} -FolderEnumerationMode ${smb_share_folder_enum_mode}${create_string_temporary_suffix}${create_string_permissions_suffix};",
        provider  => powershell,
        unless    => "\$smbshare = get-smbshare \"${smb_share_name}\";if(\$smbshare -eq \$null){exit 1;}else{exit 0;}",
        logoutput => true,
        require   => Exec["check_BranchCache-${smb_share_name}"],
      }

    } else {
      exec { "Create-${smb_share_name}":
        command   => "New-SmbShare -Name \"${smb_share_name}\" -Path \"${smb_share_directory}\" -CachingMode ${smb_share_cache} -ConcurrentUserLimit ${smb_share_concurrent_user_limit} -Description \"${smb_share_comments}\" -EncryptData \$${smb_share_encrypt_data} -FolderEnumerationMode ${smb_share_folder_enum_mode}${create_string_temporary_suffix}${create_string_permissions_suffix};",
        provider  => powershell,
        unless    => "\$smbshare = get-smbshare \"${smb_share_name}\";if(\$smbshare -eq \$null){exit 1;}else{exit 0;}",
        logoutput => true,
        require   => Exec["ensure present - test-path ${smb_share_directory}"],
      }
    }

    exec { "Path-${smb_share_name}":
      command   => "remove-smbshare -name \"${smb_share_name}\" -force;New-SmbShare -Name \"${smb_share_name}\" -Path \"${smb_share_directory}\" -CachingMode ${smb_share_cache} -ConcurrentUserLimit ${smb_share_concurrent_user_limit} -Description \"${smb_share_comments}\" -EncryptData \$${smb_share_encrypt_data} -FolderEnumerationMode ${smb_share_folder_enum_mode}${create_string_temporary_suffix}${create_string_permissions_suffix};",
      provider  => powershell,
      unless    => "if((get-smbshare \"${smb_share_name}\").path -eq \"${smb_share_directory}\"){exit 0;}else{write-output \"${smb_share_name} path not that desired, must delete and recreate\";exit 1;}",
      require   => Exec["Create-${smb_share_name}"],
      logoutput => true,
    }

    exec { "CachingMode-${smb_share_name}":
      command   => "Set-SmbShare -name \"${smb_share_name}\" -CachingMode ${smb_share_cache} -Force;",
      provider  => powershell,
      unless    => "if((get-smbshare \"${smb_share_name}\").CachingMode.tostring() -eq \"${smb_share_cache}\"){exit 0;}else{exit 1;}",
      require   => Exec["Create-${smb_share_name}"],
      logoutput => true,
    }

    exec { "ConcurrentUserLimit-${smb_share_name}":
      command   => "set-smbshare -name \"${smb_share_name}\" -ConcurrentUserLimit ${smb_share_concurrent_user_limit} -Force;",
      provider  => powershell,
      unless    => "if((get-smbshare \"${smb_share_name}\").ConcurrentUserLimit -eq ${smb_share_concurrent_user_limit}){exit 0;}else{exit 1;}",
      require   => Exec["Create-${smb_share_name}"],
      logoutput => true,
    }

    exec { "Description-${smb_share_name}":
      command   => "set-smbshare -name \"${smb_share_name}\" -Description \"${smb_share_comments}\" -Force;",
      provider  => powershell,
      unless    => "if((get-smbshare \"${smb_share_name}\").Description -eq \"${smb_share_comments}\"){exit 0;}else{exit 1;}",
      require   => Exec["Create-${smb_share_name}"],
      logoutput => true,
    }

    exec { "EncryptData-${smb_share_name}":
      command   => "set-smbshare -name \"${smb_share_name}\" -EncryptData \$${smb_share_encrypt_data} -Force",
      provider  => powershell,
      unless    => "if((get-smbshare \"${smb_share_name}\").EncryptData -eq \$${smb_share_encrypt_data}){exit 0;}else{exit 1;}",
      require   => Exec["Create-${smb_share_name}"],
      logoutput => true,
    }

    exec { "FolderEnumerationMode-${smb_share_name}":
      command   => "set-smbshare -name \"${smb_share_name}\" -FolderEnumerationMode \"${smb_share_folder_enum_mode}\" -force",
      provider  => powershell,
      unless    => "if((get-smbshare \"${smb_share_name}\").FolderEnumerationMode.tostring() -eq \"${smb_share_folder_enum_mode}\"){exit 0;}else{exit 1;}",
      require   => Exec["Create-${smb_share_name}"],
      logoutput => true,
    }

    exec { "share_temporary_nature-${smb_share_name}":
      command   => "remove-smbshare -name \"${smb_share_name}\" -force;New-SmbShare -Name \"${smb_share_name}\" -Path \"${smb_share_directory}\" -CachingMode ${smb_share_cache} -ConcurrentUserLimit ${smb_share_concurrent_user_limit} -Description \"${smb_share_comments}\" -EncryptData \$${smb_share_encrypt_data} -FolderEnumerationMode ${smb_share_folder_enum_mode}${create_string_temporary_suffix}${create_string_permissions_suffix};",
      provider  => powershell,
      unless    => "if((get-smbshare \"${smb_share_name}\").Temporary -eq \$${smb_share_temporary}){exit 0;}else{write-output \"share temporary nature changed - must delete and recreate...\";exit 1;}",
      require   => Exec["Create-${smb_share_name}"],
      logoutput => true,
    }

    exec { "share_permissions-${smb_share_name}":
      command   => "remove-smbshare -name \"${smb_share_name}\" -force;New-SmbShare -Name \"${smb_share_name}\" -Path \"${smb_share_directory}\" -CachingMode ${smb_share_cache} -ConcurrentUserLimit ${smb_share_concurrent_user_limit} -Description \"${smb_share_comments}\" -EncryptData \$${smb_share_encrypt_data} -FolderEnumerationMode ${smb_share_folder_enum_mode}${create_string_temporary_suffix}${create_string_permissions_suffix};",
      provider  => powershell,
      unless    => "\
function sanitize_access_entries{param([string[]]\$access_array);\
for(\$i=0;\$i -lt \$access_array.length;\$i++){if(\$access_array[\$i].Contains('\')){\
if(\$access_array[\$i].Substring(0,\$access_array[\$i].IndexOf('\')).Contains('.')){\
\$access_array[\$i] = \$access_array[\$i].Substring(0,\$access_array[\$i].IndexOf('.')) + \$access_array[\$i].Substring(\$access_array[\$i].IndexOf('\'));}}\
elseif(\$access_array[\$i].Contains('@')){\
\$access_array[\$i] = \$access_array[\$i].Substring(\$access_array[\$i].IndexOf('@') + 1).split('.')[0] + \"\\\" + \$access_array[\$i].Substring(0,\$access_array[\$i].IndexOf('@'));}\
else{\$access_array[\$i] = \$env:COMPUTERNAME + '\' + \$access_array[\$i];}\
\$access_array[\$i] = \$access_array[\$i].ToUpper();}return \$access_array;}
function check_access{param([object[]]\$existing_access,[string[]]\$check_array,[string]\$access_type);\
foreach(\$s in \$check_array){foreach(\$o in \$existing_access){if(\$s.ToUpper() -eq \$o.AccountName.ToUpper())\
{if(\$o.AccessRight -ne \$access_type){return \$false;}else{break;}}}}return \$true;}\
[string[]]\$access_full = sanitize_access_entries @(${fixed_full_access_str});\
[string[]]\$access_change = sanitize_access_entries @(${fixed_change_access_str});\
[string[]]\$access_read = sanitize_access_entries @(${fixed_read_access_str});\
[string[]]\$access_deny = sanitize_access_entries @(${fixed_deny_access_str});\
[object[]]\$existing_access = Get-SmbShareAccess -name \"${smb_share_name}\";\
if(\$access_full -eq \$null){\$access_full = new-object string[] 0;};\
if(\$access_change -eq \$null){\$access_change = new-object string[] 0;};\
if(\$access_read -eq \$null){\$access_read = new-object string[] 0;};\
if(\$access_deny -eq \$null){\$access_deny = new-object string[] 0;};\
\$totalcount = \$access_full.Length + \$access_change.Length + \$access_read.Length + \$access_deny.Length;\
if(\$existing_access.Count -ne \$totalcount){write-output \"count mismatch on perms entries...\";exit 1;}\
if(!(check_access -existing_access \$existing_access -check_array \$access_full -access_type \"Full\")){write-output \"share perms changed must remake share...\";exit 1;}\
if(!(check_access -existing_access \$existing_access -check_array \$access_change -access_type \"Change\")){write-output \"share perms changed must remake share...\";exit 1;}\
if(!(check_access -existing_access \$existing_access -check_array \$access_read -access_type \"Read\")){write-output \"share perms changed must remake share...\";exit 1;}\
if(!(check_access -existing_access \$existing_access -check_array \$access_deny -access_type \"Deny\")){write-output \"share perms changed must remake share...\";exit 1;}",
      require   => Exec["Create-${smb_share_name}"],
      logoutput => true,
    }

  } else {
    exec { "Delete-${smb_share_name}":
      command   => "remove-smbshare \"${smb_share_name}\" -confirm:\$false",
      provider  => powershell,
      unless    => "if((get-smbshare \"${smb_share_name}\") -ne \$null){exit 1;}else{exit 0;}",
      logoutput => true,
    }

  }
}
