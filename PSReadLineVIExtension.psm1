# {{{ Handler
Set-PSReadLineKeyHandler -Chord "c,i" -ViMode Command `
	-ScriptBlock { VIChangeInnerBlock }
Set-PSReadLineKeyHandler -Chord "c,a" -ViMode Command `
	-ScriptBlock { VIChangeOuterBlock }
Set-PSReadLineKeyHandler -Chord "d,i" -ViMode Command `
	-ScriptBlock { VIDeleteInnerBlock }
Set-PSReadLineKeyHandler -Chord "d,a" -ViMode Command `
	-ScriptBlock { VIDeleteOuterBlock }
Set-PSReadLineKeyHandler -Chord "c,s" -ViMode Command `
	-ScriptBlock { VIChangeSurround }
Set-PSReadLineKeyHandler -Chord "d,s" -ViMode Command `
	-ScriptBlock { VIDeleteSurround }
Set-PSReadLineKeyHandler -Chord "Ctrl+a" -ViMode Command `
	-ScriptBlock { VIIncrement $args[0] $args[1] }
Set-PSReadLineKeyHandler -Chord "Ctrl+x" -ViMode Command `
	-ScriptBlock { VIDecrement $args[0] $args[1] }
Set-PSReadLineKeyHandler -Chord "+,y" -ViMode Command `
	-ScriptBlock { VIGlobalYank }
Set-PSReadLineKeyHandler -Chord "+,p" -ViMode Command `
	-ScriptBlock { VIGlobalPaste }
Set-PSReadLineKeyHandler -Chord "+,P" -ViMode Command `
	-ScriptBlock { VIGlobalPaste $true }
Set-PSReadLineKeyHandler -Chord "g,e" -viMode Command `
	-ScriptBlock { ViBackwardEndOfWord }
Set-PSReadLineKeyHandler -Chord "g,E" -viMode Command `
	-ScriptBlock { VIBackwardEndOfGlob }
Set-PsReadLineKeyHandler -Chord "g,M" -viMode Command `
	-ScriptBlock { VIMiddleOfLine }
Set-PsReadLineKeyHandler -Chord "g,f" -viMode Command `
	-ScriptBlock {VIOpenFileUnderCursor }
Set-PsReadLineKeyHandler -Chord "g,m" -viMode Command `
	-ScriptBlock { VIMiddleOfScreen }
if($VIExperimental -eq $true){
	Write-Host "Using Experimental VISettings"
	Set-PSReadLineKeyHandler -Chord "g,U" -viMode Command `
	-ScriptBlock { VICapitalize }
	Set-PSReadLineKeyHandler -Chord "g,u" -viMode Command `
	-ScriptBlock { VILowerize }
	Set-PsReadLineKeyHandler -Chord 'Alt+p' -viMode Command `
	-ScriptBlock { CSHLoadPreviousFromHistory }
	Set-PsReadLineKeyHandler -Chord 'Alt+n' -viMode Command `
	-ScriptBlock { CSHLoadNextFromHistory }
	Set-PsReadLineKeyHandler -Chord 'Alt+p' -viMode Insert `
	-ScriptBlock { CSHLoadPreviousFromHistory }
	Set-PsReadLineKeyHandler -Chord 'Alt+n' -viMode Insert `
	-ScriptBlock { CSHLoadNextFromHistory }
}
#}}}
$LocalShell = New-Object -ComObject wscript.shell
$Digits = (0..9)
$Separator = "$[({})]-._ '```":\/"
$script:HistoryLine = -1
$HistorySeparator ="`r`n"
$HistoryFile = (Get-PSReadLineOption).HistorySavePath
######################################################################
# Section Function                                                   #
######################################################################
# {{{ Utility Section
function NumericArgument {
	param(
		[int]$FirstKey
	)
	$Keys = @()
	do {
		$NextEntry = ([Console]::ReadKey($true)).KeyChar.ToString()
		if($Digits -contains $NextEntry ){
			$Keys += $NextEntry
			$StillDigit = $true
		}else{
			$StillDigit = $false
		}
	}while($StillDigit -eq $true)
	return @($NextEntry, [int](@($FirstKey) + $Keys -join '') )
}
# }}}
# {{{ CSH Extension
function CSHLoadPreviousFromHistory {
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
				[ref]$Cursor)
	if($Line.Trim().Length -gt 0){
		$Line = [Regex]::Escape($Line)
		$Matches = Get-Content $HistoryFile -Delimiter $HistorySeparator | `
			Select-String -Pattern "^$Line"
		if( $Matches.Count -eq 0){
			return
		}
		${script:HistoryLine} = $Matches[-1].LineNumber 
		if($PSVersionTable.PSVersion.Major -gt 5 ){
			$Line = $Matches[-1].Line
		}else{
			$Line = $Matches[-1].Line.Trim()
		}
		[Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()
	}else{
		${script:HistoryLine}--
		$Line = (Get-Content $HistoryFile `
			-Delimiter $HistorySeparator)[${script:HistoryLine}].Trim() 
	}
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert($Line)
}

