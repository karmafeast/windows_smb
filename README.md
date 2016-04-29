windows_smb
============================

Module for puppet that can be used to create and manage windows SMB shares, and set various configuration options for SMB server / client settings on a windows system.

Very unrestricted limits on settings, I tried to find absolute min/max values for the settings for `windows_smb::manage_smb_server_config` and `window_smb::manage_smb_client_config`.

Stayed away from settings like forcing digital signing etc. as these tend to be managed via group policy.

That's kind of a thing in puppet on windows, you find yourself moving towards replacing things done with GPO.  If people want it, I'll add it.  It is good to reduce infrastructure config to state declaration code.  However, we need to make that transition smooth for admins and not be invasive.

__N.B.__: not making resources depend upon a PowerShell version check - this has been tested OK with version 4 and 5.  Upgrade your Windows Management Framework to 4.0 or higher if you run into bother on old OS.

__tested on__: server 2012R2 OK (PS 4), win 10 enterprise OK (PS 5)

Module Usage
--
__Only supports windows OS__ - `windows_smb::manage_smb_share` only supports windows feature 'FS-BranchCache' where it exists but does NOT restrict attempted auto-install of 'FS-BranchCache feature' - module resources will fail due to dependency if for some reason the windows feature is unavailable for install or the system does not support ps commandlet 'add-windowsfeature'.

Example Use
--
    node 'my_file_server.corp.blah.moo' {
        include 'my_smb_file_shares'
    }

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

          #server smb config settings example - note the 'title' / resource name isn't used in class
          #note that cannot set ensure to 'absent' as many of these settings REQUIRED for os to function properly - set ensrue => 'default' to reset to defaults
          windows_smb::manage_smb_server_config{$::clientcert:
           ensure                                        => present,
           smb_server_asynchronous_credits               => 1024,
           smb_server_smb2_credits_min                   => 1024,
           smb_server_smb2_credits_max                   => 16384,
           smb_server_max_threads_per_queue              => 64,
           smb_server_treat_host_as_stable_storage       => true,
           smb_server_max_channel_per_session            => 32,
           smb_server_additional_critical_worker_threads => 20,
           smb_server_additional_delayed_worker_threads  => 20,
           smb_server_ntfs_8dot3_name_creation           => 'disabled',
           smb_server_ntfs_disable_last_access_update    => true,
           }
           
        # reset server config settings to defaults
        # windows_smb::manage_smb_server_config{$::clientcert: ensure => default,}

        windows_smb::manage_smb_client_config{$::clientcert:
         ensure                                               => 'present',
         smb_client_connection_count_per_interface            => 16,
         smb_client_connection_count_per_rss_interface        => 16,
         smb_client_connection_count_per_rdma_interface       => 16,
         smb_client_connection_count_per_server_max           => 64,
         smb_client_dormant_Directory_timeout_seconds         => 500,
         smb_client_directory_cache_lifetime_seconds          => 15,
         smb_client_dormant_file_limit                        => 4096,
         smb_client_directory_cache_entry_size_max_bytes      => 65580,
         smb_client_file_not_found_cache_lifetime_seconds     => 5,
         smb_client_file_not_found_cache_entries_max          => 2048,
         smb_client_file_info_cache_lifetime_seconds          => 5,
         smb_client_file_info_cache_entries_max               => 1024,
         smb_client_enable_bandwidth_throttling               => false,
         smb_client_enable_large_mtu                          => false,
         smb_client_enable_byte_range_locking_read_only_files => false,
         smb_client_enable_multichannel                       => false,
         smb_client_extended_session_timeout_seconds          => 999,
         smb_client_keep_connection_seconds                   => 555,
         smb_client_max_commands                              => 8192,
         smb_client_oplocks_disabled                          => true,
         smb_client_session_timeout_seconds                   => 45,
         smb_client_use_opportunistic_locking                 => false,
         smb_client_window_size_threshold                     => 16
         }
        
       # reset client config settings to defaults
       # windows_smb::manage_smb_client_config{$::clientcert: ensure => default,}
      }

#`windows_smb::manage_smb_share`
__THIS MODULE DOES NOT SUPPORT CLUSTERED SHARES UNDER CAFS__

##`windows_smb::manage_smb_share` parameters

####`ensure`
Set the ensure state of the smb share. string.

* __'present'__: will ensure the share exists and is set as desired
* __'absent','purge'__: 'absent' / 'purge' will remove the share by share name on the system applying windows_smb::manage_smb_share

