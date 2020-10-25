Double lines to the left of any text mean it is a comment (Example: --I'm a comment!)

Double brackets to the right of a double hyphen will surround multiple lines of text as a comment
Example:
--[[
	I'm using comment brackets
	to comment out multiple
	lines of code!
]]



Script Type Key:

Script: Server sided, usually handles anything with sensitive data

ModuleScript: similar to a class in python, you can access it cleanly from anywhere with a "require()"

LocalScript: Usually found inside the player, it is the only script that can access the value "game.Players.LocalPlayer" 
(script can edit anything, but it doesn't affect the server. Example: You could turn a model invisible and the player associated with
the script will no long see it, but the other players will still be able to see the model)