function CSHLoadNextFromHistory {
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
				[ref]$Cursor)
	if($Line.Trim().Length -gt 0){
		$Line = [Regex]::Escape($Line)
		$Matches = Get-Content $HistoryFile -Delimiter $HistorySeparator | `
			Select-String -Pattern "^$Line"
		if( $Matches.Count -eq 0){
			return
		}
		${script:HistoryLine} = $Matches[-1].LineNumber 
		if($PSVersionTable.PSVersion.Major -gt 5 ){
			$Line = $Matches[-1].Line
		}else{
			$Line = $Matches[-1].Line.Trim()
		}
		[Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()
	}else{
		$Line = (Get-Content $HistoryFile `
			-Delimiter $HistorySeparator)[${script:HistoryLine}].Trim() 
	}
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert($Line)
}

# }}}
# {{{ g function

function GetReplacement {
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
			[ref]$Cursor)
	$Movement = ([Console]::ReadKey($true)).KeyChar.ToString()
	if($Digits -contains $Movement.ToString() ){
		($Movement, $IntArgument) = NumericArgument($Movement)
	}
	if(-not($IntArgument)){
		$IntArgument = 1
	}
	$Replacement = ''
	if($Movement -ceq 'l'){
		$Replacement = $Line.Substring($Cursor, $IntArgument)
	}elseif($Movement -ceq 'h'){
		$Cursor -= $IntArgument - 1
		$Replacement = $Line.Substring($Cursor, $IntArgument)
	}elseif($Movement -ceq 'w' -and $Movement -ceq 'e'){
		$EndPos = $Line.IndexOfAny($Separator, $Cursor )
		$Replacement = $Line.SubString($Cursor, $EndPos - $Cursor )
	}elseif($Movement -ceq 'W' -and $Movement -ceq 'E'){
		$EndPos = $Line.IndexOf(' ', $Cursor )
		$Replacement = $Line.SubString($Cursor, $EndPos - $Cursor )
	}elseif($Movement -ceq 'b'){
		$StartPos = $Line.LastIndexOfAny($Separator, $Cursor )
		$Replacement = $Line.SubString($StartPos, $Cursor - $StartPos )
		$Cursor = $StartPos
	}elseif($Movement -ceq 'B'){
		$StartPos = $Line.LastIndexOf(' ', $Cursor )
		$Replacement = $Line.SubString($StartPos, $Cursor - $StartPos )
		$Cursor = $StartPos
	}elseif($Movement -ceq 'i'){
		$Quotes = New-Object system.collections.hashtable
		$Quotes["'"] = @("'","'")
		$Quotes['"'] = @('"','"')
		$Quotes["("] = @('(',')')
		$Quotes[")"] = @('(',')')
		$Quotes["b"] = @('(',')')
		$Quotes["{"] = @('{','}')
		$Quotes["}"] = @('{','}')
		$Quotes["B"] = @('{','}')
		$Quotes["["] = @('[',']')
		$Quotes["]"] = @('[',']')
		$Command = ([Console]::ReadKey($true)).KeyChar.ToString()
		if($Command -ceq 'w') {
			$StartPos = $Line.LastIndexOfAny($Separator, $Cursor )
			$EndPos = $Line.IndexOfAny($Separator, $Cursor )
			if($StartPos -gt 0 -and $EndPos -lt 0){
				$EndPos = $Line.Length
			}
			$Replacement = $Line.SubString($StartPos, $EndPos - $StartPos )
			$Cursor = $StartPos
		}elseif($Command -ceq 'W'){
			$StartPos = $Line.LastIndexOf(' ', $Cursor )
			$EndPos = $Line.IndexOf(' ', $Cursor )
			if($StartPos -gt 0 -and $EndPos -lt 0){
				$EndPos = $Line.Length
			}
			$Replacement = $Line.SubString($StartPos, $EndPos - $StartPos )
			$Cursor = $StartPos
		}elseif( $Quotes.ContainsKey($Command)){
			($StartChar,$EndChar)=$Quotes[$Command]
			$StartPos = $Line.LastIndexOf($StartChar, $Cursor )
			$EndPos = $Line.IndexOf($EndChar, $Cursor )
			if($StartPos -gt 0 -and $EndPos -lt 0){
				$EndPos = $Line.Length
			}
			$Replacement = $Line.SubString($StartPos, $EndPos - $StartPos )
			$Cursor = $StartPos
		}
	}
	return @($Cursor, $Replacement)
}

