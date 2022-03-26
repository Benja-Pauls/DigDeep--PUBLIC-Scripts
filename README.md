# DigDeep--PUBLIC-Scripts
All scripts that are **allowed to be public** during Dig Deep's development process. Previously sensitive files were stored in this repository, so feel free to delve-through the commit history to see old versions of data management for your own projects. This choice was made after significant changes were made to the PlayerStatManager.lua script.


For those who accessed this GitHub from Twitter, I will be updating these GitHub scripts with the "End of Day Update" tweets (this GitHub is not a replacement for the tweets).
If you didn't access this GitHub through Twitter, Twitter is this project's development log, announcing nightly update summaries whenever possible about the day's progress.
If you would like to hear those daily updates, the project's Twitter is https://twitter.com/Benisthedj

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
(script can edit anything, but it doesn't affect the server. Example: You could turn a model invisible and the player associated with the script will no longer see it, but the other players will still be able to see the model)
