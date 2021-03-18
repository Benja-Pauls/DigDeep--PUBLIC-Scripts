
--[[Welcome to my Roblox scripting tutorial! This was compiled from other tutorials ie: AlvinBlox and 
	PeasPod, along with my own knowledge, this will go over everything you need to know so you can start
	writing your own code in Lua!
  ]]


-----[Start of Extreme Basics Demonstration]-----------------------------------------------------------------------------------------------------------------

game.Workspace.Hello.Material = Enum.Material.Wood --this is a way of selecting an object's material within the scipt, try removing air to see the list

game.Workspace.Hello.Material = "Wood" --similar way as above, but you don't get a list within the scripting

game.Workspace.Hello.BrickColor = BrickColor.new("Really red") --Brick color method of making a block colorful

game.Workspace.Hello.Color = Color3.fromRGB(255,0,0) --How to select a color from RGB instead of Roblox's dedicated brick colors

game.Workspace.Hello.Anchord = true --Stating an object's value on check marked boxes

--the reason for game.Workspace.Hello.****** is this...

	--We're in the "game" which contains the "Workspace" which contains the part "Hello"
	--The next section of text is a property within the "Hello" part
	
-----[End of Extreme Basics Demonstration]--------------------------------------------------------------------------------------------------------------------------

-----[Start of Parts With Strange Names Demonstration]---------------------------------------------------------------------------------------------------------------------
game.Workspace.My brick.Transparency = 1 --How to handle blocks with spaces in their names

	--The output error would say this if you include the space:
	--"ServerScriptService.Script:28:'=' expected near 'brick'
	
	--28=line number, ServerScriptService.Script = location, and the '=' is saying the Workspace doesn't understand what it's equaling to

--to fix this...

game.Workspace["My brick"].Transparency = 1  --Now the scipt will turn "My brick" invisible (Transparency = 1)

--The ["My brick"] is considered a string. A string is text

--Therefore, 37 would not be a sting, but ["37"] would be, since it is now considered "text" (which is why you should present your numbers like this)

--But what if you name your part the same as an option in properties, for example we'll use "gravity"

game.Workspace:FindFirstChild("Gravity").Transparency = 0.5

--This finds the first "child" from Workspace that is presented as "Gravity"

--What if we have two parts that have the same name? For example, we have two parts named "dog"

game.Workspace.Dog1.Transparency = 1
game.Workspace.Dog2.Transparency = 1

