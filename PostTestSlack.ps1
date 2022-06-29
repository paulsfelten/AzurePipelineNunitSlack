Param(
 [String]$browser,
 [String]$server,
 [String]$productFramework,
 [String]$buildId,
 [String]$agentTempDir,
 [String]$org,
 [String]$proj
)

try {
	cd $agentTempDir
	$trxFile = Get-ChildItem -Path ./TestResults/*.trx | %{$_.FullName} | Select-Object -First 1
	echo ".trx file: $trxFile"
	$passed = ""
	$failed = ""
	$duration = ""

	foreach($line in Get-Content $trxFile) {
		if($line -match '<Times creation="(?<creation>.+)" queuing="(?<queuing>.+)" start="(?<start>.+)" finish="(?<finish>.+)" ') {
		  $dt=[datetime]$($Matches.finish)-[datetime]$($Matches.start)
		  if($dt.Hours -eq 0) {
			  $duration=$dt.Minutes.ToString() + "m " + $dt.Seconds.ToString() + "s"
		  }
		  else {
			  $duration=$dt.Hours.ToString() + "h " + $dt.Minutes.ToString() + "m " + $dt.Seconds.ToString() + "s"
		  }
		}
		
		if($line -match '<Counters total="(?<total>.+)" executed="(?<executed>.+)" passed="(?<passed>.+)" failed="(?<failed>.+)" error="(?<error>.+)" ' ) {
			$passed=$($Matches.passed)
			$failed=$($Matches.failed)

			$uriSlack = "<slack-webhook-here>"
            $body = ConvertTo-Json @{ text = "<https://dev.azure.com/$org/$proj/_build/results?buildId=$buildId&view=results|Test Results>: $passed :arrow_up: $failed :arrow_down: in $duration.`n$productFramework / $server / $browser" }                          
			Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json' | Out-Null
		} 
	}
}
catch {
  echo "Update to Slack hit a snag..."
}
