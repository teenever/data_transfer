<#
SplitMergeTransferWin.ps1 - File split, merge, and transfer tool for Windows.

Examples:
  .\SplitMergeTransferWin.ps1 -Mode split -Size 10MB -File large.iso -Prefix part_
  .\SplitMergeTransferWin.ps1 -Mode merge -File merged.iso -Parts part_a,part_b
  .\SplitMergeTransferWin.ps1 -Mode scp -Args user@host:file ./
  .\SplitMergeTransferWin.ps1 -Mode ftp -Args ftp.example.com
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('split','merge','scp','sftp','ftp')]
    [string]$Mode,
    [string]$Size,
    [string]$File,
    [string[]]$Parts,
    [string[]]$Args,
    [string]$Prefix
)

function Convert-SizeToBytes {
    <# Convert strings like 10MB or 100K to bytes #>
    param([string]$InputSize)
    if ($InputSize -match '^(\d+)(KB|MB)?$') {
        $value = [int]$matches[1]
        switch ($matches[2]) {
            'KB' { $value *= 1kb }
            'MB' { $value *= 1mb }
        }
        return $value
    }
    throw "Invalid size format: $InputSize"
}

function Split-File {
    <# Split a file into pieces #>
    param([string]$Size,[string]$File,[string]$Prefix)
    $bytes = Convert-SizeToBytes $Size
    $in = [IO.File]::OpenRead($File)
    try {
        $index = 0
        $buffer = New-Object byte[] $bytes
        while (($read = $in.Read($buffer,0,$bytes)) -gt 0) {
            $part = "${Prefix}${index}"
            $out = [IO.File]::OpenWrite($part)
            try { $out.Write($buffer,0,$read) } finally { $out.Close() }
            $index++
        }
    } finally { $in.Close() }
}

function Merge-Files {
    <# Merge files into one #>
    param([string[]]$Parts,[string]$File)
    $cmd = "copy /b " + ($Parts -join '+') + " $File"
    cmd /c $cmd | Out-Null
}

function Invoke-SCP {
    <# Call scp.exe with arguments #>
    param([string[]]$Args)
    & scp.exe @Args
}

function Invoke-SFTP {
    <# Call sftp.exe with arguments #>
    param([string[]]$Args)
    & sftp.exe @Args
}

function Invoke-FTP {
    <# Call ftp.exe with arguments #>
    param([string[]]$Args)
    & ftp.exe @Args
}

switch ($Mode) {
    'split' { Split-File -Size $Size -File $File -Prefix $Prefix }
    'merge' { Merge-Files -Parts $Parts -File $File }
    'scp'   { Invoke-SCP -Args $Args }
    'sftp'  { Invoke-SFTP -Args $Args }
    'ftp'   { Invoke-FTP -Args $Args }
    default { Write-Error "Unknown mode: $Mode" }
}


