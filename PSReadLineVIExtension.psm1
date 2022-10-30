# {{{ Handler
Set-PSReadLineKeyHandler -Chord "c,i" -ViMode Command `
	-ScriptBlock { VIChangeInnerBlock } `
	-Description 'Change Inner block'
Set-PSReadLineKeyHandler -Chord "c,a" -ViMode Command `
	-ScriptBlock { VIChangeOuterBlock } `
	-Description 'Change outter block'
Set-PSReadLineKeyHandler -Chord "d,i" -ViMode Command `
	-ScriptBlock { VIDeleteInnerBlock } `
	-Description 'Delete Inner Word'
Set-PSReadLineKeyHandler -Chord "d,a" -ViMode Command `
	-ScriptBlock { VIDeleteOuterBlock } `
	-Description 'Delete Outter Word'
Set-PSReadLineKeyHandler -Chord "c,s" -ViMode Command `
	-ScriptBlock { VIChangeSurround } `
	-Description 'Change Surrounding'
Set-PSReadLineKeyHandler -Chord "d,s" -ViMode Command `
	-ScriptBlock { VIDeleteSurround } `
	-Description 'Delete Surrounding'
Set-PSReadLineKeyHandler -Chord "Ctrl+a" -ViMode Command `
	-ScriptBlock { VIIncrement $args[0] $args[1] } `
	-Description 'Increment Argument'
Set-PSReadLineKeyHandler -Chord "Ctrl+x" -ViMode Command `
	-ScriptBlock { VIDecrement $args[0] $args[1] } `
	-Description 'Decrement Argument'
Set-PSReadLineKeyHandler -Chord "+,y" -ViMode Command `
	-ScriptBlock { VIGlobalYank } `
	-Description 'Yank CommandLine to system clipboard'
Set-PSReadLineKeyHandler -Chord "+,p" -ViMode Command `
	-ScriptBlock { VIGlobalPaste } `
	-Description 'Paste system clipboard at cursor'
Set-PSReadLineKeyHandler -Chord "+,P" -ViMode Command `
	-ScriptBlock { VIGlobalPasteBefore} `
	-Description 'Paste system clipboard before cursor'
Set-PSReadLineKeyHandler -Chord "g,e" -viMode Command `
	-ScriptBlock { ViBackwardEndOfWord } `
	-Description 'Move to End of previous word'
Set-PSReadLineKeyHandler -Chord "g,E" -viMode Command `
	-ScriptBlock { VIBackwardEndOfGlob } `
	-Description 'Move to End of previous glob'
Set-PsReadLineKeyHandler -Chord "g,M" -viMode Command `
	-ScriptBlock { VIMiddleOfLine } `
	-Description 'Move to Middle of Line'
Set-PsReadLineKeyHandler -Chord "g,f" -viMode Command `
	-ScriptBlock {VIOpenFileUnderCursor } `
	-Description 'Open File under cursor'
Set-PsReadLineKeyHandler -Chord "g,m" -viMode Command `
	-ScriptBlock { VIMiddleOfScreen } `
	-Description 'Move to Middle of Screen'
Set-PsReadLineKeyHandler -Chord "g,P" -viMode Command `
	-ScriptBlock {VIgPasteBefore } `
	-Description "Paste Before and put cursor after yanked text"
Set-PsReadLineKeyHandler -Chord "g,p" -viMode Command `
	-ScriptBlock {VIgPasteAfter } `
	-Description "Paste after and put cursor after yanked text"
Set-PsReadlineKeyHandler -Chord ':,w' -ViMode Command `
	-ScriptBlock {
		[Microsoft.PowerShell.PSConsoleReadLine]::ValidateAndAcceptLine()
	} `
	-Description 'Validate and AcceptLine'
Set-PsReadlineKeyHandler -Chord ':,x' -ViMode Command `
	-ScriptBlock {
		[Microsoft.PowerShell.PSConsoleReadLine]::ValidateAndAcceptLine()
	} `
	-Description 'Validate and AcceptLine'
Set-PsReadlineKeyHandler -Chord ':,q' -ViMode Command `
	-ScriptBlock {
		[Microsoft.PowerShell.PSConsoleReadLine]::CancelLine()
	} `
	-Description 'Cancel Line'
