function Add-UserNewSharedMailbox { 
<#
.SYNOPSIS
Add-UserNewSharedMailbox will help to grant permissions to the new shared mailbox and send an email.
.DESCRIPTION
Add-UserNewSharedMailbox will help to grant permissions to the new shared mailbox and send an email.
.PARAMETER GMDN
Get the Display Name for the group mailbox from SNOW and paste/type here.
.PARAMETER GMUPN
Get the UPN for the group mailbox and paste/type here.
.PARAMETER TaskNumber
Get the task number from SNOW and paste/type here.
.PARAMETER Requester
Get the first name of the person requesting the mailbox and paste/type here.
.PARAMETER RequesterUPN
Get the UPN for the person requesting the mailbox and paste/type here.
.EXAMPLE
Add-UserNewSharedMailbox Will prompt for GMDN, GMUPN, TaskNumber, Requester, and RequesterUPN
.EXAMPLE
Add-UserNewSharedMailbox -GMDN New Group Mailbox -GMUPN NewGroupMailbox -TaskNumber TASK1234567 -Requester Thomas -RequesterUPN tjones
Enter the parameters
.INPUTS
Types of objects input
.OUTPUTS
Types of objects returned
.NOTES
My notes.
.LINK
http://
.COMPONENT
.ROLE
.FUNCTIONALITY
#>
    [alias('ngm')]
    [cmdletbinding()]
    Param(

        [parameter(Mandatory=$True,HelpMessage="Enter the new Shared Mailbox display name without quotes, like: New Shared Mailbox")]
        [string]$GMDN = (Read-Host "Enter the new Shared Mailbox display name without quotes, like: New Shared Mailbox"),
       
        [parameter(Mandatory=$True,HelpMessage="Enter the new shared Mailbox UPN without quotes, like: newsharedmailbox")]
        [string]$GMUPN = (Read-Host "Enter the new shared Mailbox UPN without quotes, like: newsharedmailbox"),
        
        [parameter(Mandatory=$True,HelpMessage="Enter the Task Number without quotes, like: TASK1234567")]
        [string]$TaskNumber = (Read-Host "Enter the Task Number without quotes, like: TASK1234567"),

        [parameter(Mandatory=$True,HelpMessage="Enter the first name of the person requesting the mailbox without quotes, like: Mary")]
        [string]$Requester = (Read-Host "Enter the first name of the person requesting the mailbox without quotes, like: Mary"),

        [parameter(Mandatory=$True,HelpMessage="Enter the UPN of the person requesting the mailbox without quotes, like: mjones")]
        [string]$RequesterUPN = (Read-Host "Enter the UPN of the person requesting the mailbox without quotes, like: mjones")
                                       
        )

            
    #Get Lists to create display names - clear and add names - names are in format: First Last
    C:\NewGroupMailboxList\NGDNFullList.csv
    C:\NewGroupMailboxList\NGDNSendAsList.csv

    #Pause Until Key Press
    Read-Host "Enter names in text files, save, close, press enter"

    #connect to exchange online
    $CertThumbPrnt = import-clixml "c:\KeyPath\CertificateThumbPrint.xml"
    $EXOAppID = import-clixml "c:\KeyPath\EXOAppID.xml"
    Connect-ExchangeOnline -CertificateThumbPrint "$CertThumbPrnt" -AppID "$EXOAppID" -Organization "yourcorp.onmicrosoft.com"

    #Grant Full Access 
    Import-Csv C:\NewGroupMailboxList\NGDNFullList.csv | foreach { Add-MailboxPermission -Identity "$GMUPN@yourcorp.com" -User $_.Email -AccessRights FullAccess }

    #create a variable for the imported data
    $data = Import-Csv -Path "C:\NewGroupMailboxList\NGDNFullList.csv"

    # Convert the data to an HTML table
    $table = $data | ConvertTo-Html -Fragment

    #Grant Send as access
    Import-Csv C:\NewGroupMailboxList\NGDNSendAsList.csv | foreach { Add-RecipientPermission -Identity "$GMUPN@yourcorp.com" -Trustee $_.Email -AccessRights SendAs -Confirm:$false }

    #create a variable for the imported data
    $data = Import-Csv -Path "C:\NewGroupMailboxList\NGDNSendAsList.csv"

    # Convert the data to an HTML table
    $table1 = $data | ConvertTo-Html -Fragment
        
    #Display Permissions
    Get-MailboxPermission -Identity "$GMUPN@yourcorp.com" | sort User 
    Get-RecipientPermission -Identity "$GMUPN@yourcorp.com" | sort User
    
    #Send Mail Messages
    $SMTPServer = "smtp.office365.com"
    $SMTPPort = "587"
    $credential = Import-CliXml -Path 'C:\keypath\yourcred.xml'
    $From = "Automated <youremail@yourcorp.com>"
    $Subject = "$TaskNumber - New Group Mailbox $GMDN"
    $body = @"
<html>
<head>
<style>
    /* add any custom styles here */
</style>
</head>
<body>
   <p>Hi $Requester,</p>
<br>
   <p>A new shared mailbox was created named $GMDN :</p>
   <p>Email Address: $GMUPN@yourcorp.com</p>	
<br>
   <p>The following have been granted "Read and manage (Full Access)" access:</p>
   <p><table>$table</table></p>
<br>
   <p>The following have been granted "Send as" access:</p>	
   <p><table>$table1</table></p>
<br>
<br>
<p>Your Name<br>
Your Title <br>
Your Org<br>
(123) 456-7890<br>
youremail@yourcorp.com<br></p>

</body>
</html>
"@ 

    
    Send-MailMessage -From $From -To "$RequesterUPN@yourcorp.com" -Cc "support_distribution_list@yourcorp.com" -Subject $Subject -Body $body -BodyAsHtml -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -Credential $credential
    
   
    } # end function AddUserNewSharedMailbox