--Just name them slightly different, and you'll have to independently code each one
--(You can't name two parts the same and have them both affected by one code)

--REMEMBER: Caps do matter! Make sure you capitalize what needs to be capitalized!

-----[End of Parts With Strange Names Demonstration]----------------------------------------------------------------------------------------------------------
		--(none of these scripts will probably work here, because there are too many repeating or missing parts, but they will work if put together correctly)
-----[Start of "Rolling the Dice" Demonstration]--------------------------------------------------------------------------------------------------------------

--!!!!This is scripted as if the dice weren't in the "group" folder named "Dice"
-	--Treat it like they are both just out in the workspace

--Left dice anchored so we can un-anchor it when we "roll"

--Used "Images" in the "Toolbox" tab and looked up "dice #" to find images for each side

game.Workspace.Dice1.Anchored = false --Roll first dice

--,but we want the first dice to hit the second dice so it stumbles more

wait(1) --wait 1 second

game.Workspace.Dice2.Anchored = false --Roll second dice

--What will happen: The Dice will fall because they were set to "anchored", but we are now setting that
--to false so they will roll when they hit the ground

-----[End of "Rolling the Dice" Demonstration]-----------------------------------------------------------------------------------------------------------------

-----[Start of Using Variables Demonstration]------------------------------------------------------------------------------------------------------------------

--We now grouped the dice into a group named "Dice" + another group on top named "GameParts"
	--Therefore, when denouncing the specific dice, we have to say...
	
game.Workspace.GameParts.Dice.Dice1.Anchored = false --Roll first dice

wait(0.5)

game.Workspace.GameParts.Dice.Dice2.Anchored = false --Roll second dice

--same thing if you wanted to change it's color

game.Workspace.GameParts.Dice.Dice2.BrickColor = Brickcolor.new("Really red")

--...but this takes a really long time to type out everytime...
	--so lets add some variables!
	
--We're going to create a "shortcut" so we don't have to type "game.Workspace.GameParts.Dice" everytime

--to create a variable we have to say "local" first

local dice = game.Workspace.GameParts.Dice --The name of the variable is what you will write as your shortcut, instead of repeating the same code all the time

--now you can write the above code as:

dice.Dice1.Anchored = false --Roll first dice

wait(0.5)

dice.Dice2.Anchored = false --Roll second dice

--Perks of variables:

	--Saves time writing our same code over and over again
	
	--You don't have to change every single line of code if you change the variable value
	
--We could simplify this even more!

local dice1 = game.Workspace.GameParts.Dice.Dice1

local dice2 = game.Workspace.GameParts.Dice.Dice2

--so now we could write our coding as...

dice1.Anchored = false --Roll first dice

wait(0.5)

dice2.Anchored = false --Roll second dice

--this will also work in different "tabs"

local lighting = game.Lighting

--variables can be ANY data type!
	--The four data types are...
	
	
	""   		 			--"This is a string" - Text
	3020 		 			--Number
	true / false 			--Boolean
	game.Workspace.Camera   --Object Reference
	
	
--so we could say... (using text)

local text = "The quick brown fox jumps over the lazy dog"

print("The quick brown fox jumps over the lazy dog") --"Print" puts a message in the output

--but with the local variable... we don't have to type that all out... we could just say:

print(text)

--if you ever get "nil" as an error in the output that means:
	--nil = nothing (if you didn't denounce what "text" was, it would say nil, meaning "there's nothing
	--stored to text here as we haven't defined the variable"
	
--MAKE SURE YOU PUT THE LOCAL VARIABLE ABOVE WHAT YOUR USING IT WITH!! 
--The code is read from top to bottom, so if you explained what your local variable is below when you
--use that local variable, you will get a nil error

--You can also do math with local variables!!
	
local myNumber = 500

print(myNumber+10) --This will display 510 in the output instead of just 500

--you could also set the value of my number later without changing it's local variable

myNumber = myNumber + 50
--500    = 500       + 50

print(myNumber+10) --Now this will display 560 instead of 510

--(Just so we're clear, the word "variable" means being able to change value) 

--So you could say it's temporary storage (holding) in Lua as it could change value at any time

--A variable can change value before it's used at a certain point in the script. Each time you
--change the value of the variable, it will be different at the next step where you use it

--The above example: we added 50 to "myNumber" before we divided by 10

-----[End of Using Variables Demonstration]------------------------------------------------------------------------------------------------------------------

-----[Start of Instancing Demonstration]---------------------------------------------------------------------------------------------------------------------

--Instancing is using scripting to insert something into your game, such as a part

--You can find the list of objects you can spawn by going to model->advanced objects

Instance.new("Part",game.Workspace) --after the comma is where the object will spawn

--so let's make a local variable of what we just created so we can more easily change it's properties

local myPart = Instance.new("Part",game.Workspace)

myPart.Transparency = 0.5
myPart.Anchored = true
myPart.Position = Vector3.new(5,5,5)

--so now the part will be created and it will have all of these properties

--There is also another way of saying local myPart = Instance.new("Part",game.Workspace), and this way
--is the PREFERED method, since it is much more efficient, so instead we could say:

local myPart = Instance.new("Part")

myPart.Parent = game.Workspace
myPart.Transparency = 0.5
myPart.Anchored = true
myPart.Position = Vector3.new(5,5,5)

--With this we're saying the "myPart"'s parent is game.Workspace without interrupting the local variable

-----[End of Instancing Demonstration]-----------------------------------------------------------------------------------------------------------------------

-----[Start of Introduction to Functions Demonstration]----------------------------------------------------------------------------------------------------------------------

--To start let's create an object with some properties

local part = Instance.new("Part")

part.Name = "MyAwesomePart"
part.BrickColor = BrickColor.new("Really red")
part.Anchored = true
part.Position = Vector3.new(0,15,0)
part.Transparency = 0.5
part.Reflectance = 0.6
part.CanCollide = false
part.Parent = game.Workspace

--you could spawn this part in 5 times by copy and pasting this line of code 5 times
	--...but that would take up a lot of lines of code
	
--So we could instead make it a function so we don't have to copy and paste it 5 times
	
function generatePart() --the "generatePart()" is the name of the function (works like local variables)
	
	local part = Instance.new("Part")

	part.Name = "MyAwesomePart"
	part.BrickColor = BrickColor.new("Really red")   --The () is very important in the function line
	part.Anchored = true
	part.Position = Vector3.new(0,15,0)                  --We'll get to why later
	part.Transparency = 0.5								 	--(in the Parameters / Arguments Demo)
	part.Reflectance = 0.6
	part.CanCollide = false
	part.Parent = workspace

end --this marks the end of the code (like using {} is other coding languages

--but defining the function doesn't mean the script is going to do anything with it
	--so we have to trigger it

generatePart()
generatePart()
generatePart() --so now it will spawn it five times, and it will take up less space in your script
generatePart()      --Saving your time and making your code look neater
generatePart()

--This works the same as local variables, meaning your have to define the function before you use it

-----[End of Introduction to Functions Demonstration]--------------------------------------------------------------------------------------------------------

-----[Start of Parameters / Arguments Demonstration]---------------------------------------------------------------------------------------------------------

--So let's create our same function that we created before
	
function generatePart()
	
	local part = Instance.new("Part")

	part.Name = "MyAwesomePart"
	part.BrickColor = BrickColor.new("Really red")  
	part.Anchored = true
	part.Position = Vector3.new(0,15,0)                 
	part.Transparency = 0.5
	part.Reflectance = 0.6
	part.CanCollide = false
	part.Parent = workspace

end

generatePart() 
generatePart() 
generatePart()
generatePart()
generatePart()

--So far we've only used functions to shorten our code to make our lives easier
	--But there are much more helpful ways to use funtions in your code

--We're going to change the "parameter" so that each time a new object is spawned it will have a different name

function generatePart(name) --This is called the parameter (the variable we have pre-defined)
	
	local part = Instance.new("Part")

	part.Name = name       	 --The "name" follows the same rules as naming a local variable
	part.BrickColor = BrickColor.new("Really red")  
	part.Anchored = true
	part.Position = Vector3.new(0,15,0)                 
	part.Transparency = 0.5
	part.Reflectance = 0.6
	part.CanCollide = false
	part.Parent = workspace

end

generatePart("PartNumberOne") 		--This is called the data that will be sent to the function
generatePart("PartNumberTwo") 			--The "argument" = (What it will be equaling to)
generatePart("PartNumberThree")
generatePart("PartNumberFour")
generatePart("PartNumberFive")

--So now the name of each part will have it's "part.Name = name" where name = what's within the parameters

--But now you have to name each part, because if you don't you will get a "nil" error
	--(meaning information is missing)
	
--You could also have multiple parameters for one function
	--(You'd have to seperate the parameters with a comma)
	--Subsequently, you'd have to seperate the parameters within the argument with a comma
		--!!In the same order as denounced in the parameters!!
		
--Let's try another example

function printText(stringToPrint)
	print(stringToPrint)
end

printText("Hello")
printText("This is a message")		--This will put two messages into your output window

-----[End of Parameters / Arguments Demonstration]-----------------------------------------------------------------------------------------------------------

-----[Start of While Loop Demonstration]------------------------------------------------------------------------------------------------------------------

while true do   --This creates the while loop that will repeat the code within the "while" and the "end"
	local part = Instance.new("Part")
	
	part.Parent = game.Workspace        --This function will spawn a part named "part" every one second
	wait(1)
end
	
	--"True" just means there is nothing to check, but what if you did have something to check?
while i+2==4 do
	local part = Instance.new("Part")
	
	part.Parent = game.Workspace        --This is an example of a "check" that must be true to repeat
	wait(1)
end
	
	--if you put a "break" underneath the "wait(1)" it would stop the loop, spawning in the object once

--You could use these "checks" within the loops to build unique games that check for players, time, etc.

-----[End of While Loop Demonstration]-----------------------------------------------------------------------------------------------------------------------

-----[Start of For Loop Demonstration]-----------------------------------------------------------------------------------------------------------------------

--The for loop only runs "for" a certain amount of time (you tell it how many times to run)

for i = x,y,z do 	--"i" is your counter (will change to 1 after one loop, then 2, etc.)
						
	\					--x is your starting loop number (set to 1 if you want a consistent counter)
	\					--y is the number that i will go up to (loop will be the end of the loop)
	\					--z is the number of values i will increase per loop (if 1 = 1,2,3,4,5,6,7)
	\					
						--Example: Loop 60 times = "for i = 1,60,1 do"
end

--Let's do an example...
	
for i = 1,60,1 do
	print(i)		--This will look like a 60 second timer in your output
	wait(1)
end

--Lets include an "if" statement in this next example...

for i = 1,60,1 do
	if i < 30 then
		print(i)
		wait(1)				--This statement will count to 29
	end							--but will then start saying "30 seconds" to "60 seconds" after 29
	if i > 29 then
		print(i,"seconds")
		wait(1)
	end
end
	
-----[End of For Loop Demonstration]-------------------------------------------------------------------------------------------------------------------------

-----[Start of Events Demonstration]-------------------------------------------------------------------------------------------------------------------------

--To find an events list go to view -> object browser -> all lightning icons
	--For this example we are going to be using the event: "PlayerAdded"
	
game.Players.PlayerAdded:Connect(function(player)        --Remember, you can name "player" anything
	print("Hey! "..player.Name.." has joined the game")  --Example: Hey! benisthedj has joined the game
end)

--Lets test another type of event, for this example we'll use the "Touched" event

game.Workspace.TouchedEventPart.Touched:Connect(function(hit)           --TouchedEventPart = part name
	game.Workspace.Baseplate.BrickColor = Brickcolor.new("Really red")
end)

--This script means: When the part "TouchedEventPart" touches ANYHTING the baseplate will turn red

-----[End of Events Demonstration]---------------------------------------------------------------------------------------------------------------------------

-----[Start of If Statements Demonstration]------------------------------------------------------------------------------------------------------------------

--We have used if statements in a previous demonstration,
	--but this demonstration will explain their meaning and different variations
	
--If statements are used "if" a certain requirement has been met, this is used in a lot of languages

--IF+CONDITION+THEN
	--CODE
	--CODE
	--CODE
	--CODE
	--CODE
--END

variable = 1   --this will be our "check"

if variable == 1 then
	print("The variable is equal to 1")
end

--But what if we don't want the variable set equal to something? 

--IF+RELATIONAL OPERATOR+THEN

  --A relational operator is used to compare two values, and they can also be called comparison operators

--Operators you can use are...

--			"<" 	meaning less than
--			">" 	meaning greater than
--			"<=" 	meaning less than or equal to
--			">="	meaning greater than or equal to
--			"=="	meaning equals
--			"~="	meaning does not equal

if 2+2==4 then
	print("Hello There")
end

--Now we're going to move on to else statements

if 2+2==5 then
	print("Hello There")		--Since 2+2 doesn't equal 5, the script will read below the "else" statement
else
	print("There Hello")
end

--But there is one more we can use... elseif

if 2+2==5 then
	print("Hello There")	
elseif 2+3==5 then				--This will do the same thing as the example above, but you can use "elseif"
	print("General Kenobe")		--to set a parameter for the function
else
	print("I have the high ground")
end
	
-----[End of If Statements Demonstration]--------------------------------------------------------------------------------------------------------------------

-----[Start of Boolean Operators Demonstration]--------------------------------------------------------------------------------------------------------------

--there are three Boolean Operators... and, or, not

variable1 = 5
variable2 = 6

if variable1 == 5 and variable2 == 6 then     --This AND this (both have to be correct)
	print("True1")
end

if variable1 == 5 or variable2 == 6 then		  --This OR this (one has to be correct)
	print("True2")
end

--The not rule works best with BOOLEAN, meaning true / false

variable = true

if not variable == true then      			  --This does NOT = this (nothing is correct)
	print("True3")
end										

-----[End of Boolean Operators Demonstration]----------------------------------------------------------------------------------------------------------------

-----[Start of Click Detector Demonstration]-----------------------------------------------------------------------------------------------------------------

--First we're going to build an object that will hold a button
	--Therefore, the script for this demonstration is inside the button object
	
-----[End of Click Detector Demonstration]-------------------------------------------------------------------------------------------------------------------

-----[Start of Leaderboards Demonstration]-------------------------------------------------------------------------------------------------------------------

--I'm going to put the leaderboard script in a different script, so look for it there.

--Reason: this script has errors and repeating functions that could interfere with this code
--        (I want to see the leaderboard working, not just know it will probably work)

-----[End of Leaderboards Demonstration]---------------------------------------------------------------------------------------------------------------------
-----[END OF BEGINNER UNIT]----------------------------------------------------------------------------------------------------------------------------------

-----[START OF ADVANCED UNIT]--------------------------------------------------------------------------------------------------------------------------------
-----[Start of Tables Demonstration]-------------------------------------------------------------------------------------------------------------------------

--Tables are like variables, but it can store a ton of values within it

pod = 5 --this is a generic variable, that can only store one value

--So lets make a table that will store more than one value:

myTable = {5, 7, 2, 0, 9, 2, "peaspod"} --Look at all of those values!

print(maTable[1])            --Now we have to chose which values to print in the table
print(maTable[2])
print(maTable[7]) --This will print "peaspod" in the output (just print(maTable[7]), not the others

--now that is cool and all, but lets discuss all the different table functions (All four of them)

table.insert(myTable, 8) 
--We're going to insert 8 into "myTable" (the value will be inserted to the end)

table.remove(myTable, 2) 
--Will remove the second value from "myTable"

table.sort(myTable)
--This will sort all the values in your table in numerical order

print(table.concat(myTable, " ") --This prints all of the table and puts a space between all the values

--It organizes the table with what ever you put in the argument, so ", " = 5, 7, 2, etc....

-----[End of Tables Demonstration]---------------------------------------------------------------------------------------------------------------------------

-----LOOK AT PISHPOD PART SCRIPT'S TOP FOR DEMONSTRATION ON DIFFERENT VARIABLES IN TABLES-----



