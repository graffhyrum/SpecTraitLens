# Restore Mechanic's lua.exe from LuaBinaries when mech setup downloads a bad file.
param(
    [string]$MechanicRoot = "C:\Tools\Mechanic"
)

$ErrorActionPreference = "Stop"

$bin = Join-Path $MechanicRoot "desktop\bin"
$luaExe = Join-Path $bin "lua.exe"
$zip = Join-Path $env:TEMP "nmwq-lua515.zip"
$extract = Join-Path $env:TEMP "nmwq-lua515"
$url = "https://downloads.sourceforge.net/project/luabinaries/5.1.5/Tools%20Executables/lua-5.1.5_Win64_bin.zip"

New-Item -ItemType Directory -Force -Path $bin | Out-Null

curl.exe -fsSL -o $zip $url
if ($LASTEXITCODE -ne 0) { throw "curl failed downloading Lua 5.1.5 ($url)" }

if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
Expand-Archive $zip $extract -Force

Copy-Item (Join-Path $extract "lua5.1.exe") $luaExe -Force
Copy-Item (Join-Path $extract "lua5.1.dll") $bin -Force

$header = Get-Content $luaExe -Encoding Byte -TotalCount 2
if ($header[0] -ne 0x4D -or $header[1] -ne 0x5A) {
    $hex = ($header | ForEach-Object { "{0:X2}" -f $_ }) -join " "
    throw "lua.exe is not a PE binary after restore (header: $hex)"
}

$version = (cmd /c "`"$luaExe`" -v 2>&1").Trim()
Write-Host "Restored $luaExe ($version)"
