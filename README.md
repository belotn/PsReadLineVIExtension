# PsReadLineVIExtension
Powershell Module to add VIM Keybinding for some text manipulation

# Requirement
This modules require PSreadline to work

# Bindings
## Innter text
Appends binding for manipulating inner text
id est : ci di
### Supported bracket key
" ' ( [ { : Manipulate text between selected bracket
### Supported mouvement key
w W : Manipulate text between non word character ou blank character (word and WORD)

C 	: Manipulate text between non word and Caps 
## Outer Text
Appends binding to manipulate outer text
id est : ca da
### Supported bracket key
" ' ( [ { : Manipulate text between selected bracket
### Supported mouvement key
w W : Manipulate text between non word character ou blank character (word and WORD)
## Surrounds
Change or remove surrounding bracket
id est : cs ds
### Supported bracket key
" ' ( [ { 
example : cs"' will replace cursor surrounding " by '
## Increments / Decrements
ctrl+a will increment under cursor interger

ctrl+x will increment under cursor interger

Note : 
- Supports digit arguments 10ctrl+a will increment by 10
- Supports User Declare Increment (set the variable $VIIncrementArray)
> Example :
> `$VIIncrementArray = @(
 	@('Monday', 'Tuesday','Wednesday','Thursday', 'Friday', 'Saturday', 'Sunday'),
	@('January', 'February','March', 'April','May', 'June',
	'July','August','September', 'October', 'November','December') )`

## Global Clipboard
+y will yank current buffer in system clibboard

+p will paste after cursor current system clipboard

+P will paste before cursor current system clipboard

## g Operator
ge : go end of previous word

gE : go end of previous WORD

gm : Go to middle of screen

gM : Go to middle of line

gf : Open file under cursor if exist

## Experimental
Set variable $VIExperimental to $True to activate

gu gU / lowercase ; uppercase :

supported motion
- g[digit]U : next X charater
- gU[motion] iwW : next word WORD

<C+)> Call Help for CmdLet or Operation using ENV PAGER or more if not defined