__default value__: 'present'

####`smb_share_directory`
Set this to the fully qualified path to share as string.  Note that this class will NOT ensure that the target file system path for share assurance is present.  Doing so would be invasive coding.  
Create a File resource for the directory to be shared and make the `windows_smb::manage_smb_share` instance dependent upon it.  this is shown in the example above.

####`smb_share_comments`
Set string to put as comments on the share (description)

__default value__: 'puppet generated smb share'

####`smb_share_concurrent_user_limit`
Set the Uint32 desired concurrent user limit on the share being managed.
 
__valid integer range__: 0 - 4294967295  --- Setting 0 will result in there not being a share enforced restriction on concurrent user limit.

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

* __'AccessBased'__: SMB will not the display the files and folders for a share to a user unless that user has rights to access the files and folders. Via PowerShell, access-based enumeration is disabled by default for new SMB shares.  This is NOT true for this module.
* __'Unrestricted'__: SMB will display files and folders to a user even when the user does not have permission to access those items.
 
__default value__: 'AccessBased'

###`smb_share_temporary`
Set bool to indicate whether share will persist past system reboot:

* __true__: share will NOT persist past system reboot.  The share is temporary.
* __false__: share is permanent and will persist past system reboot.

__default value__: false

##share permissions params
__N.B.__ Module does NOT support share creation with no permissions whatsoever.  If all permissions params are `[]` (empty array) will cause catalog failure due to resource where that implementation exists.

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

#`windows_smb::manage_smb_server_config`

##`windows_smb::manage_smb_server_config` parameters
Sensible caps on resource params are not implemented.  You may tweak up to the maximum allowed value and it is assumed you will research impact on system performance / viability to serve.  Good luck, have fun!

###Resource 'Name' / 'Title' is irrelivent - suggest set to `$::fqdn` or `$::clientcert` as in example
Settings are global for the Windows machine the resource is applied against.  For sanity, suggest naming resource `$::fqdn` or `$::clientcert`

####`ensure`
Set the ensure state of the smb share. string.

* __'present'__: will ensure the smb server config exists and is set as desired
* __'default'__: 'default' will reset node values to sensible OS defaults.  These may or may not be the most optimal for node use case.

__default value__: 'present'

###`smb_server_asynchronous_credits`
Limits the number of concurrent asynchronous SMB commands that are allowed on a single connection. Some cases (such as when there is a front-end server with a back-end IIS server) require a large amount of concurrency (for file change notification requests, in particular). The value of this entry can be increased to support these cases.

__default value__: false

###`smb_server_smb2_credits_min`

Uint32. Allow the server to throttle client operation concurrency dynamically within the specified boundaries. Some clients might achieve increased throughput with higher concurrency limits, for example, copying files over high-bandwidth, high-latency links.

__valid integer range__: 1 - `smb_server_smb2_credits_max` (theoretical max 4294967295)

__default value__: 512  << value may not be higher than `smb_server_smb2_credits_max`

__tweaking notes__: You can monitor SMB Client Shares\Credit Stalls /Sec to see if there are any issues with credits.

###`smb_server_smb2_credits_max`
Uint32. Allow the server to throttle client operation concurrency dynamically within the specified boundaries. Some clients might achieve increased throughput with higher concurrency limits, for example, copying files over high-bandwidth, high-latency links.

__valid integer range__: `smb_server_smb2_credits_max` (theoretical min 1) - 4294967295

__default value__: 8192 << value may not be lower than `smb_server_smb2_credits_min`

__tweaking notes__: You can monitor SMB Client Shares\Credit Stalls /Sec to see if there are any issues with credits.

###`smb_server_max_threads_per_queue`
Uint32. Increasing this value raises the number of threads that the file server can use to service concurrent requests. When a large number of active connections need to be serviced, and hardware resources, such as storage bandwidth, are sufficient, increasing the value can improve server scalability, performance, and response times. 

__valid integer range__: 1 - 4294967295

__default value__: 20

###`smb_server_treat_host_as_stable_storage`
bool. Set true to disables processing write flush commands from clients. If the value of this param is true, the server performance and client latency for power-protected servers can improve. Workloads that resemble the NetBench file server benchmark benefit from this behavior.  

__default value__: false

