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
w W : Manipulate text between non word character ou blank character
## Outer Text
Appaends binding to manipulate outer text
id est : ca da
### Supported bracket key
" ' ( [ { : Manipulate text between selected bracket
### Supported mouvement key
w W : Manipulate text between non word character ou blank character
## Surrounds
Change or remove surrounding bracket
id est : cs ds
### Supported bracket key
" ' ( [ { 
example : cs"' will replace cursor surrounding " by '
## Increments / Decrements
Ctrl+a will increment under cursor interger

ctrl+x will increment under cursor interger

Note : Supports digit arguments 10ctrl+a will increment by 
## Global Clipboard
+y will yank current buffer in system clibboard

+p will paste after cursor current system clipboard

+P will paste before cursor current system clipboard
