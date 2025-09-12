function Send-EidUserMfaReport
{
    <#
    .SYNOPSIS
        Send Entra user MFA status report.
    .DESCRIPTION
        Collects Entra user MFA status and sends a report to the specified e-mail address.
    .PARAMETER EmailAddress
        E-mail address to send the report.
    .EXAMPLE
        Send-EidUserMfaReport -EmailAddress 'abc@contoso.com';
    #>
    [cmdletbinding()]
    [OutputType([void])]
    [ValidateScript({ $_ -match '' })]
    param
    (
        # E-mail address to send the report.
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-EmailAddress -InputObject $_ })]
        [string]$EmailAddress = ((Get-EntraContext).Account)
    )

    begin
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Sending Entra user MFA status report';

        # Get Entra user MFA status.
        $users = Get-EidUserMfaPolicy;

        # Import header and footer.
        $header = Get-Content -Path (Join-Path -Path $Script:scriptPath -ChildPath 'private\assets\send-eidusermfareport\header.html');
        $footer = Get-Content -Path (Join-Path -Path $Script:scriptPath -ChildPath 'private\assets\send-eidusermfareport\footer.html');

        # HTML.
        [string]$html = '';

        # Update header with date.
        $header = $header -replace '##DATE##', (Get-Date -Format 'yyyy-MM-dd HH:mm:ss');

        # Add header.
        $html = $header | Out-String;

        # Temporary folder path.
        [string]$tempFolderPath = [System.IO.Path]::GetTempPath();

        # File name.
        [string]$outputFileName = ('Microsoft 365 User MFA Status Report - {0}.csv' -f (Get-Date -Format 'yyyy-MM-dd'));

        # Output file path.
        [string]$outputFilePath = Join-Path -Path $tempFolderPath -ChildPath $outputFileName;
    }
    process
    {
        # Foreach user.
        foreach ($user in $users)
        {
            # If the user is not protected by a conditional access policy requiring MFA.
            if ($false -eq $user.IsProtected)
            {
                # Add user to HTML.
                $html += '<tr>' | Out-String;
                $html += "<td>$($user.UserPrincipalName)</td>" | Out-String;
                $html += "<td>$($user.DisplayName)</td>" | Out-String;
                $html += "<td>$($user.AccountEnabled)</td>" | Out-String;
                $html += "<td>$($user.UserType)</td>" | Out-String;
                $html += "<td>$($user.LastSuccessfulSignIn)</td>" | Out-String;
                $html += '</tr>' | Out-String;
            }
        }

        # Add footer.
        $html += $footer | Out-String;

        # Write to log.
        Write-CustomLog -Message ('Found {0} MFA users for the MFA status report' -f $users.Count) -Level 'Verbose';
        Write-CustomLog -Message ("Exporting report to '{0}'" -f $outputFilePath) -Level 'Verbose';

        # Save status report as CSV.
        $null = $users | Select-Object -Property Id,
        UserPrincipalName,
        DisplayName,
        AccountEnabled,
        DirSyncEnabled,
        UserType,
        @{ Name = 'PasswordPolicies'; Expression = { $_.PasswordPolicies -join '|' } },
        LastSuccessfulSignIn,
        @{ Name = 'ConditionalAccessPolicy'; Expression = { $_.ConditionalAccessPolicy -join '|' } },
        IsProtected,
        Mailbox | Export-Csv -Path $outputFilePath -UseQuotes Always -Encoding utf8 -Delimiter ';' -Force;

        # Convert CSV to Base64.
        $attachment = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($outputFilePath));

        # Create parameters for sending the e-mail.
        $params = @{
            message         = @{
                subject      = ('Microsoft 365 User MFA Status Report - {0}' -f (Get-Date -Format 'yyyy-MM-dd'));
                body         = @{
                    contentType = 'HTML';
                    content     = $html;
                };
                toRecipients = @(
                    @{
                        emailAddress = @{
                            address = $EmailAddress;
                        };
                    }
                );
                attachments  = @(
                    @{
                        '@odata.type' = '#microsoft.graph.fileAttachment';
                        name          = $outputFileName;
                        contentType   = 'text/plain';
                        contentBytes  = $attachment;
                    }
                );
            };
            saveToSentItems = 'true';
        };

        # Write to log.
        Write-CustomLog -Message ("Sending MFA status report to '{0}'" -f $EmailAddress) -Level Verbose;

        # A UPN can also be used as -UserId.
        $null = Send-MgUserMail `
            -UserId (Get-EntraContext).Account `
            -BodyParameter $params `
            -ErrorAction Stop;
    }
    end
    {
        # Write to log.
        Write-CustomProgress @customProgress;
    }
}