function VICapitalize {
	($Cursor, $Replacement ) = GetReplacement
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($Cursor,`
				$Replacement.Length, $Replacement.toUpper() )
}

function VILowerize {
	($Cursor, $Replacement ) = GetReplacement
	$Replacement.toLower()
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($Cursor,`
				$Replacement.Length, $Replacement.ToLower() )
}

function VIMiddleOfLine {
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	$Cursor = $Line.Length / 2
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($Cursor)
}

function VIMiddleOfScreen {
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	$Cursor = $host.UI.RawUI.WindowSize.Width / 2
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($Cursor)
}

function VIOpenFileUnderCursor {
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	$Separator = "' `""
	$StartChar = $Line.LastIndexOfAny($Separator, $Cursor) + 1
	$EndChar = $Line.IndexOfAny($Separator, $Cursor) 
	if($EndChar -eq -1){
		$EndChar = $Line.Length
	}
	Out-File -inputObject "$Line $Cursor $StartChar $EndChar" -path c:\temp\log.Txt
	$Path = $Line.Substring($StartChar, $EndChar - $StartChar)
	if( Test-PAth $Path -PAthType Leaf){
		Start-Process $ENV:EDITOR -ArgumentList $PAth -Wait -NoNewWindow
	}
}

function VIBackwardEndOfWord {
	[Microsoft.PowerShell.PSConsoleReadLine]::ViBackwardWord()
	[Microsoft.PowerShell.PSConsoleReadLine]::ViBackwardWord()
	[Microsoft.PowerShell.PSConsoleReadLine]::NextWordEnd()
}

function VIBackwardEndOfGlob {
	[Microsoft.PowerShell.PSConsoleReadLine]::ViBackwardGlob()
	[Microsoft.PowerShell.PSConsoleReadLine]::ViBackwardGlob()
	[Microsoft.PowerShell.PSConsoleReadLine]::ViEndOfGlob()
}

# }}}
# {{{ Increment/decrement

