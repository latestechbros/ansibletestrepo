$Comp = [System.Net.Dns]::GetHostEntry("").HostName
$searchscope = [System.DirectoryServices.SearchScope]::Subtree
if(Test-Connection -ComputerName $Comp -Count 1 -Quiet)
{
    $now=Get-Date
    $admins = ([ADSI]"WinNT://$Comp/Administrators,group").psbase.Invoke("Members") | %{
        $_.GetType().InvokeMember("Name",'GetProperty',$null,$_,$null)
    }
    $localAccounts = ([ADSI]"WinNT://$Comp").Children | ?{$_.SchemaClassName -eq 'user'} | %{
        $groups=$_.Groups() | %{$_.GetType().InvokeMember("Name",'GetProperty',$null,$_,$null)}
        $_ | Select @{n='Server';e={$Comp}},
        @{n='Username';e={$_.Name}},
        @{n='Firstname';e={$_.FullName}},
        @{n='Lastname';e={}},
        @{n='Type';e={"Local Account"}},
        @{n='Active';e={if($_.PasswordAge -like 0){$false}else{$true}}},
        @{n='PasswordExpired';e={if($_.PasswordExpired){$true}else{$false}}},
        @{n='PasswordAgeDays';e={[math]::Round($_.PasswordAge[0]/86400,0)}},
        @{n='PasswordLastSet';e={(Get-Date).AddDays(-([math]::Round($_.PasswordAge[0]/86400,0))).ToString('MM/dd/yyyy')}},
        @{n='LastLogin';e={$_.LastLogin}},
        @{n='Groups';e={$Groups -join ';'}},
        @{n='Path';e={$_.Path}},
        @{n='Description';e={$_.Description}},
        @{n='Refresh Date';e={Get-Date -Format "MM-dd-yyyy"}}

    }
   
    $localAccounts 
}
Else {
    Write-Warning "Server '$Comp' is Unreachable hence Could not fetch the data"
}
