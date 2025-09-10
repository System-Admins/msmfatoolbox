function Send-EntraUserMfaStatusReport
{
    <#test
    .SYNOPSIS
        Send Entra user MFA status report.
    .DESCRIPTION
        Collects Entra user MFA status and sends a report to the specified e-mail address.
    .PARAMETER EmailAddress
        E-mail address to send the report.
    .EXAMPLE
        Send-EntraUserMfaStatusReport -EmailAddress 'abc@contoso.com';
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

    BEGIN
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Sending Entra user MFA status report';

        # Write to log.
        Write-CustomLog -Message ('Microsoft Entra User MFA Status Report') -Level Console;
        Write-CustomLog -Message ('Gathering information from Microsoft Entra, this might take a while (be patient)') -Level Console -IndentLevel 1;

        # Get Entra user MFA status.
        $entraUserMfaStatus = Get-EntraUserMfaStatus;

        # Import header and footer.
        $header = Get-Content -Path (Join-Path -Path $Script:scriptPath -ChildPath 'private\assets\email\send-entrausermfastatusreport\header.html');
        $footer = Get-Content -Path (Join-Path -Path $Script:scriptPath -ChildPath 'private\assets\email\send-entrausermfastatusreport\footer.html');

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

        # User object array.
        $users = @();
    }
    PROCESS
    {
        # Foreach user.
        foreach ($user in $entraUserMfaStatus)
        {
            # If user is protected by MFA.
            if ($user.FullMfa -eq $true)
            {
                # Skip to next user.
                continue;
            }

            # If user is disabled.
            if ($false -eq $user.AccountEnabled)
            {
                # Skip to next user.
                continue;
            }

            # If user is external.
            if ($user.UserPrincipalName -like '*#EXT#@*')
            {
                # Skip to next user.
                continue;
            }

            # Add to object array.
            $users += $user;

            # Add user to HTML.
            $html += '<tr>' | Out-String;
            $html += "<td>$($user.DisplayName)</td>" | Out-String;
            $html += "<td>$($user.UserPrincipalName)</td>" | Out-String;
            $html += "<td>$($user.IsAdmin)</td>" | Out-String;
            $html += "<td>$($user.Apps -join ',<br>')</td>" | Out-String;
            $html += "<td>$($user.IsMfaCapable)</td>" | Out-String;
            $html += '</tr>' | Out-String;
        }

        # Add footer.
        $html += $footer | Out-String;

        # Write to log.
        Write-CustomLog -Message ('Found {0} MFA users for the MFA status report' -f $users.Count) -Level 'Verbose';
        Write-CustomLog -Message ("Exporting report to '{0}'" -f $outputFilePath) -Level 'Verbose';
        Write-CustomLog -Message ("Exporting report to '{0}'" -f $outputFilePath) -Level Console -IndentLevel 1;

        # Save status report as CSV.
        $null = $users | Select-Object -Property DisplayName,
        UserPrincipalName,
        IsAdmin,
        @{ Name = 'Apps'; Expression = { $_.Apps -join ', ' } },
        IsMfaCapable | Export-Csv -Path $outputFilePath -UseQuotes Always -Encoding utf8 -Delimiter ';' -Force;

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
        Write-CustomLog -Message ('Sending MFA status report to {0}' -f $EmailAddress) -Level Console -IndentLevel 1;

        # A UPN can also be used as -UserId.
        Send-MgUserMail -UserId (Get-EntraContext).Account -BodyParameter $params -ErrorAction Stop;
    }
    END
    {
        # Write to log.
        Write-CustomProgress @customProgress;
    }
}