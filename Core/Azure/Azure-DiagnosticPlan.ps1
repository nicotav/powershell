#Requires -Version 5.1
<#
.SYNOPSIS
    Azure/Entra ID diagnostic plan for comprehensive tenant health check.

.DESCRIPTION
    Interactive diagnostic workflow that runs multiple Azure AD checks
    and provides actionable insights for common issues.

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Azure/Azure-DiagnosticPlan.ps1')

    Requires: Microsoft.Graph PowerShell module
    Requires: Appropriate Azure AD permissions
#>

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          AZURE/ENTRA ID DIAGNOSTIC PLAN                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check modules
$requiredModules = @('Microsoft.Graph.Users', 'Microsoft.Graph.Identity.SignIns', 'Microsoft.Graph.Reports')
$missingModules = @()

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        $missingModules += $module
    }
}

if ($missingModules) {
    Write-Host "⚠ Missing required modules:" -ForegroundColor Yellow
    $missingModules | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
    exit
}

# Connect to Microsoft Graph
try {
    $context = Get-MgContext
    if (-not $context) {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All", "Policy.Read.All", "UserAuthenticationMethod.Read.All" -ErrorAction Stop
        Write-Host "✓ Connected successfully" -ForegroundColor Green
    } else {
        Write-Host "✓ Already connected to Microsoft Graph" -ForegroundColor Green
    }
    Write-Host ""
} catch {
    Write-Host "✗ Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
    exit
}

# Diagnostic Menu
Write-Host "Select diagnostic checks to perform:" -ForegroundColor Cyan
Write-Host "1. User Account Health (disabled, inactive, stale accounts)" -ForegroundColor Gray
Write-Host "2. MFA Compliance Check" -ForegroundColor Gray
Write-Host "3. Sign-In Activity Analysis" -ForegroundColor Gray
Write-Host "4. Conditional Access Policy Review" -ForegroundColor Gray
Write-Host "5. License Assignment Check" -ForegroundColor Gray
Write-Host "6. Guest User Audit" -ForegroundColor Gray
Write-Host "7. Admin Role Assignments" -ForegroundColor Gray
Write-Host "8. Full Diagnostic (All checks)" -ForegroundColor Yellow
Write-Host ""

$choice = Read-Host "Select option (1-8)"

function Test-UserAccountHealth {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "USER ACCOUNT HEALTH CHECK" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    $users = Get-MgUser -All -Property DisplayName,UserPrincipalName,AccountEnabled,CreatedDateTime,SignInActivity
    
    $disabledUsers = $users | Where-Object { -not $_.AccountEnabled }
    $inactiveUsers = $users | Where-Object { 
        $_.SignInActivity.LastSignInDateTime -and 
        $_.SignInActivity.LastSignInDateTime -lt (Get-Date).AddDays(-90) 
    }
    
    Write-Host "Total Users:          $($users.Count)" -ForegroundColor White
    Write-Host "Disabled Accounts:    $($disabledUsers.Count)" -ForegroundColor $(if($disabledUsers.Count -gt 0){'Yellow'}else{'Green'})
    Write-Host "Inactive (>90 days):  $($inactiveUsers.Count)" -ForegroundColor $(if($inactiveUsers.Count -gt 0){'Yellow'}else{'Green'})
    Write-Host ""

    if ($disabledUsers.Count -gt 0) {
        Write-Host "⚠ Disabled accounts should be reviewed and removed if no longer needed" -ForegroundColor Yellow
    }
    if ($inactiveUsers.Count -gt 0) {
        Write-Host "⚠ Inactive accounts pose security risks - consider disabling or removing" -ForegroundColor Yellow
    }
}

function Test-MFACompliance {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "MFA COMPLIANCE CHECK" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    $users = Get-MgUser -All -Property DisplayName,UserPrincipalName,Id
    $mfaEnabled = 0
    $mfaDisabled = 0

    foreach ($user in $users) {
        try {
            $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction SilentlyContinue
            $hasMFA = $authMethods | Where-Object { 
                $_.AdditionalProperties.'@odata.type' -match 'phone|authenticator|fido2|oath'
            }
            if ($hasMFA) { $mfaEnabled++ } else { $mfaDisabled++ }
        } catch {
            $mfaDisabled++
        }
    }

    $complianceRate = [math]::Round(($mfaEnabled / $users.Count) * 100, 2)
    
    Write-Host "MFA Enabled:          $mfaEnabled" -ForegroundColor Green
    Write-Host "MFA Disabled:         $mfaDisabled" -ForegroundColor Red
    Write-Host "Compliance Rate:      $complianceRate%" -ForegroundColor $(if($complianceRate -ge 80){'Green'}elseif($complianceRate -ge 50){'Yellow'}else{'Red'})
    Write-Host ""

    if ($complianceRate -lt 100) {
        Write-Host "✓ Recommendation: Enforce MFA through Conditional Access policies" -ForegroundColor Yellow
        Write-Host "  Target: 100% MFA coverage for all users" -ForegroundColor Gray
    }
}

function Test-SignInActivity {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "SIGN-IN ACTIVITY ANALYSIS" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    $startDate = (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $signIns = Get-MgAuditLogSignIn -Filter "createdDateTime ge $startDate" -All
    
    $totalSignIns = $signIns.Count
    $failedSignIns = ($signIns | Where-Object { $_.Status.ErrorCode -ne 0 }).Count
    $successRate = [math]::Round((($totalSignIns - $failedSignIns) / $totalSignIns) * 100, 2)

    Write-Host "Last 7 Days Sign-Ins: $totalSignIns" -ForegroundColor White
    Write-Host "Failed Sign-Ins:      $failedSignIns" -ForegroundColor $(if($failedSignIns -gt 100){'Red'}elseif($failedSignIns -gt 50){'Yellow'}else{'Green'})
    Write-Host "Success Rate:         $successRate%" -ForegroundColor $(if($successRate -ge 95){'Green'}elseif($successRate -ge 90){'Yellow'}else{'Red'})
    Write-Host ""

    if ($failedSignIns -gt 0) {
        $topFailures = $signIns | Where-Object { $_.Status.ErrorCode -ne 0 } | 
            Group-Object { $_.Status.FailureReason } | 
            Sort-Object Count -Descending | 
            Select-Object -First 3

        Write-Host "Top Failure Reasons:" -ForegroundColor Yellow
        $topFailures | ForEach-Object {
            Write-Host "  • $($_.Name): $($_.Count)" -ForegroundColor Red
        }
    }
}

switch ($choice) {
    "1" { Test-UserAccountHealth }
    "2" { Test-MFACompliance }
    "3" { Test-SignInActivity }
    "4" { Write-Host "✓ Use Get-ConditionalAccessPolicies.ps1 for detailed review" -ForegroundColor Yellow }
    "5" { Write-Host "✓ License check - Coming soon" -ForegroundColor Yellow }
    "6" { Write-Host "✓ Guest audit - Coming soon" -ForegroundColor Yellow }
    "7" { Write-Host "✓ Admin roles - Coming soon" -ForegroundColor Yellow }
    "8" {
        Test-UserAccountHealth
        Test-MFACompliance
        Test-SignInActivity
    }
    default {
        Write-Host "Invalid selection" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Diagnostic check completed" -ForegroundColor Green
