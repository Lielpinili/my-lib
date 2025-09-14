-- Add under ConsoleClient
local Syntax = {}

-- Console

Syntax.clear = false
Syntax.clearcmds = false

Syntax.consoleui = {
	pos = 'bottom|top',
	anchor = 'bottom|top'
}

Syntax.help = '!number'


-- Player

Syntax.tp = {'!plrs','!plr'}
Syntax.sethp = {'!plrs','!number'}
Syntax.setmaxhp = {'!plrs','!number'}


-- Import custom commands
-- for cmd, v in require(script.name) do
-- 	Syntax['name:'..cmd] = v
-- end

return Syntax
