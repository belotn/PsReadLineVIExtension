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
#}}}
$LocalShell = New-Object -ComObject wscript.shell
######################################################################
# Section Function                                                   #
######################################################################
# {{{ Increment/decrement

function VIDecrement( $key , $arg ){
	[int]$numericArg = 0
	[Microsoft.PowerShell.PSConsoleReadLine]::TryGetArgAsInt($arg,
		  [ref]$numericArg, 1)
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	$OpeningQuote = ' '
	$ClosingQuote = ' '
	$EndChar = $Line.indexOf($ClosingQuote, $Cursor)
	$StartChar = $Line.LastIndexOf($OpeningQuote, $Cursor) + 1
	[int]$nextVal = $Line.Substring($StartChar, $EndChar - $StartChar)
	$nextVal -= $numericArg

	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($StartChar,`
				$EndChar - $StartChar, $nextVal.toString() )
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($EndChar - 1)
}

function VIIncrement( $key , $arg ){
	[int]$numericArg = 1
	[Microsoft.PowerShell.PSConsoleReadLine]::TryGetArgAsInt($arg,
		  [ref]$numericArg, 1)
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	$OpeningQuote=' '
	$ClosingQuote=' '
	$EndChar=$Line.indexOf($ClosingQuote, $Cursor)
	$StartChar=$Line.LastIndexOf($OpeningQuote, $Cursor) + 1
	[int]$nextVal = $Line.Substring($StartChar, $EndChar - $StartChar)
	$nextVal += $numericArg

	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($StartChar,`
				$EndChar - $StartChar, $nextVal.toString() )
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($EndChar - 1)
}
# }}}

