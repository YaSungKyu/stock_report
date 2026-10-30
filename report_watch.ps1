# Announce a missing gapbet report with a toast that stays until dismissed.
# Its own scheduled task (gapbet_report_watch), not a step inside the wrappers: a Ctrl+C
# (0xC000013A) or a hang takes the wrapper console down with claude, and the 10-01 / 10-27
# weekly-limit failures reset outside the NXT window, so being told is the only recovery.
# Before 17:00 it checks the preclose report, after it the post-close scan report.
# ASCII only (cp949-safe).
$main  = "C:\Projects\ai"
$today = (Get-Date).ToString("yyyy-MM-dd")
if ((Get-Date).Hour -lt 17) {
    $what = "preclose (B mode)"; $file = "gapbet_preclose_$today.md"; $log = "gapbet_preclose_$today.log"
    $when = "The closing auction ends 15:30"
} else {
    $what = "post-close scan (A mode)"; $file = "gapbet_report_$today.md"; $log = "gapbet_$today.log"
    $when = "The NXT after-market closes 20:00"
}
if (Test-Path (Join-Path $main "docs\gapbet\$file")) { exit 0 }

$out = & python "$main\reports\market_open.py" $today 2>&1
if ($LASTEXITCODE -eq 1) { exit 0 }    # holiday: no report is expected

$body = "No $what report for $today -- every scheduled attempt failed. $when. Log: reports\logs\$log"
Add-Content -Path "$main\reports\logs\$log" -Value "[$((Get-Date).ToString('HH:mm:ss'))] watch: $body" -Encoding UTF8

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$esc = [System.Security.SecurityElement]::Escape($body)
$xml.LoadXml("<toast scenario=`"reminder`"><visual><binding template=`"ToastGeneric`"><text>gapbet: report missing</text><text>$esc</text></binding></visual><actions><action content=`"OK`" arguments=`"ok`" activationType=`"system`"/></actions></toast>")
$app = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show([Windows.UI.Notifications.ToastNotification]::new($xml))