__tweaking notes__: Note that if you have a clustered file server, it is possible that you may experience data loss if the server fails with this setting enabled. Therefore, evaluate it carefully prior to applying it. __THIS MODULE DOES NOT SUPPORT CLUSTERED SHARES UNDER CAFS__

###`smb_server_max_channel_per_session`
Uint32. Specifies the maximum channels per session.

__valid integer range__: 1 - 4294967295

__default value__: 32

__tweaking notes__: 64 / 128 didn't seem to explode a file server under load, seems a good starting point

###`smb_server_max_session_per_connection`
Uint32. Specifies the maximum sessions per connection.

__valid integer range__: 1 - 4294967295

__default value__: 16384

##Additional work threads
At system startup, Windows creates several server threads that operate as part of the System process. These are called system worker threads. They exist with the sole purpose of performing work on the behalf of other threads generated by the kernel, system device drivers, the system executive and other components. When one of these components puts a work item in a queue, a thread is assigned to process it.
The number of system worker threads should ideally be high enough to accept work tasks as soon as they become assigned. The trade off, of course, is that worker threads sitting idle consume system resources unnecessarily.

###`smb_server_additional_critical_worker_threads`
Uint32. The AdditionalCriticalWorkerThreads value increases the number of critical worker threads created for a specified work queue. Critical worker threads process time-critical work items and have their stack present in physical memory at all times. An insufficient number of threads will reduce the rate at which time-critical work items are serviced; a value that is too high will consume system resources unnecessarily.

The default is 0, which means that no additional critical kernel worker threads are added. This value affects the number of threads that the file system cache uses for read-ahead and write-behind requests. Raising this value can allow for more queued I/O in the storage subsystem, and it can improve I/O performance, particularly on systems with many logical processors and powerful storage hardware. 

__valid integer range__: 0 - 4294967295

__default value__: 0

__tweaking notes__: The value may need to be increased if the amount of cache manager dirty data (performance counter Cache\Dirty Pages) is growing to consume a large portion (over ~25%) of memory or if the system is doing lots of synchronous read I/Os.

###`smb_server_additional_delayed_worker_threads`
Uint32. The AdditionalDelayedWorkerThreads value increases the number of delayed worker threads created for the specified work queue.

__valid integer range__: 0 - 4294967295

__default value__: 0

__tweaking notes__: Delayed worker threads process work items that are not considered time-critical and can have their memory stack paged out while waiting for work items. An insufficient number of threads will reduce the rate at which work items are serviced; a value that is too high will consume system resources unnecessarily.

###`smb_server_ntfs_8dot3_name_creation`
String equating to enum.  When a long file name is created using the Windows NTFS file system, the default behavior may be (OS version dependent) to generate a corresponding short file name in the older 8.3 DOS file name convention for compatibility with older operating systems. This functionality can be disabled.

__value values__: [string] - numerics correspond to the raw registry value controlling this setting, which equate to an enum in practice

* __'0' , 'enabled'__: 8.3 name creation is enabled
* __'1' , 'disabled'__: 8.3 name creation is disabled
* __'2' , 'per_volume'__: 8.3 name creation can be configured on a per volume basis

###`smb_server_ntfs_disable_last_access_update`
The default is 1 in newer Windows versions. In versions of Windows earlier than Windows Vista and Windows Server 2008, the default is 0.

__default value__: undef   <<< don't know what OS is being run.

__N.B.__: `ensure => 'default'` will set value to 1 - this will DISABLE last access timestamp updates.

__valid values__:

* __true__:  DISABLE last access timestamp updates
* __false__: ENABLE last access timestamp updates

__tweaking notes__: A value of 0 can reduce performance because the system performs additional storage I/O when files and directories are accessed to update date and time information.

#`windows_smb::manage_smb_client_config`
Avoided `EnableInsecureGuestLogons` as only available windows 10 / server 2016 and documentation I found simply says 'TBD'. so no.

Avoided `EnableLoadBalanceScaleOut` - I do not know enough about impact of this.  Tell me and I'll add it.

Avoided `RequireSecuritySignature` - typically options for client/server digital signing / encryption handled in organization via GPO.  Yes, we can replace a lot of whats going on there with puppet code but at this time I deem that invasive to the Windows OS platform as typically managed in an enterprise.

Manage smb client settings on node.  suggest name resource like so for sanity across your catalog: `windows_smb::manage_smb_client_config{$::clientcert: ensure => present, ...}`

##`windows_smb::manage_smb_client_config` parameters
Sensible caps on resource params are not implemented.  You may tweak up to the maximum allowed value and it is assumed you will research impact on system performance / viability to serve.  Good luck, have fun!