function VIDecrement( $key , $arg ){
	$Separator = "$[({})]-._ '```":"
	$Caps = $Separator + ([char]'A'..[char]'z' | `
		Foreach-Object { [char]$_ }) -join ''
	$ConditionalStatements = @('elseif','if','else')
	$BoolValues = @('true','false')
	[int]$NumericArg = 0
	[Microsoft.PowerShell.PSConsoleReadLine]::TryGetArgAsInt($arg,
		  [ref]$NumericArg, 1)
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	$EndChar = $Line.indexOfAny($Caps, $Cursor)
	$StartChar = $Line.LastIndexOfAny($Caps, $Cursor) + 1
	$IsNumeric = $true
	$IsStringStatement = $false
	if($EndChar -lt 0 -and $StartChar -gt 0){
		$EndChar = $Line.Length
	}elseif($EndChar - $StartChar -le 0){
		$IsNumeric = $false
		$EndChar = $Line.indexOfAny($Separator, $Cursor)
		$StartChar = $Line.LastIndexOfAny($Separator, $Cursor) + 1
		if($StartChar -gt 0 -and $EndChar -lt 0){
			$EndChar = $Line.Length
		}elseif($StartChar -le 0 -and $EndChar -lt 0){
			$StartChar = 0
			$EndChar = $Line.Length
		}
		$CurrentStatement = $Line.Substring($StartChar, $EndChar - $StartChar)
		if($ConditionalStatements -contains $CurrentStatement){
			$NextIndex = ([array]::IndexOf(
						$ConditionalStatements, $CurrentStatement)`
				- $NumericArg) % $ConditionalStatements.Length
			$NextVal = $ConditionalStatements[$NextIndex]
			$IsStringStatement = $true
		}elseif( $BoolValues -contains $CurrentStatement){
			$NextIndex = ([array]::IndexOf(
						$BoolValues, $CurrentStatement)`
				- $NumericArg) % $BoolValues.Length
			$NextVal = $BoolValues[$NextIndex]
			$IsStringStatement = $true
		}elseif( Test-Path Variable:VIIncrementArray){
			if( $VIIncrementArray[0] -is [array] ) {
				foreach($UserStrings in $VIIncrementArray){
					if($UserStrings -contains $CurrentStatement ){
						$NextIndex = ([array]::IndexOf(
									$UserStrings, $CurrentStatement)`
							- $NumericArg) % $UserStrings.Length
						$NextVal = $UserStrings[$NextIndex]
						$IsStringStatement = $true
					}
				}
			}else{
				if($VIIncrementArray -contains $CurrentStatement ){
					$NextIndex = ([array]::IndexOf(
								$VIIncrementArray, $CurrentStatement)`
						- $NumericArg) % $VIIncrementArray.Length
					$NextVal = $VIIncrementArray[$NextIndex]
					$IsStringStatement = $true
				}
			}
		}
	}
	if( $IsNumeric -eq $false -and $IsStringStatement -eq $false){
		return
	}
	if($IsNumeric){
		[int]$NextVal = $Line.SubString($StartChar, $EndChar - $StartChar)
		$NextVal -= $NumericArg
	}
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($StartChar,`
				$EndChar - $StartChar, $nextVal.ToString() )
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($EndChar - 1)
}

function VIIncrement( $key , $arg ){
	$Separator = "$[({})]-._ '```":"
	$Caps = $Separator + ([char]'A'..[char]'z' | `
		Foreach-Object { [char]$_ }) -join ''
	$ConditionalStatements = @('elseif','if','else')
	$BoolValues = @('true','false')
	[int]$NumericArg = 1
	[Microsoft.PowerShell.PSConsoleReadLine]::TryGetArgAsInt($arg,
		  [ref]$NumericArg, 1)
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	$EndChar = $Line.indexOfAny($Caps, $Cursor)
	$StartChar = $Line.LastIndexOfAny($Caps, $Cursor) + 1
	$IsNumeric = $true
	$IsStringStatement = $false
	if($EndChar -lt 0 -and $StartChar -gt 0){
		$EndChar = $Line.Length
	}elseif($EndChar - $StartChar -le 0){
		$IsNumeric = $false
		$EndChar = $Line.indexOfAny($Separator, $Cursor)
		$StartChar = $Line.LastIndexOfAny($Separator, $Cursor) + 1
		if($StartChar -gt 0 -and $EndChar -lt 0){
			$EndChar = $Line.Length
		}elseif($StartChar -le 0 -and $EndChar -lt 0){
			$StartChar = 0
			$EndChar = $Line.Length
		}
		$CurrentStatement = $Line.Substring($StartChar, $EndChar - $StartChar)
		if($ConditionalStatements -contains $CurrentStatement){
			$NextIndex = ([array]::IndexOf(
						$ConditionalStatements, $CurrentStatement)`
				+ $NumericArg) % $ConditionalStatements.Length
			$NextVal = $ConditionalStatements[$NextIndex]
			$IsStringStatement = $true
		}elseif( $BoolValues -contains $CurrentStatement){
			$NextIndex = ([array]::IndexOf(
						$BoolValues, $CurrentStatement)`
				- $NumericArg) % $BoolValues.Length
			$NextVal = $BoolValues[$NextIndex]
			$IsStringStatement = $true
		}elseif( Test-Path Variable:VIIncrementArray){
			if( $VIIncrementArray[0] -is [array] ) {
				foreach($UserStrings in $VIIncrementArray){
					if($UserStrings -contains $CurrentStatement ){
						$NextIndex = ([array]::IndexOf(
									$UserStrings, $CurrentStatement)`
							+ $NumericArg) % $UserStrings.Length
						$NextVal = $UserStrings[$NextIndex]
						$IsStringStatement = $true
					}
				}
			}else{
				if($VIIncrementArray -contains $CurrentStatement ){
					$NextIndex = ([array]::IndexOf(
								$VIIncrementArray, $CurrentStatement)`
						+ $NumericArg) % $VIIncrementArray.Length
					$NextVal = $VIIncrementArray[$NextIndex]
					$IsStringStatement = $true
				}
			}
		}
	}
	if( $IsNumeric -eq $false -and $IsStringStatement -eq $false){
		return
	}
	if($IsNumeric){
		[int]$NextVal = $Line.SubString($StartChar, $EndChar - $StartChar)
		$NextVal += $NumericArg
	}
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($StartChar,`
				$EndChar - $StartChar, $NextVal.ToString() )
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($EndChar - 1)
}
# }}}

# {{{ InnerBlock
function VIChangeInnerBlock(){
	VIDeleteInnerBlock
	[Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode()
}

function VIDeleteInnerBlock(){
	$Caps = "$[({})]-._ '```"\/" + ([char]'A'..[char]'Z' | `
		Foreach-Object { [char]$_ }) -join ''
	$Quotes = New-Object system.collections.hashtable
	$Quotes["'"] = @("'","'")
	$Quotes['"'] = @('"','"')
	$Quotes["("] = @('(',')')
	$Quotes[")"] = @('(',')')
	$Quotes["b"] = @('(',')')
	$Quotes["{"] = @('{','}')
	$Quotes["}"] = @('{','}')
	$Quotes["B"] = @('{','}')
	$Quotes["["] = @('[',']')
	$Quotes["]"] = @('[',']')
	$Quotes[">"] = @('<','>')
	$Quotes["<"] = @('<','>')
	$Quotes["w"] = @("$[({})]-._ '```"\/", "$[({})]-._ '```"\/")
	$Quotes["W"] = @(' ', ' ')
	$Quotes['C'] = @($Caps, $Caps)
	$Quote = ([Console]::ReadKey($true)).KeyChar
	if( $Quotes.ContainsKey($quote.ToString())){
		$Line = $Null
		$Cursor = $Null
		[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
				[ref]$Cursor)
		$OpeningQuotes = $Quotes[$Quote.ToString()][0]
		$ClosingQuotes = $Quotes[$Quote.ToString()][1]
		if($ClosingQuotes.length -gt 1){
			$EndChar=$Line.IndexOfAny($ClosingQuotes, $Cursor)
		}else{
			$EndChar=$Line.IndexOf($ClosingQuotes, $Cursor)
		}
		if($OpeningQuotes.Length -gt 1){
			$StartChar=$Line.LastIndexOfAny($OpeningQuotes, $Cursor) + 1
		}else{
			$StartChar=$Line.LastIndexOf($OpeningQuotes, $Cursor) + 1
		}
		if(($OpeningQuotes.Length -gt 1 -or $Quote -ceq 'W' -or $Quote -ceq 'C'`
				) -and $EndChar -lt 0){
			$EndChar = $Line.Length
		}
		if(($OpeningQuotes.Length -gt 1 -or $Quote -ceq 'W')`
				-and $StartChar -lt 0){
			$StartChar = 0
		}
		if( $Quote.ToString() -eq 'C'){
			$StartChar -= 1
		}
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar )
		if($Quote.ToString() -ceq 'w'){
			[Microsoft.PowerShell.PSConsoleReadLine]::DeleteWord()
		}elseif( $Quote.ToString() -ceq 'W'){
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteGlob()
		}elseif($Quote.ToString() -eq '"' -or $Quote.ToString() -eq "'" ){
			$LocalShell.SendKeys($Quote)
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToBeforeChar()
		}elseif( $Quote.ToString() -eq '(' -or $Quote.ToString() -eq '[' -or `
				$Quote.ToString() -eq '{' -or $Quote.ToString() -ceq 'B' `
				-or $Quote.ToString() -ceq 'b' -or $Quote.ToString() -ceq ')' `
				-or $Quote.ToString() -ceq ']' -or $Quote.ToString() -ceq '}' `
				-or $Quote.ToString() -ceq '<' -or $Quote.ToString() -ceq '>' `
				){
			$LocalShell.SendKeys("{$($ClosingQuotes.ToString())}")
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToBeforeChar()
			out-file -inputobject "CI : {$($ClosingQuotes.ToString())}" -path c:\temp\log.txt
		} elseif( $Quote.ToString() -eq 'C') {
			if($EndChar -eq $Line.Length){
				[Microsoft.PowerShell.PSConsoleReadLine]::DeleteToEnd()
			}elseif($Line[$EndChar] -eq ' '){
				[Microsoft.PowerShell.PSConsoleReadLine]::DeleteWord()
			}else {
				$LocalShell.SendKeys($Line[$EndChar])
				[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToBeforeChar()
			}
		}
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($StartChar)
	}
}

# }}}

# {{{ OuterBlock

function VIChangeOuterBlock(){
	VIDeleteOuterBlock
	[Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode()
}

function VIDeleteOuterBlock(){
	$Quotes = New-Object system.collections.hashtable
	$Quotes["'"] = @("'","'")
	$Quotes['"'] = @('"','"')
	$Quotes["("] = @('(',')')
	$Quotes[")"] = @('(',')')
	$Quotes["b"] = @('(',')')
	$Quotes["{"] = @('{','}')
	$Quotes["}"] = @('{','}')
	$Quotes["B"] = @('{','}')
	$Quotes["["] = @('[',']')
	$Quotes["]"] = @('[',']')
	$Quotes[">"] = @('<','>')
	$Quotes["<"] = @('<','>')
	$Quotes["w"] = @("$[({})]-._ '```"\/", "$[({})]-._ '```"\/")
	$Quotes["W"] = @(' ', ' ')
	$Quote = ([Console]::ReadKey($true)).KeyChar
	if( $Quotes.ContainsKey($quote.ToString())){
		$Line = $Null
		$Cursor = $Null
		[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
				[ref]$Cursor)
		$OpeningQuotes = $Quotes[$Quote.ToString()][0]
		$ClosingQuotes = $Quotes[$Quote.ToString()][1]
		if($ClosingQuotes.Length -gt 1){
			$EndChar=$Line.IndexOfAny($ClosingQuotes, $Cursor) + 1
		}else{
			$EndChar=$Line.IndexOf($ClosingQuotes, $Cursor) +1
		}
		if($OpeningQuotes.length -gt 1){
			$StartChar=$Line.LastIndexOfAny($OpeningQuotes, $Cursor)
		}else{
			$StartChar=$Line.LastIndexOf($OpeningQuotes, $Cursor)
		}
		if(($OpeningQuotes.Length -gt 1 -or $Quote -ceq 'W') `
				-and $EndChar -eq 0){
			$EndChar = $Line.Length
		}
		if(($OpeningQuotes.Length -gt 1 -or $Quote -ceq 'W')`
				-and $StartChar -lt 0){
			$StartChar = 0
		}
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar + 1)
		if($Quote.ToString() -ceq 'w'){
			[Microsoft.PowerShell.PSConsoleReadLine]::DeleteWord()
		}elseif( $Quote.ToString() -ceq 'W'){
			if($StartChar -eq 0){
				$StartChar--
			}
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar + 1 )
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteGlob()
		}elseif($Quote.ToString() -eq '"' -or $Quote.ToString() -eq "'" ){
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar )
			$LocalShell.SendKeys($Quote)
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToChar()
		}elseif( $Quote.ToString() -eq '(' -or $Quote.ToString() -eq '[' -or `
				$Quote.ToString() -eq '{' -or $Quote.ToString() -eq ')' -or `
				$Quote.ToString() -eq ']' -or $Quote.ToString() -eq '}'-or `
				$Quote.ToString() -ceq '<' -or $Quote.ToString() -ceq '>' -or `
				$Quote.ToString() -ceq 'b' -or $Quote.ToString() -ceq 'B'){
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar )
			$LocalShell.SendKeys("{" + $ClosingQuotes.ToString() + "}")
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToChar()
		} elseif( $Quote.ToString() -eq 'C') {
			$LocalShell.SendKeys($Line[$EndChar])
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToChar()

		}
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($StartChar)
	}
}
# }}}

