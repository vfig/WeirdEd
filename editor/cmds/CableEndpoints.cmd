; this doesnt work :(
set foo @@value
; this works but is kinda useless :(
set @@foo value
; this doesnt work because eval looks up the config name, doesnt give the literal value:
eval @@value set foo %s

; this seemed promising, but...
mprint @@an_integer_please
eval last_command set %s
;now is the 'mprint' var set to what you typed??
;no: last_command is the pre-parsed last command.

script_ping EditorCables,endpoints:15
