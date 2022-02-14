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
	$Caps = "$[({})]-._ '```"" + ([char]'A'..[char]'z' | `
		Foreach-Object { [char]$_ }) -join ''
	[int]$NumericArg = 0
	[Microsoft.PowerShell.PSConsoleReadLine]::TryGetArgAsInt($arg,
		  [ref]$numericArg, 1)
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	$EndChar = $Line.indexOfAny($Caps, $Cursor)
	$StartChar = $Line.LastIndexOfAny($Caps, $Cursor) + 1
	if($EndChar -lt 0 -and $StartChar -gt 0){
		$EndChar = $Line.Length
	}
	[int]$NextVal = $Line.SubString($StartChar, $EndChar - $StartChar)
	$NextVal -= $NumericArg

	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($StartChar,`
				$EndChar - $StartChar, $nextVal.ToString() )
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($EndChar - 1)
}

function VIIncrement( $key , $arg ){
	$Caps = "$[({})]-._ '```"" + ([char]'A'..[char]'z' | `
		Foreach-Object { [char]$_ }) -join ''
	[int]$NumericArg = 1
	[Microsoft.PowerShell.PSConsoleReadLine]::TryGetArgAsInt($arg,
		  [ref]$numericArg, 1)
	$Line = $Null
	$Cursor = $Null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line,`
		[ref]$Cursor)
	$EndChar = $Line.IndexOfAny($Caps, $Cursor)
	$StartChar = $Line.LastIndexOfAny($Caps, $Cursor) + 1
	if($EndChar -lt 0 -and $StartChar -gt 0){
		$EndChar = $Line.Length
	}
	[int]$NextVal = $Line.SubString($StartChar, $EndChar - $StartChar)
	$NextVal += $NumericArg

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
	$Caps = "$[({})]-._ '```"" + ([char]'A'..[char]'Z' | `
		Foreach-Object { [char]$_ }) -join ''
	$Quotes = New-Object system.collections.hashtable
	$Quotes["'"] = @("'","'")
	$Quotes['"'] = @('"','"')
	$Quotes["("] = @('(',')')
	$Quotes["{"] = @('{','}')
	$Quotes["["] = @('[',']')
	$Quotes["w"] = @("$[({})]-._ '```"", "$[({})]-._ '```"")
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
				$Quote.ToString() -eq '{' ){
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
	$Quotes["{"] = @('{','}')
	$Quotes["["] = @('[',']')
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
				$Quote.ToString() -eq '{' ){
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
					$StartChar )
			$LocalShell.SendKeys("{$($ClosingQuotes.ToString())}")
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
function ViChangeSurround(){
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

function ViDeleteSurround(){
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
# HEAD: 1.0.1                                                                  #
################################################################################
# {{{CODING FORMAT                                                             #
################################################################################
# Variable = CamelCase                                                         #
# TabSpace = 4                                                                 #
# Max Line Width = 80                                                          #
# Bracket Style : OTBS                                                         #
################################################################################