####`ensure`
Set the ensure state of the smb share. string.

* __'present'__: will ensure the smb client config exists and is set as desired
* __'default'__: 'default' will reset node values to sensible OS defaults.  These may or may not be the most optimal for node use case.

__default value__: 'present'

###`smb_client_connection_count_per_interface`
Uint32. Specifies the maximum connections per interface to be established with a smb server running Windows Server for non-RSS interfaces. 

__valid integer range__: 1 - 16

__default value__: 1

###`smb_client_connection_count_per_rss_interface`
Uint32. Specifies the maximum connections per rss interface to be established with a server running Windows Server 2012 for RSS interfaces.

__valid integer range__: 1 - 16

__default value__: 4

###`smb_client_connection_count_per_rdma_interface`
Uint32. Specifies the maximum connections per rss interface to be established with a server running Windows Server 2012 for RDMA interfaces.

__valid integer range__: 1 - 16

__default value__: 2

###`smb_client_connection_count_per_server_max`
Uint32. Specifies the maximum number of connections to be established with a single smb server running Windows across all interfaces.

__valid integer range__: 1 - 64

__default value__: 32

###`smb_client_dormant_directory_timeout_seconds`
Uint32. Specifies the maximum time server directory handles held open with directory leases.

__valid integer range__: 0 - 4294967295

__default value__: 600

###`smb_client_directory_cache_lifetime_seconds`
Uint32. Specifies the directory cache timeout.  This parameter controls caching of directory metadata in the absence of directory leases.

__valid integer range__: 0 - 4294967295

__default value__: 10

###`smb_client_dormant_file_limit`
Uint32. Specifies the maximum number of files that should be left open on a shared resource after the application has closed the file.

__valid integer range__: 1 - 4294967295

__default value__: 1023

###`smb_client_directory_cache_entry_size_max_bytes`
Uint32. in bytes. Specifies the maximum size of directory cache entries. The default is 64KB.  Can be increased to max of 16MB.

__valid integer range__: 65536 - 16777216

__default value__: 1023

__tweaking notes__: try 16777216

###`smb_client_directory_cache_entries_max`
Uint32. in bytes. Specifies the amount of directory information that can be cached by the client. Increasing the value can reduce network traffic and increase performance when large directories are accessed.

__valid integer range__: 1 - 4096

__default value__: 16

__tweaking notes__: recommend set to 4096 - ref: <https://msdn.microsoft.com/en-us/library/windows/hardware/dn567661(v=vs.85).aspx> 

###`smb_client_file_not_found_cache_lifetime_seconds`
Uint32. in bytes. Specifies the amount of directory information that can be cached by the client. Increasing the value can reduce network traffic and increase performance when large directories are accessed.

__valid integer range__: 0 - 4294967295

__default value__: 5

__tweaking notes__: try increase, e.g. 10 or more, use with `smb_client_file_not_found_cache_entries_max`

###`smb_client_file_not_found_cache_entries_max`
Uint32. Specifies the amount of file name information that can be cached by the client. Increasing the value can reduce network traffic and increase performance when a large number of file names are accessed.

__valid integer range__: 1 - 65536

__default value__: 128

__tweaking notes__: try increase, use with  `smb_client_file_not_found_cache_lifetime_seconds` - suggest 32768 - ref: <https://msdn.microsoft.com/en-us/library/windows/hardware/dn567661(v=vs.85).aspx> 

###`smb_client_file_info_cache_lifetime_seconds`
Uint32. The file information cache timeout period.

__valid integer range__: 0 - 4294967295

__default value__: 10

__tweaking notes__: try increase, 15 or more. use with `smb_client_file_info_cache_entries_max`

###`smb_client_file_info_cache_entries_max`
Uint32. Specifies the amount of file metadata that can be cached by the client. Increasing the value can reduce network traffic and increase performance when a large number of files are accessed.

__valid integer range__: 1 - 65536

__default value__: 64

__tweaking notes__: suggest 32768 - ref: <https://msdn.microsoft.com/en-us/library/windows/hardware/dn567661(v=vs.85).aspx> 

###`smb_client_enable_bandwidth_throttling`
bool. the SMB redirector throttles throughput across high-latency network connections, in some cases to avoid network-related timeouts. Setting this param to false may result in higher file transfer throughput over high-latency network connections.