# {{{ Surround
function VIChangeSurround(){
	# inspired by tpope vim-surround
	# https://github.com/tpope/vim-surround
	$Quotes = @{
		"'" = @("'","'");
		'"'= @('"','"');
		"(" = @('(',')');
		"{" = @('{','}');
		"[" = @('[',']');
	}
	$Line = $Null
	$Cursor = $Null
	$Search = ([Console]::ReadKey($true)).KeyChar
	$Replace = ([Console]::ReadKey($true)).KeyChar
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
			[ref]$Cursor)
	$SearchOpeningQuotes = $Quotes[$Search.ToString()][0]
	$SearchClosingQuotes = $Quotes[$Search.ToString()][1]
	$ReplaceOpeningQuotes = $Quotes[$Replace.ToString()][0]
	$ReplaceClosingQuotes = $Quotes[$Replace.ToString()][1]
	$EndChar=$Line.indexOf($SearchClosingQuotes, $Cursor)
	$StartChar=$Line.LastIndexOf($SearchOpeningQuotes, $Cursor)
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($StartChar, `
		1,$ReplaceOpeningQuotes )
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($EndChar, `
		1,$ReplaceClosingQuotes )
}

function VIDeleteSurround(){
	# inspired by tpope vim-surround
	# https://github.com/tpope/vim-surround
	$Quotes = @{
		"'" = @("'","'");
		'"'= @('"','"');
		"(" = @('(',')');
		"b" = @('(',')');
		"{" = @('{','}');
		# "B" = @('{','}');
		"[" = @('[',']');
	}
	$Line = $Null
	$Cursor = $Null
	$Search = ([Console]::ReadKey($true)).KeyChar
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
			[ref]$Cursor)
	$SearchOpeningQuotes = $Quotes[$Search.ToString()][0]
	$SearchClosingQuotes = $Quotes[$Search.ToString()][1]
	$EndChar=$Line.indexOf($SearchClosingQuotes, $Cursor)
	$StartChar=$Line.LastIndexOf($SearchOpeningQuotes, $Cursor)
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($StartChar, `
		1,'')
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($EndChar - 1, `
		1,'' )
}
# }}}

