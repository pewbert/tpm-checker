# For use with Windows 11
# https://learn.microsoft.com/en-us/windows/win32/secprov/GetPhysicalPresenceRequest-win32-tpm
# https://learn.microsoft.com/en-us/windows/win32/secprov/SetPhysicalPresenceRequest-win32-tpm
# https://learn.microsoft.com/en-us/windows/win32/secprov/GetPhysicalPresenceTransition-win32-tpm
# https://learn.microsoft.com/en-us/windows/win32/secprov/GetPhysicalPresenceResponse-win32-tpm
# https://learn.microsoft.com/en-us/windows/win32/secprov/GetPhysicalPresenceConfirmationStatus

#assume Get-TPM returns restartPending is TRUE. Check to see which PhysicalPresentInterface [PPI] requires a restart.
#If there is no request there should not be a RestartPending.
#If there is a request, 1-22, it should clear and go back to 0 after a restart, but it is not working properly.
#We check to see the PhysicalPresenceTransition value, 1 or 2 means a reboot is required to clear the Request state.
#We check to see the PhysicalPresenceConfirmationStatus value, this checks to see if the feature can be cleared or not with a physically present person or if it is blocked or supported by the O/S and/or BIOS

if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $False) { write-host "Need Administrative privileges to continue..."}
else {

$table = New-Object System.Data.DataTable

$column1 = New-Object System.Data.DataColumn("Instance",[string])
$column2 = New-Object System.Data.DataColumn("ID", [int])
$column3 = New-Object System.Data.DataColumn("Value",[string])

$table.Columns.Add($column1)
$table.Columns.Add($column2)
$table.Columns.Add($column3)

$row1 = $table.NewRow()
$row2 = $table.NewRow()
$row3 = $table.NewRow()
$row4 = $table.NewRow()
$row5 = $table.NewRow()

$tpm = Get-CimInstance -Namespace 'root/cimv2/Security/MicrosoftTpm' -ClassName 'Win32_TPM'
$tval = $tpm | Invoke-CimMethod -MethodName 'GetPhysicalPresenceTransition'
$rval = $tpm | Invoke-CimMethod -MethodName 'GetPhysicalPresenceRequest'
$cval= $tpm | Invoke-CimMethod -MethodName 'GetPhysicalPresenceConfirmationStatus' -Arguments @{Operation=$rval.Request}
$BIOS = Get-CimInstance -ClassName 'Win32_BIOS'

$row1.ID = $rval.Request
$row1.Instance = "GetPhysicalPresenceRequest"
$row2.ID = $tval.Transition
$row2.Instance = "GetPhysicalPresenceTransition"
$row3.ID = $cval.ConfirmationStatus
$row3.Instance = "GetPhysicalPresenceConfirmationStatus"
$row4.Instance = "Confirm-SecureBootUEFI"
$row4.Value = Confirm-SecureBootUEFI
$row5.Instance = $BIOS.Manufacturer
$row5.ID = $BIOS.Name
$row5.Value = $BIOS.Version
#

    switch ($tval.Transition)
    {
        0 { $row2.Value = "No user action is needed to perform a TPM physical presence operation." }
        1 { $row2.Value = "To perform a TPM physical presence operation, the user must shutdown the computer and then turn it back on by using the power button. The user must be physically present at the computer to accept or reject the change when prompted by the BIOS." }
        2 { $row2.Value = "To perform a TPM physical presence operation, the user must restart the computer by using a warm reboot. The user must be physically present at the computer to accept or reject the change when prompted by the BIOS." }
        3 { $row2.Value = "The required user action is unknown." }
        default {$row2.Value = "Not Implemented."  }
    }

$TPM = Get-tpm
$rp = $TPM | Select-Object RestartPending
if (($rp.RestartPending) -eq $True) 
 {
    switch ($rval.Request) 
    {
            0  { $row1.Value = "No Request." }
            1  { $row1.Value = "Enable the TPM." }
            2  { $row1.Value = "Disable the TPM." }
            3  { $row1.Value = "Activate the TPM." }
            4  { $row1.Value = "Deactivate the TPM." }
            5  { $row1.Value = "Clear the TPM." }
            6  { $row1.Value = "Enable and activate the TPM." }
            7  { $row1.Value = "Deactivate and disable the TPM." }
            8  { $row1.Value = "Allow the installation of a TPM owner." }
            9  { $row1.Value = "Prevent the installation of a TPM owner." }
            10 { $row1.Value = "Enable, activate, and allow the installation of a TPM owner." }
            11 { $row1.Value = "Deactivate, disable, and prevent the installation of a TPM owner." }
            12 { $row1.Value = "Deferred Physical PresenceunownedFieldUpgrade. Physical presence setting has been updated." }
           #13 { $row1.Value = "Not Implemented." }
            14 { $row1.Value = "Clear, enable, and activate the TPM. " }
            15 { $row1.Value = "SetNoPPIProvision_False. Sets the provision that you must be physically presence to set the TPM." }
            16 { $row1.Value = "SetNoPPIProvision_True. Sets the provision that you don't need to be physically presence to set the TPM." }
            17 { $row1.Value = "SetNoPPIClear_False. Sets the provision that you must be physically presence to clear the TPM." }
            18 { $row1.Value = "SetNoPPIClear_True. Sets the provision that you don't need to be physically presence to clear the TPM." }
            19 { $row1.Value = "SetNoPPIMaintenance_False. Sets the provision that you must be physically presence to maintain the TPM." }
            20 { $row1.Value = "SetNoPPIMaintenance_True. Sets the provision that you don't need to be physically presence to maintain the TPM." }
            21 { $row1.Value = "Enable, activate, and clear the TPM." }
            22 { $row1.Value = "Enable, activate, and clear the TPM, and then enable and reactivate the TPM." }
            default { $row1.Value = "Not Implemented." }
     }
}
else { $row1.Value = "No restart pending." }
    switch ($cval.ConfirmationStatus) 
    {
        0 { $row3.Value = "Not Implemented." }
        1 { $row3.Value = "BIOS Only." }
        2 { $row3.Value = "Blocked for the OS by the BIOS cfg." }
        3 { $row3.Value = "Allowed and Physically Present user required." }
        4 { $row3.Value = "Allowed and Physically Present user not required." }
    }

$table.Rows.Add($row1)
$table.Rows.Add($row2)
$table.Rows.Add($row3)
$table.Rows.Add($row4)
$table.Rows.Add($row5)

$table | Format-Table -autosize -wrap

}