if($VIExperimental -eq $true){
	Write-Host "Using Experimental VISettings"
	Set-PSReadLineKeyHandler -Chord "g,U" -viMode Command `
	-ScriptBlock { VICapitalize } `
	-Description 'Capitalize'
	Set-PSReadLineKeyHandler -Chord "g,u" -viMode Command `
	-ScriptBlock { VILowerize } `
	-Description 'Lowerize'
	Set-PSReadLineKeyHandler -Chord "g,alt+2" -viMode Command `
	-ScriptBlock { VIChangeCase } `
	-Description 'Change Case'
	Set-PSReadLineKeyHandler -Chord "g,~" -viMode Command `
	-ScriptBlock { VIChangeCase } `
	-Description 'Change Case'
	Set-PsReadLineKeyHandler -Chord 'Alt+p' -viMode Command `
	-ScriptBlock { CSHLoadPreviousFromHistory } `
	-Description 'Load Previous entry From History '
	Set-PsReadLineKeyHandler -Chord 'Alt+n' -viMode Command `
	-ScriptBlock { CSHLoadNextFromHistory } `
	-Description 'Load Next entry From History '
	Set-PsReadLineKeyHandler -Chord 'Alt+p' -viMode Insert `
	-ScriptBlock { CSHLoadPreviousFromHistory } `
	-Description 'Load Previous entry From History '
	Set-PsReadLineKeyHandler -Chord 'Alt+n' -viMode Insert `
	-ScriptBlock { CSHLoadNextFromHistory } `
	-Description 'Load Next entry From History '
	Set-PsReadLineKeyHandler -Chord "Ctrl+)" -viMode Command `
	-ScriptBlock { VIGetHelp } `
	-Description 'Open Help for Command under cursor'
	Set-PsReadLineKeyHandler -Chord "Ctrl+)" -viMode Insert `
	-ScriptBlock { VIGetHelp } `
	-Description 'Open Help for Command under cursor'
	Set-PSReadlineKeyHandler -Chord "z,=" -ScriptBlock { VIZWordSubstitution } `
		-ViMode Command -Description "List similar CmdLet"
}
#}}}
$LocalShell = New-Object -ComObject wscript.shell
$Digits = (0..9)
$Separator = "$[({})]-._ '```":\/"
$CmdLEtSeparator =  "$[({})]._ '```":\/"
$script:HistoryLine = -1
$HistorySeparator ="`r`n"
$HistoryFile = (Get-PSReadLineOption).HistorySavePath
$SBDisplayChoice = {
	param([array]$List)
	$Msg = "`n"
	for($i=0;$i -lt $List.Count ;$i++){
		$Msg+= "$($i+1) : $($List[$i])`n"
		# [Console]::Write( "$i : $($List[$i]) `n")
	}
	$Choice = Read-Host "$Msg Enter the correction number or press enter"
	if( $Choice -gt 0 -or $Choice -le $List.Count){
		return $List[$Choice - 1]
	}else{
		return $null
	}
}
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

function LevenstienDistance {

# get-ld.ps1 (Levenshtein Distance)
# Levenshtein Distance is the # of edits it takes to get from 1 string to another
# This is one way of measuring the "similarity" of 2 strings
# Many useful purposes that can help in determining if 2 strings are similar possibly
# with different punctuation or misspellings/typos.
#
########################################################

# Putting this as first non comment or empty line declares the parameters
# the script accepts
###########
param([string] $first, [string] $second, [switch] $ignoreCase)

# No NULL check needed, why is that?
# PowerShell parameter handling converts Nulls into empty strings
# so we will never get a NULL string but we may get empty strings(length = 0)
#########################

$len1 = $first.length
$len2 = $second.length

# If either string has length of zero, the # of edits/distance between them
# is simply the length of the other string
#######################################
if($len1 -eq 0)
{ return $len2 }

if($len2 -eq 0)
{ return $len1 }

# make everything lowercase if ignoreCase flag is set
if($ignoreCase -eq $true)
{
  $first = $first.tolowerinvariant()
  $second = $second.tolowerinvariant()
}

# create 2d Array to store the "distances"
$dist = new-object -type 'int[,]' -arg ($len1+1),($len2+1)

# initialize the first row and first column which represent the 2
# strings we're comparing
for($i = 0; $i -le $len1; $i++) 
{  $dist[$i,0] = $i }
for($j = 0; $j -le $len2; $j++) 
{  $dist[0,$j] = $j }

$cost = 0

for($i = 1; $i -le $len1;$i++)
{
  for($j = 1; $j -le $len2;$j++)
  {
    if($second[$j-1] -ceq $first[$i-1])
    {
      $cost = 0
    }
    else   
    {
      $cost = 1
    }
    
    # The value going into the cell is the min of 3 possibilities:
    # 1. The cell immediately above plus 1
    # 2. The cell immediately to the left plus 1
    # 3. The cell diagonally above and to the left plus the 'cost'
    ##############
    # I had to add lots of parentheses to "help" the Powershell parser
    # And I separated out the tempmin variable for readability
    $tempmin = [System.Math]::Min(([int]$dist[($i-1),$j]+1) , ([int]$dist[$i,($j-1)]+1))
    $dist[$i,$j] = [System.Math]::Min($tempmin, ([int]$dist[($i-1),($j-1)] + $cost))
  }
}

# the actual distance is stored in the bottom right cell
return $dist[$len1, $len2];
}
# }}}
# {{{ Vi Help
function InvokeHelp {
	param($Command)
	$CmdType = Get-Command $Command.Trim()
	if( $null -eq $CmdType  ){
		start-process "pwsh" -argumentlist ('-noprofile','-command', 'echo'`
				, "'$command'", "|",$pager) -wait -nonewwindow
	}elseif( $CmdType.CommandType -eq "Cmdlet" -or  $CmdType.CommandType -eq "Function") {
		start-process "pwsh" -argumentlist ('-noprofile','-command', 'get-help'`
				, '-full', $command, '|', $pager) -wait -nonewwindow
	}elseif($CmdType.CommandType -eq 'Application'){
		& $Command.TRim() -h 2>&1 | out-null
		if($LASTEXITCODE -eq 0 ){
			start-process "pwsh" -argumentlist ('-noprofile','-command', `
					$command,'-h','2>&1', '|', $pager) -Wait -NoNewWindow
		}else{
			& $Command.TRim() --help 2>&1 | out-null
			if($LASTEXITCODE -eq 0){
				start-process "pwsh" -argumentlist ('-noprofile', `
						'-command' ,$command,'--help','2>&1', '|', $pager) `
				-Wait -NoNewWindow
			} else {
				start-process "pwsh" -argumentlist ('-noprofile', `
						'-command',  $command,'/?','2>&1', '|', $pager)`
				-Wait -NoNewWindow
			}
		}
	}elseif($CmdType.CommandType -eq 'Alias'){
		out-file -path c:\temp\logs.txt -inputobject $cmdtype.Definition -append
		InvokeHelp $CmdType.Definition
	}
}
function VIGetHelp {
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
				[ref]$Cursor)
	if( $null -ne $ENV:PAGER){
		$Pager = $ENV:PAGER
	}else{
		$Pager = "more"
	}
	$Command = " $Line "
	$CmdLetCursor = $Cursor + 1
	$CommandStart = 1 + $Command.LastIndexOfAny($CmdLetSeparator, $CmdLetCursor)
	$CommandEnd = $Command.IndexOfAny($CmdLetSeparator, $CmdLetCursor)
	$Command = $Command.Substring($CommandStart, `
			$CommandEnd - $CommandStart + 1)
	InvokeHelp $Command
}
# }}}
# {{{ csh extension
function cshloadpreviousfromhistory {
	$line = $null
	$cursor = $null
	[microsoft.powershell.psconsolereadline]::getbufferstate([ref]$line,`
				[ref]$cursor)
	if($line.trim().length -gt 0){
		$line = [regex]::escape($line)
		$matches = get-content $historyfile -delimiter $historyseparator | `
			select-string -pattern "^$line"
		if( $matches.count -eq 0){
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
# Case Replacement {{{

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

function VIChangeCase {
	($Cursor, $Replacement) = Get-Replacement
	$Replacement = @( $Replacement.toCharArray() | Foreach-Object {
		if( $_ -ge 'a' ){
			$_.toString().toUpper()
		}else {
			$_.toString().toLower()

		}
			}) -join ''
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($Cursor,`
				$Replacement.Length, $Replacement)

}

#}}}

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
	# Out-File -inputObject "$Line $Cursor $StartChar $EndChar" -path c:\temp\log.Txt
	$Path = $Line.Substring($StartChar, $EndChar - $StartChar)
	if( Test-Path $Path -PathType Leaf){
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

function VIgPasteBefore {
	[Microsoft.PowerShell.PSConsoleReadLine]::PasteBefore()
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($Cursor+1)
}

function VIgPasteAfter {
	[Microsoft.PowerShell.PSConsoleReadLine]::PasteAfter()
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($Cursor+1)


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
	$Quotes['|'] = @('|', '|')
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
		}elseif($Quote.ToString() -eq '"' -or $Quote.ToString() -eq "'" -or `
				$Quote.ToString() -eq '|' ){
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
	$Quotes['|'] = @('|', '|')
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
		}elseif($Quote.ToString() -eq '"' -or $Quote.ToString() -eq "'" -or `
				$Quote.ToString() -eq '|'){
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

function VIGlobalPasteBefore{
	$Line = $Null
	$Cursor = $Null
	[Microsoft.Powershell.PSConsoleReadline]::GetBufferState([ref] $Line,
			[ref] $Cursor)
	$Lines = (Get-ClipBoard).Split("`n")
	if($Lines.Count -gt 1){
		$LastLine = $Lines[-1]
		$Lines[0..($Lines.Length-2)]| Foreach-Object {
			[Microsoft.Powershell.PSConsoleReadline]::Insert( `
					$_.Replace("`t",'  ') )
			[Microsoft.Powershell.PSConsoleReadline]::AddLine()
				}
		[Microsoft.Powershell.PSConsoleReadline]::Insert( `
			$LastLine.Replace("`t",'  ') )
	}else{
			[Microsoft.Powershell.PSConsoleReadline]::Insert( `
					$Lines.Replace("`t",'  ') )
	}
}

function VIGlobalPaste (){
	$Line = $Null
	$Cursor = $Null
	[Microsoft.Powershell.PSConsoleReadline]::GetBufferState([ref] $Line,
			[ref] $Cursor)
	$Lines = (Get-ClipBoard).Split("`n")
	if($Cursor -ge ($Line.Length-1) ){
		if($Lines.Count -gt 1){
			$LastLine = $Lines[-1]
			$FirstLine = $Lines[0]
			[Microsoft.Powershell.PSConsoleReadline]::Replace(0, $Line.Length ,`
					$Line + $FirstLine)
			"$Line$FirstLine" | out-file c:\temp\log.txt
			$Lines[1..($Lines.Length-2)]| Foreach-Object {
			[Microsoft.Powershell.PSConsoleReadline]::Insert( `
					$_.Replace("`t",'  ') )
					[Microsoft.Powershell.PSConsoleReadline]::AddLine()
			}
			[Microsoft.Powershell.PSConsoleReadline]::Insert( `
				$LastLine.Replace("`t",'  ') )
		}else{
			$Length = $Line.Length
			$Line += $Lines
			$Line | out-file c:\temp\log.txt
			[Microsoft.Powershell.PSConsoleReadline]::Replace(0, $Length , `
					$Line)
		}
	} else {
		[Microsoft.Powershell.PSConsoleReadline]::SetCursorPosition($Cursor + 1)
		if($Lines.Count -gt 1){
			$LastLine = $Lines[-1]
			$Lines[0..($Lines.Length-2)]| Foreach-Object {
			[Microsoft.Powershell.PSConsoleReadline]::Insert( `
					$_.Replace("`t",'  ') )
					[Microsoft.Powershell.PSConsoleReadline]::AddLine()
			}
			[Microsoft.Powershell.PSConsoleReadline]::Insert( `
				$LastLine.Replace("`t",'  ') )
		}else{
			$Length = $Line.Length
			[Microsoft.Powershell.PSConsoleReadline]::Replace(0, $Length, `
						$($Line + $Lines) )
		}
	}
}
# }}}
# z {{{

function VIZWordSubstitution 	{
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	$Tokens = [System.Management.Automation.PsParser]::Tokenize( `
				$Line, [ref] $null)
	$Token = $Tokens | Where-Object { $Cursor -ge $_.Start -and `
		$Cursor -lt ($_.Start + $_.Length)  }
	$Command = $Token.Content
	$Length = $Token.Length
	if( $Token.Type -eq 'Command'){
		$Commands = (Get-Command | select Name, @{
			N='LD';
			E={ LevenstienDistance $Command $_.Name -i
			}} | sort LD | select -First 20).Name
	}
	# $subst = $Commands | Invoke-Fzf -NoSort -Layout reverse
	$subst = invoke-command -ScriptBlock $SBDisplayChoice `
		-ArgumentList $Commands, $null
	if( $null -ne $subst){
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($Token.Start, $Token.Length, $subst)
	}
	Clear-Host
	[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
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
# FIXED: Use PsReadLine get option                                             #
# FIXED: Get-Content do not remove delim in posh5                              #
# VERSION: 1.0.6                                                               #
# FIXED: Global Paste After does not work when at end of line                  #
# DONE: Ctrl+) to open help on cmdlet                                          #
# DONE: Ctrl+) Invoke Help (/? , -h or --help on application                   #
# VERSION: 1.0.7                                                               #
# FIXME: B to not work                                                         #
# DONE: Add Description to defined chords                                      #
# DONE: Call Help on Alias                                                     #
# DONE: Call Help on Function                                                  #
# TODO: Add g~                                                                 #
# DONE: Add gp and gP                                                          #
# DONE: Try to implement z= on command                                         #
# TODO: z= should list alias also                                              #
# TODO: add | to inner and outer Text                                          #
# HEAD:                                                                        #
################################################################################
# {{{CODING FORMAT                                                             #
################################################################################
# Variable = CamelCase                                                         #
# TabSpace = 4                                                                 #
# Max Line Width = 80                                                          #
# Bracket Style : OTBS                                                         #
################################################################################