# {{{ Global Clipboard
function VIGlobalYank (){
	$Line = $Null
	$Cursor = $Null
	[Microsoft.Powershell.PSConsoleReadline]::GetBufferState([ref] $Line,
			[ref] $Cursor)
	Set-ClipBoard $Line
}

function VIGlobalPaste (){
	param(
		$Before=$False
	)
	$Line = $Null
	$Cursor = $Null
	[Microsoft.Powershell.PSConsoleReadline]::GetBufferState([ref] $Line,
			[ref] $Cursor)
	if(-not ($Before )){
		[Microsoft.Powershell.PSConsoleReadline]::SetCursorPosition($Cursor + 1)
	}
	(Get-ClipBoard).Split("`n") | Foreach-Object {
		[Microsoft.Powershell.PSConsoleReadline]::Insert( `
				$_.Replace("`t",'  ') )
		[Microsoft.Powershell.PSConsoleReadline]::AddLine()
	}
}
# }}}

Export-ModuleMember -Function 'VIDecrement', 'VIIncrement', `
	'VIChangeInnerBlock', 'VIDeleteInnerBlock', 'VIChangeOuterBlock', `
	'VIDeleteOuterBlock', 'VIChangeSurround', 'VIDeleteSurround', `
	'VIGlobalYank', 'VIGlobalPaste'
################################################################################
# Author - belot.nicolas@gmail.com                                             #
################################################################################
# CHANGELOG                                                                    #
################################################################################
# DONE: Change Quotes declaration to be case sensitive (W)                     #
# DONE: Add Handler for Next Camel Word (Maybe cd and cD)                      #
#       Should be ciC and diC                                                  #
# VERSION: 0.0.1                                                               #
# DONE: Use compatible Ps5 char range operator                                 #
# VERSION: 0.0.2                                                               #
# DONE: Add function to access global clipboard                                #
# DONE: Delete must add erase text in register  (VIDelete*)                    #
# VERSION: 0.0.3                                                               #
# FIXED: Outter Text malfunction when word contains special char               #
# FIXED: [cd]iW do nothing                                                     #
# DONE: Change Inner Cap should work with endOfWord                            #
# DONE: Change Inner Cap should work with endOfLine                            #
# VERSION: 0.0.4                                                               #
# DONE: (In|De)Crement do not work at end of line                              #
# DONE: Use all exception numeric for inc or dec                               #
# VERSION: 1.0.0                                                               #
# FIXED: ciC problem with end of word                                          #
# FIXED: Global paste does not insert at correct place                         #
# FIXED: Remove new line after paste                                           #
# FIXED: Increment/Decrement return error when cursor is not on number         #
# DONE: Increment if/elseif/else                                               #
# FIXED:Increment take the first cond statement found                          #
# DONE: Increment true/false                                                   #
# VERSION: 1.0.1                                                               #
# DONE: Add user defined increment array                                       #
# FIXED: Increment does not support end of line                                #
# VERSION: 1.0.2                                                               #
# FIXED: Increment crash when line contains only one word                      #
# FIXED: ciw doesn't consider path separtor                                    #
# VERSION: 1.0.3                                                               #
# DONE: Implement gU and gu operator                                           #
# FIXED: Preserve line end in global paste                                     #
# DONE: Implement gE and ge operator                                           #
# DONE: add [ai]b as an equivalent to [ai][()]                                 # 
# NOTE: DigitArgument() do not read previous keysend                           #
# DONE: Add ESC+P ESC+N CSH equivalent (not really vi function)                #
# VERSION: 1.0.4                                                               #
# FIXED: add a[ movement                                                       # 
# DONE: map gM (go to midlle of line )                                         #
# DONE: map gf (Edit File under cursor)                                        #
# DONE: add i< i> a< a>                                                        #
# DONE: add [ai]B as an equivalent to [ai][{}]                                 #
# VERSION: 1.0.5                                                               #
# FIXME: B to not work                                                         # 
# FIXED: Use PsReadLine get option                                             #
# FIXME: Get-Content do not remove delim in posh5                              #
# HEAD:                                                                        #
################################################################################
# {{{CODING FORMAT                                                             #
################################################################################
# Variable = CamelCase                                                         #
# TabSpace = 4                                                                 #
# Max Line Width = 80                                                          #
# Bracket Style : OTBS                                                         #
################################################################################