# {{{ InnerBlock
function VIChangeInnerBlock(){
	VIDeleteInnerBlock
	[Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode()
}

function VIDeleteInnerBlock(){
	$Caps = "$[({})]-._ '```"" + ([char]'A'..[char]'Z' |% { [char]$_ }) -join ''
	$quotes = New-Object system.collections.hashtable
	$quotes["'"] = @("'","'")
	$quotes['"'] = @('"','"')
	$quotes["("] = @('(',')')
	$quotes["{"] = @('{','}')
	$quotes["["] = @('[',']')
	$quotes["w"] = @("$[({})]-._ '```"", "$[({})]-._ '```"")
	$quotes["W"] = @(' ', ' ')
	$quotes['C'] = @($Caps, $Caps)
	$quote = ([Console]::ReadKey($true)).KeyChar
	if( $quotes.ContainsKey($quote.toString())){
		$Line = $Null
		$Cursor = $Null
		[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
				[ref]$Cursor)
		$OpeningQuotes = $quotes[$quote.ToString()][0]
		$ClosingQuotes = $quotes[$quote.ToString()][1]
		if($ClosingQuotes.length -gt 1){
			$EndChar=$Line.indexOfAny($ClosingQuotes, $Cursor)
		}else{
			$EndChar=$Line.indexOf($ClosingQuotes, $Cursor)
		}
		if($OpeningQuotes.length -gt 1){
			$StartChar=$Line.LastIndexOfAny($OpeningQuotes, $Cursor) + 1
		}else{
			$StartChar=$Line.LastIndexOf($OpeningQuotes, $Cursor) + 1
		}
		if(($OpeningQuotes.Length -gt 1 -or $quote -ceq 'W' -or $quote -ceq 'C') -and $EndChar -lt 0){
			$EndChar = $Line.Length
		}
		if(($OpeningQuotes.Length -gt 1 -or $quote -ceq 'W') -and $StartChar -lt 0){
			$StartChar = 0
		}
		# if($OpeningQuotes.Length -eq 1 -and ( $StartChar -eq 0 -or $EndChar -eq -1)){
		# 	Return
		# }
		# if($OpeningQuotes.Length -gt 1 -and $EndChar -eq -1){
		# 	$EndChar = $Line.Length
		# }
		if( $quote.toString() -eq 'C'){
			$StartChar -= 1
		}
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar )
		if($quote.toString() -ceq 'w'){
			[Microsoft.PowerShell.PSConsoleReadLine]::DeleteWord()
		}elseif( $quote.toString() -ceq 'W'){
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteGlob()
		}elseif($quote.toString() -eq '"' -or $quote.toString() -eq "'" ){
			$LocalShell.SendKeys($quote)
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToBeforeChar()
		}elseif( $quote.toString() -eq '(' -or $quote.toString() -eq '[' -or `
				$quote.toString() -eq '{' ){
			$LocalShell.SendKeys("{$($ClosingQuotes.toString())}")
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToBeforeChar()
		} elseif( $quote.toString() -eq 'C') {
			if($EndChar -eq $Line.Length){
				[Microsoft.PowerShell.PSConsoleReadLine]::DeleteToEnd()
			}else{
				$LocalShell.SendKeys($Line[$EndChar])
				[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToBeforeChar()
			}
		 } #else {
			# [Microsoft.PowerShell.PSConsoleReadLine]::Replace($StartChar,`
			# 		$EndChar - $StartChar, '')
		# }
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
	$quotes = New-Object system.collections.hashtable
	$quotes["'"] = @("'","'")
	$quotes['"'] = @('"','"')
	$quotes["("] = @('(',')')
	$quotes["{"] = @('{','}')
	$quotes["["] = @('[',']')
	$quotes["w"] = @("$[({})]-._ '```"\/", "$[({})]-._ '```"\/")
	$quotes["W"] = @(' ', ' ')
	$quote = ([Console]::ReadKey($true)).KeyChar
	if( $quotes.ContainsKey($quote.toString())){
		$Line = $Null
		$Cursor = $Null
		[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
				[ref]$Cursor)
		$OpeningQuotes = $quotes[$quote.ToString()][0]
		$ClosingQuotes = $quotes[$quote.ToString()][1]
		if($ClosingQuotes.length -gt 1){
			$EndChar=$Line.indexOfAny($ClosingQuotes, $Cursor) + 1
		}else{
			$EndChar=$Line.indexOf($ClosingQuotes, $Cursor) +1
		}
		if($OpeningQuotes.length -gt 1){
			$StartChar=$Line.LastIndexOfAny($OpeningQuotes, $Cursor)
		}else{
			$StartChar=$Line.LastIndexOf($OpeningQuotes, $Cursor)
		}
		if(($OpeningQuotes.Length -gt 1 -or $quote -ceq 'W') -and $EndChar -eq 0){
			$EndChar = $Line.Length
		}
		if(($OpeningQuotes.Length -gt 1 -or $quote -ceq 'W') -and $StartChar -lt 0){
			$StartChar = 0
		}
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar + 1)
		if($quote.toString() -ceq 'w'){
			[Microsoft.PowerShell.PSConsoleReadLine]::DeleteWord()
		}elseif( $quote.toString() -ceq 'W'){
			if($StartChar -eq 0){
				$StartChar--
			}
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar + 1 )
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteGlob()
		}elseif($quote.toString() -eq '"' -or $quote.toString() -eq "'" ){
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar )
			$LocalShell.SendKeys($quote)
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToChar()
		}elseif( $quote.toString() -eq '(' -or $quote.toString() -eq '[' -or `
				$quote.toString() -eq '{' ){
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar )
			$LocalShell.SendKeys("{$($ClosingQuotes.toString())}")
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToChar()
		} elseif( $quote.toString() -eq 'C') {
			$LocalShell.SendKeys($Line[$EndChar])
			[Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteToChar()

		} #else {
		# [Microsoft.PowerShell.PSConsoleReadLine]::Replace($StartChar, `
		# 		$EndChar - $StartChar, '')
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($StartChar)
	}
}
# }}}

# {{{ Surround
function ViChangeSurround(){
	# inspired by tpope vim-surround
	# https://github.com/tpope/vim-surround
	$quotes = @{
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
	$SearchOpeningQuotes = $quotes[$Search.ToString()][0]
	$SearchClosingQuotes = $quotes[$Search.ToString()][1]
	$ReplaceOpeningQuotes = $quotes[$Replace.ToString()][0]
	$ReplaceClosingQuotes = $quotes[$Replace.ToString()][1]
	$EndChar=$Line.indexOf($SearchClosingQuotes, $Cursor)
	$StartChar=$Line.LastIndexOf($SearchOpeningQuotes, $Cursor)
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($StartChar, `
		1,$ReplaceOpeningQuotes )
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($EndChar, `
		1,$ReplaceClosingQuotes )
}

function ViDeleteSurround(){
	# inspired by tpope vim-surround
	# https://github.com/tpope/vim-surround
	$quotes = @{
		"'" = @("'","'");
		'"'= @('"','"');
		"(" = @('(',')');
		"{" = @('{','}');
		"[" = @('[',']');
	}
	$Line = $Null
	$Cursor = $Null
	$Search = ([Console]::ReadKey($true)).KeyChar
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
			[ref]$Cursor)
	$SearchOpeningQuotes = $quotes[$Search.ToString()][0]
	$SearchClosingQuotes = $quotes[$Search.ToString()][1]
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
	$line = $null
	$cursor = $null
	[Microsoft.Powershell.PSConsoleReadline]::GetBufferState([ref] $line,
			[ref] $cursor)
	Set-Clipboard $line
}

function VIGlobalPaste (){
	param(
		$Before=$false
	)
	$Line = $null
	$Cursor = $null
	[Microsoft.Powershell.PSConsoleReadline]::GetBufferState([ref] $Line,
			[ref] $Cursor)
	if($Before ){
		[Microsoft.Powershell.PSConsoleReadline]::SetCursorPosition($Cursor -1)
	}
	(Get-Clipboard).Split("`n") |% {
		[Microsoft.Powershell.PSConsoleReadline]::Insert( `
				$_.Replace("`t",'  ') + "`n" )
	}
}
# }}}

Export-ModuleMember -Function 'VIDecrement', 'VIIncrement', `
	'VIChangeInnerBlock', 'VIDeleteInnerBlock', 'VIChangeOuterBlock', `
	'VIDeleteOuterBlock', 'ViChangeSurround', 'ViDeleteSurround', `
	'VIGlobalYank', 'VIGlobalPaste'
################################################################################
# Author - belot.nicolas@gmail.com                                             #
################################################################################
# CHANGELOG                                                                    #
################################################################################
# DONE: Change Quotes declaration to be case sensitive (W)                     #
# DONE: Add Handler for Next Camel Word (Maybe cd and cD)                      #
#       Should be ciC and diC                                                  #
# DONE: Use compatible Ps5 char range operator                                 #
# DONE: Add function to access global clipboard                                #
# DONE: Delete must add erase text in register  (VIDelete*)                    #
# FIXED: Outter Text malfunction when word contains special char               #
# FIXED: [cd]iW do nothing                                                     #
# DONE: Change Inner Cap should work with endOfWord                            #
# DONE: Change Inner Cap should work with endOfLine                            #
################################################################################
# {{{CODING FORMAT                                                             #
################################################################################
# Variable = CamelCase                                                         #
# TabSpace = 4                                                                 #
# Max Line Width = 80                                                          #
# Bracket Style : OTBS                                                         #
################################################################################
