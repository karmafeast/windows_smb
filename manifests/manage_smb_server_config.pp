class windows_smb::manage_smb_server_config {
fail('windows_smb::manage_smb_server_config is not yet implemented - do not call this')
#TODO: build this - make it a custom resource as with the share management
#only support 2012r2 and up - smb 3.0 related stuffs
#build from here - https://msdn.microsoft.com/en-us/library/windows/hardware/dn567661(v=vs.85).aspx
#define windows_smb_share::manage_smb_server_config{}
#Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" AdditionalCriticalWorkerThreads -Value 64 -Force
#Set-SmbServerConfiguration -AsynchronousCredits 512 -force
#Set-SmbServerConfiguration -Smb2CreditsMin 512 -force
#Set-SmbServerConfiguration -Smb2CreditsMax 8192 -force
#Set-SmbServerConfiguration -MaxThreadsPerQueue 64 -force
#Set-SmbServerConfiguration -TreatHostAsStableStorage $true -force
#Set-SmbServerConfiguration -MaxChannelPerSession 64 -force
}
