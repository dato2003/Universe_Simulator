--MADE BY DAVID ZUROSHVILI (DARKNINJAD)
local discordia = require("discordia")
local sql = require ("sqlite3")
local timer = require ("timer")
local client = discordia.Client()
math.randomseed(os.time())


client:on('ready', function()
	print('Logged in as '.. client.user.username)
end)

--Open a DB where you keep the money
local db = sql.open("MoneyDB.db")

local sql = "PRAGMA journal_mode=WAL"
db:exec(sql)
--People that are on cooldown and should not get exp will be in this table
local CooldownTable = {}

--Function to Remove People that have passed Cooldown
function Cooldown(name)
	CooldownTable[name] = false
end

client:on('messageCreate', function(message)
	local name = message.author.id
	local Guild = message.channel.guild.id
	local AuthorMentionName = message.author.mentionString

	sql = "CREATE TABLE IF NOT EXISTS '" .. Guild .. "' (ID TEXT, Coins TEXT)"
	db:exec(sql)

	if(name ~= "643070824403959808" and string.sub(message.content,1,1) == ">") then
		--IF command is >treasury or >Treasury
		if(string.lower(string.sub(message.content,2,#message.content)) == "treasury") then
			local body = AuthorMentionName .. ":"
			sql = "select Coins from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			--Get The Coins in a table
			local Rows,errorString = db:exec(sql)

			--IF There is no such ID in DB Send back sending that it's 0.it will insert it later
			if errorString == 0 then
				message.channel:send(body .. "0")
			else
				local Curr
				--Get The Coins
				for k, v in pairs(Rows) do
					if(k == "Coins") then
						Curr = v[1]
					end
				end
				--Send Back the msg of the money
				message.channel:send(body .. Curr)
			end
		--IF command is >pay or >Pay
		elseif(string.lower(string.sub(message.content,2,4)) == "pay") then
			--Check that persion that is being paid is real
			if message.mentionedUsers.first ~= nil then
				local Target = message.mentionedUsers.first.id
				local TargetMentionName = message.mentionedUsers.first.mentionString
				local Coins
				--Break Down The Full Command to find the Number of Coins
				for word in string.gmatch(message.content, "%S+") do
					if(tonumber(word) ~= nil) then
						Coins = tonumber(word)
					end
				end
				
				sql = "select Coins from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				--Get Coins in a table
				local Rows,errorString = db:exec(sql)
				--IF There is no such ID in DB Send back sending that it's 0.it will insert it later
				if errorString == 0 then
					message.channel:send("No Money")
				else
					local Prev,New
					--Get The Coins of The Guy Paying
					for k, v in pairs(Rows) do
						if(k == "Coins") then
							Prev = v[1]
						end
					end
					--Calculate The Left Over Gold
					local Sum = tonumber(Prev) - Coins
					
					sql = "select Coins from '" .. Guild .. "' Where ID='" .. Target .. "' LIMIT 1"
					--Get the Coins in a Table of the guy being Payed
					Rows,errorString = db:exec(sql)

					for k, v in pairs(Rows) do
						if(k == "Coins") then
							New = v[1]
						end
					end
					--Check if The Guy Paying Can Afford it
					if Sum > 0 then
						sql = "UPDATE '" .. Guild .. "' SET Coins = " .. Sum .. " WHERE ID = " .. name .. ";"
						--Update the Leftover Gold
						db:exec(sql)
						Sum = New + Coins
						sql = "UPDATE '" .. Guild .. "' SET Coins = " .. Sum .. " WHERE ID = " .. Target .. ";"
						--Update Money for the Guy Being Payed
						db:exec(sql)
						--Display the MSG
						message.channel:send(AuthorMentionName .. " Payed " .. TargetMentionName .. " " .. Coins)
					else
						message.channel:send("Not Enough Money")
					end
				end
			
			
			else
				message.channel:send("To Who?")
			end
		end
	--IF There is no Command and is a normal MSG and is not on Cooldown adds gold
	elseif(name ~= "643070824403959808" and (CooldownTable[name] == false or CooldownTable[name] == nil)) then
		sql = "select Coins from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
		--Get The Coins in a table
		local Rows,errorString = db:exec(sql)
		--IF there is no such Guy in DB Create it and give him 0 gold
		if errorString == 0 then
			db:exec("insert into '" .. Guild .. "' (ID,Coins) values('" .. name .. "',0);")
		else
			local Prev,New
			--Get The Current Number of Coins
			for k, v in pairs(Rows) do
				if(k == "Coins") then
					Prev = v[1]
				end
			end
			--Calculate New Coins
			New = tonumber(Prev) + math.random(0.2,0.5)
			sql = "UPDATE '" .. Guild .. "' SET Coins = " .. New .. " WHERE ID = " .. name .. ";"
			--Update The New Number of Coins in the DB
			db:exec(sql)
			--Start the 10 Second Cooldown
			CooldownTable[name] = true
			timer.setTimeout(10000,Cooldown,name)
		end
	end
end)

client:run('Bot ')