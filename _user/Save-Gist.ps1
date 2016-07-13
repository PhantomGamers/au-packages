function Save-Gist {
    function Expand-PoshString() {
        [CmdletBinding()]
        param ( [parameter(ValueFromPipeline = $true)] [string] $str)
        "@`"`n$str`n`"@" | iex
    }

    function ConvertTo-MarkdownTable($result, $Columns, $MaxErrorLength=150)
    {
        if (!$Columns) { $Columns = 'PackageName', 'Updated', 'Pushed', 'RemoteVersion', 'NuspecVersion', 'Error' }
        $res = '|' + ($Columns -join '|') + "|`r`n"
        $res += ((1..$Columns.Length | % { '|---' }) -join '') + "|`r`n"

        $result | % {
            $o = $_ | select @{N='PackageName'; E={'[{0}](https://chocolatey.org/packages/{0}/{1})' -f $_.PackageName, (max_version $_)} },
                    'Updated', 'Pushed', 'RemoteVersion', 'NuspecVersion',
                    @{N='Error'; E={
                        $err = ("$($_.Error)" -replace "`r?`n", '; ').Trim()
                        if ($err) {
                            if ($err.Length -gt $MaxErrorLength) { $err = $err.Substring(0,$MaxErrorLength) + ' ...' }
                            "[{0}](#{1})" -f $err, $_.PackageName.ToLower()
                        }
                    }}

            $res += ((1..$Columns.Length | % { $col = $Columns[$_-1]; '|' + $o.$col }) -join '') + "|`r`n"
        }

        $res
    }

    function max_version($p) {
        try {
            $n = [version]$p.NuspecVersion
            $r = [version]$p.RemoteVersion
            if ($n -gt $r) { "$n" } else { "$r" }
        } catch {}
    }

    function md_code($Text) {
        "`n" + '```'
        ($Text -join "`n").Trim()
        '```' + "`n"
    }

    "Saving results to gist"
    if (!(gcm gist.bat -ea 0)) { "ERROR: No gist.bat found. Install it using:  'gem install gist'"; return }

    $log = gc gist.md.ps1 -Raw | Expand-PoshString
    $log | Out-File gist.md

    $params = @( "--filename 'Update-AUPackages.md'")
    $params += if ($Info.Options.Gist_ID) { "--update " + $Info.Options.Gist_ID } else { '--anonymous' }

    iex -Command "`$log | gist.bat $params"
    if ($LastExitCode) { "ERROR: Gist update failed with exit code: '$LastExitCode'" }
}
