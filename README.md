windows_smb
============================

Module for puppet that can be used to create and manage windows SMB shares, and set verious configuration options for SMB server / client settings on a windows system.

Usage
--
Only supports windows OS - only supports windows feature 'FS-BranchCache' where it exists but does NOT restrict attempted auto-install of 'FS-BranchCache feature' - module resources will fail due to dependency if for some reason the windows feature is unavailable for install or the system does not support ps commandlet 'add-windowsfeature'.

    node 'my_file_server.corp.blah.moo' {
        include 'my_smb_file_shares'
    }


Examples - `windows_smb::manage_smb_share`
--
      class my_smb_file_shares {
            
          #module will NOT ensure share target directory on file system exists, make sure it does and require it in windows_smb::manage_smb_share resource instance
          file { 'c:\temp1': ensure => directory, }

          windows_smb::manage_smb_share { 'testshare':
            smb_share_directory               => 'c:\temp1',
            ensure                            => present,
            smb_share_comments                => 'puppet generated smb share test',
            smb_share_concurrent_user_limit   => 0,
            smb_share_cache                   => 'None',
            smb_share_encrypt_data            => false,
            smb_share_folder_enum_mode        => 'AccessBased',
            smb_share_temporary               => true,
            smb_share_access_full             => ['corp.blah.moo\user0', 'local_admin','user1@corp.blah.moo'],
            smb_share_access_change           => ['corp\domain admins'],
            smb_share_access_read             => [],
            smb_share_access_deny             => [],
            smb_share_autoinstall_branchcache => false,
            require                           => File['c:\temp1'],
          }

          #with defaults - note ensure is assumed => 'present'
          windows_smb::manage_smb_share { 'testshare1':
            smb_share_directory               => 'c:\temp1',
            smb_share_access_full             => ['Everyone'],
            require                           => File['c:\temp1'],
          }  
      }

###`windows_smb::manage_smb_share` parameters

####`smb_share_directory`
Set this to the fully qualified path to share as string.  Note that this class will NOT ensure that the target file system path for share assurance is present.  Doing so would be invasive coding.  
Create a File resource for the directory to be shared and make the `windows_smb::manage_smb_share` instance dependent upon it.  this is shown in the example above.

####`ensure`
Set the ensure state of the smb share. string.

* __'present'__: will ensure the share exists and is set as desired
* __'absent','purge'__: 'absent' / 'purge' will remove the share by share name on the system applying windows_smb::manage_smb_share

__default value__: 'present'

####`smb_share_comments`
Set string to put as comments on the share (description)

__default value__: 'puppet generated smb share'

####`smb_share_concurrent_user_limit`
Set the Uint32 desired concurrent user limit on the share being managed.
 
__valid integer range__: 0 - 4294967296  --- Setting 0 will result in there not being a share enforced restriction on concurrent user limit.

__default value__: 0

####`smb_share_cache`
Set to one of the valid string options 'None', 'Manual', 'Programs', 'Documents', 'BrancheCache'.

* __None__: Prevents users from storing documents and programs offline.
* __Manual__: Allows users to identify the documents and programs that they want to store offline.
* __Programs__: Automatically stores documents and programs offline.
* __Documents__: Automatically stores documents offline.
* __BranchCache__: Enables BranchCache and manual caching of documents on the shared folder.

__default value__: 'None'

###`smb_share_encrypt_data`
Set bool to indicate if the share utilizes encrytion. 

__default value__: false

###`smb_share_folder_enum_mode`
Set string to specify which files and folders in the SMB share will be visible to the users.

* __'AccessBased'__: SMB will not the display the files and folders for a share to a user unless that user has rights to access the files and folders. By default, access-based enumeration is disabled for new SMB shares.
* __'Unrestricted'__: SMB will display files and folders to a user even when the user does not have permission to access those items.
 
__default value__: 'AccessBased'

###`smb_share_temporary`
Set bool to indicate whether share will persist past system reboot:

* __true__: share will NOT persist past system reboot.  The share is temporary.
* __false__: share is permanent and will persist past system reboot.

__default value__: false

##share permissions params
__N.B.__ Module does NOT support share creation with no permissions whatsoever.  If all permissions params are [] (empty array) will cause catalog failure due to resource where that implementation exists.

__N.B.__ CANNOT set permissions entries for user to multiple permission types on a share - i.e. user1 may not have both 'full' and 'change' assignments.  It is not like ACEs at the file system level.  Can only be in one place.  Puppet DSL logic will attempt to reject a configuration made in this way and if somehow slips through the resource create would fail.  if resource exists permissions check would also fail as change in permissions results in share removal and recreate.

__N.B.__ UPN limitation in that it much match the user domain - so user@corp.moo would not work if user domain was user@corp.blah.moo

__N.B.__ permissions return with powershell 'GetSmbAccess' returns object array with UNQUALIFIED domain name as string - cannot accurately resolve scenarion where assigning permissions over trust - e.g. assign permissions for user0@corp.blah.moo AND user0@corp.foo.toyou UNTESTED and may not work

* can use local account unqualified, domain\username or user UPN

###`smb_share_access_full`
string array of users / groups to grant 'full' access permissions to at the smb share level (THIS IS NOT FILE PERMISSIONS ON DISK).

* e.g. ['domain\user0', 'local_admin','user1_upn@domain.blah.moo']

__default value__: []     <<<< EMPTY (STRING) ARRAY

###`smb_share_access_change`
string array of users / groups to grant 'change' access permissions to at the smb share level (THIS IS NOT FILE PERMISSIONS ON DISK)

* e.g. ['domain\user1', 'local_admin_0','user2_upn@domain.blah.moo']

__default value__: []     <<<< EMPTY (STRING) ARRAY

###`smb_share_access_read`
string array of users / groups to grant 'read' access permissions to at the smb share level (THIS IS NOT FILE PERMISSIONS ON DISK)

* e.g. ['domain\user2', 'local_admin_1','user3_upn@domain.blah.moo']

__default value__: []     <<<< EMPTY (STRING) ARRAY

###`smb_share_access_deny`
string array of users / groups to set 'deny' access permissions to at the smb share level (THIS IS NOT FILE PERMISSIONS ON DISK)

* e.g. ['domain\user3', 'local_admin_2','user4_upn@domain.blah.moo']

__default value__: []     <<<< EMPTY (STRING) ARRAY

###`smb_share_autoinstall_branchcache`
set boolean true to attempt to auto-install windows feature 'FS-BranchCache' if available to system via PowerShell 'Add-WindowsFeature'.  Does not ensure state of windows feature via another resource type - it is an exec based get / set.  So safe to use if ensure 'FS-BranchCache' as windows feature elsewhere in catalog.
Share creation made dependent on this exec resource if this param 'true' to ensure proper fail if not available for install and cannot install.

__N.B.__ use in conjunction with `smb_share_cache => 'BranchCache'` if set to true, otherwise not relevant and will not execute.

__N.B.__ can use `smb_share_cache => 'BranchCache'` WITHOUT using `smb_share_autoinstall_branchcache' => true` - it just won't consider windows feature 'FS-BranchCache' presence - caller in this case responsible for it being there

__default value__: false



References
--
__Set-SmbShare documentation__: <https://technet.microsoft.com/en-us/%5Clibrary/jj635727(v=wps.630).aspx>