__valid values__:

* __true__:  ENABLE bandwidth throttling
* __false__: DISABLE bandwidth throttling

__default value__: true

__tweaking notes__: suggest false - ref: <https://msdn.microsoft.com/en-us/library/windows/hardware/dn567661(v=vs.85).aspx> 

###`smb_client_enable_large_mtu`
bool. if enabled (true) the SMB redirector transfers payloads as large as 1 MB per request, which can improve file transfer speed. if disabled, limited to 64 KB.

__valid values__:

* __true__:  ENABLE large MTU
* __false__: DISABLE large MTU

__default value__: true

###`smb_client_enable_byte_range_locking_read_only_files`
bool. Controls whether byte-range locking is enabled on read-only files.

__valid values__:

* __true__:  ENABLE byte-range locking on read-only files
* __false__: DISABLE byte-range locking on read-only files

__default value__: true

###`smb_client_enable_multichannel`
bool. Enable or disable the use of multiple physical network interfaces.

__valid values__:

* __true__:  ENABLE use of multiple physical network interfaces
* __false__: DISABLE use of multiple physical network interfaces

__default value__: true

###`smb_client_extended_session_timeout_seconds`
Uint32. extended session timeout in seconds.
 
__valid integer range__: 0 - 4294967295

__default value__: 1000

###`smb_client_keep_connection_seconds`
Uint32. How long to keep an smb session open.

__valid integer range__: 0 - 4294967295

__default value__: 600

###`smb_client_max_commands`
Uint32.  Specifies the maximum number of network control blocks that the redirector can reserve. The value of this entry coincides with the number of execution threads that can be outstanding simultaneously.

__valid integer range__: 0 - 4294967295

__default value__: 50

###`smb_client_oplocks_disabled`
bool. set this true if opportunistic locking is to be disabled. See `smb_client_use_opportunistic_locking`.  did not mask this setting into one thing as want to expose as much as possible raw in this module.  

__valid values__:

* __true__:  DISABLE use of opportunistic locking
* __false__: ENABLE use of opportunistic locking

__default value__: false

__tweaking notes__: I don't know what you want to do as a devops person / admin / engineer / architect / whatever we're called today; so you're getting both setting exposed and are not locked to setting both in tandem.  Though this is suggested. see `smb_client_use_opportunistic_locking`

###`smb_client_use_opportunistic_locking`
Controls whether the opportunistic-locking (oplock) performance enhancement is enabled. If true, the redirector requests an opportunistic lock on any file opened in "Deny None" mode. As a result, the server performs automatic read-ahead and write-behind caching on behalf of the redirector.

__valid values__:

* __true__:  ENABLE use of opportunistic locking
* __false__: DISABLE use of opportunistic locking

__default value__: true

__tweaking notes__: there may be interference if this is used in certain scenarios but for general use (and os default) sounds like a good idea to use.  leave `smb_client_oplocks_disabled` not specified as a param or specify false for `smb_client_oplocks_disabled` if you want op locking ON.

###`smb_client_session_timeout_seconds`
Uint32. The number of seconds that the client waits before disconnecting an inactive session.

__valid integer range__: 10 - 65535

__default value__: 60

###`smb_client_window_size_threshold`
Uint32. The minimum window size before Multichannel will trigger the use of multiple connections. 

__valid integer range__: 10 - 65535

__default value__: 1

__tweaking notes__: The default value is 1 for Windows Server operating systems and 8 for Windows client operating systems.  This module uses 1 as default.  It won't kill the workstation and is what server wants.

References
--
__Set-SmbShare documentation__: <https://technet.microsoft.com/en-us/%5Clibrary/jj635727(v=wps.630).aspx>

__Set-SmbServerConfiguration__: <https://technet.microsoft.com/en-us/library/jj635714(v=wps.630).aspx>

__Performance Tuning for File Servers__: <https://msdn.microsoft.com/en-us/library/windows/hardware/dn567661(v=vs.85).aspx>

__Optimizing Operating System Performance__: <https://msdn.microsoft.com/en-us/library/cc615012(v=bts.10).aspx>

__CIFS and SMB Timeouts in Windows__: <https://blogs.msdn.microsoft.com/openspecification/2013/03/19/cifs-and-smb-timeouts-in-windows/>

__SetConfiguration method of the MSFT_SmbClientConfiguration class__: <https://msdn.microsoft.com/en-us/library/hh830477(v=vs.85).aspx>