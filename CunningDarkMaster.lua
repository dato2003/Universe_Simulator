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
local WorldDB = sql.open("WorldDB.db")
local MoneyDB = sql.open("MoneyDB.db")
local BattleDB = sql.open("BattleDB.db")

local sql = "PRAGMA journal_mode=DELETE"
db:exec(sql)

local sql = "PRAGMA journal_mode=DELETE"
WorldDB:exec(sql)

--People that are on cooldown and should not get exp will be in this table
local CooldownTable = {}

--Function to Remove People that have passed Cooldown
function Cooldown(name)
	CooldownTable[name] = false
end

function GetTroops(TroopsData)
	local Template = {"archers","swordsmen","catapult","cavalry"}
	local Troops = {}
	local stage = 1
	local number = 0

	for i=1,#TroopsData do
		local c = TroopsData:sub(i,i)

		if(string.byte(c,1) >= 48 and string.byte(c,1) <= 57) then
			number = number * 10 + tonumber(c)		
		elseif(string.byte(c,1) == 124) then
			Troops[Template[stage]] = number
			stage = stage + 1
			number = 0
		end
	end
	return Troops
end

function CollectTax()

end

local UnitsWiki = {
	["archers"] = {15,20},
	["swordsmen"] = {15,30},
	["catapult"] = {2,50},
	["cavalry"] = {10,40},
}

local CooldownTable2 = {}

function Cooldown2(name,guild)
	CooldownTable2[guild][name] = false
end

function StringChunck(str,n)
	local k,t
	t = {}
	for k in str:gmatch("[^\r\n]+") do
		table.insert(t,k)
	end
	return t
end

function GetAllianceMembers(AllianceMembers)
	local t = {0}

	for i=1,#AllianceMembers do
		local c = AllianceMembers:sub(i,i)
		if(c == ",") then
			t[#t+1] = i
		end
	end

	local AllianceMemberIDs = {}

	for i=1,#t-1 do
		AllianceMemberIDs[#AllianceMemberIDs+1] = string.sub(AllianceMembers,t[i]+1,t[i+1]-1)
	end
	
	return AllianceMemberIDs
end

function GetTroops(TroopsData)
	local Template = {"archers","swordsmen","catapult","cavalry"}
	local Troops = {}
	local stage = 1
	local number = 0

	for i=1,#TroopsData do
		local c = TroopsData:sub(i,i)

		if(string.byte(c,1) >= 48 and string.byte(c,1) <= 57) then
			number = number * 10 + tonumber(c)		
		elseif(string.byte(c,1) == 124) then
			Troops[Template[stage]] = number
			stage = stage + 1
			number = 0
		end
	end
	return Troops
end

function GetAllianceTroops(AllianceMemberIDs,GuildID)
	local AllianceTroops = {
		["archers"] = 0,
		["swordsmen"] = 0,
		["catapult"] = 0,
		["cavalry"] = 0
	}

	for i=1,#AllianceMemberIDs do
		sql = "select Troops from '" .. GuildID .. "' Where ID='" .. AllianceMemberIDs[i] .. "' LIMIT 1"
		local Rows,errorString = WorldDB:exec(sql)
		local TroopsData

		if errorString == 0 then
			print("Gold Entry Does not exist in the MoneyDB")
		else
			for k, v in pairs(Rows) do
				if(k == "Troops") then
					TroopsData = v[1]
				end
			end
		end

		local Troops = GetTroops(TroopsData)
		AllianceTroops["archers"] = AllianceTroops["archers"] + Troops["archers"]
		AllianceTroops["swordsmen"] = AllianceTroops["swordsmen"] + Troops["swordsmen"]
		AllianceTroops["catapult"] = AllianceTroops["catapult"] + Troops["catapult"]
		AllianceTroops["cavalry"] = AllianceTroops["cavalry"] + Troops["cavalry"]
	end

	return AllianceTroops
end

local UnitsWiki2 = {
	["archers"] = {2,1},
	["swordsmen"] = {3,2},
	["catapult"] = {10,1},
	["cavalry"] = {5,3},
}

local AttackQueue = {}
local AcceptedQueue = {}

client:on('messageCreate', function(message)
	local name = message.author.id
	local Guild = message.channel.guild.id
	local AuthorMentionName = message.author.mentionString

	sql = "CREATE TABLE IF NOT EXISTS '" .. Guild .. "' (ID TEXT, Coins TEXT)"
	db:exec(sql)

	if(name ~= "643070824403959808" and string.sub(message.content,1,1) == ".") then
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
				if errorString == 0 or Rows == nil then
					message.channel:send("No Money or Recipient is not Registered")
				else
					local Prev,New
					--Get The Coins of The Guy Paying
					for k, v in pairs(Rows) do
						if(k == "Coins") then
							Prev = v[1]
						end
					end
					if(Coins ~= nil and Coins > 0 and Target ~= name) then 
						--Calculate The Left Over Gold
						local Sum = tonumber(Prev) - Coins
						
						sql = "select Coins from '" .. Guild .. "' Where ID='" .. Target .. "' LIMIT 1"
						--Get the Coins in a Table of the guy being Payed
						Rows,errorString = db:exec(sql)
						if(Rows ~= nil) then
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
						else
							message.channel:send("User is not Registered")
						end
					else
						message.channel:send("How Much?")
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
			New = tonumber(Prev) + math.random(0.2,2)
			sql = "UPDATE '" .. Guild .. "' SET Coins = " .. New .. " WHERE ID = " .. name .. ";"
			--Update The New Number of Coins in the DB
			db:exec(sql)
			--Start the 10 Second Cooldown
			CooldownTable[name] = true
			timer.setTimeout(10000,Cooldown,name)
		end
	end
end)

client:on('messageCreate', function(message)
	local name = message.author.id
	local Guild = message.channel.guild.id
	local AuthorMentionName = message.author.mentionString

	local sql = "CREATE TABLE IF NOT EXISTS '" .. Guild .. "' (ID TEXT,Domain TEXT, Walls TEXT, Castle TEXT, Tavern TEXT, Training_Ground TEXT,Troops TEXT)"
	WorldDB:exec(sql)

	if(name ~= "646756600194793472" and string.sub(message.content,1,1) == ".") then
		if(string.lower(string.sub(message.content,2,#message.content)) == "getdomain") then
			local Domain = "Domain Of " .. message.author.name
			local Money = 0
			-- MODIFY THE TROOPS STRING MAKE IT MORE EASY TO USE
			local Troops = "{Archers: 0|Swordsmen: 0|Catapult: 0|Cavalry: 0|}"
			sql = "select * from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = WorldDB:exec(sql)
			if errorString == 0 then
				sql = "select Coins from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
            	Rows,errorString = MoneyDB:exec(sql)
				
            	if errorString == 0 then
                	message.channel:send("You Dont Have Enough Gold To Buy Land")
            	else
                	for k, v in pairs(Rows) do
                    	if(k == "Coins") then
                        	Money = v[1]
                    	end
                	end

                	if(tonumber(Money) >= 0) then
						WorldDB:exec("insert into '" .. Guild .. "' (ID,Domain,Walls,Castle,Tavern,Training_Ground,Troops) values('" .. name .. "','" .. Domain .."',0,0,0,0,'" .. Troops .."');")
						local NewCoins = Money + 100
						sql = "UPDATE '" .. Guild .. "' SET Coins = " .. NewCoins .. " WHERE ID = " .. name .. ";"
						MoneyDB:exec(sql)	
						message.channel:send("Welcome to the World Stage, Go forth and Conquer")
					else
						message.channel:send("Not Enough Money Bastard")
					end
				end
			else
            	message.channel:send("You Already Have Land Greedy Bastard!!")
			end
		elseif(string.lower(string.sub(message.content,2,#message.content)) == "domain") then
			
			local Walls=0
			local Castle=0
			local Tavern=0
			local Training_Ground=0
			local Domain = "Domain Of " .. message.author.name
			local HasDomain = 0


			sql = "select * from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = WorldDB:exec(sql)
			if errorString == 0 then
				HasDomain = 1
				message.channel:send("Buy Piece Of Land.(.getdomain)")
			else
				--Get The Coins
				for k, v in pairs(Rows) do
					for m,n in pairs(v) do
						if(k == "Walls") then Walls = n end
						if(k == "Castle") then Castle = n end
						if(k == "Tavern") then Tavern = n end
						if(k == "Training_Ground") then Training_Ground = n end
						if(k == "Domain") then Domain = n end
					end
				end
			end
			--print(Walls .. " " .. Castle .. " " .. Tavern .. " " .. Training_Ground)
			local WallsTable = {
				[0] = "No Walls",
				[1] = "Small Wooden Walls",
				[2] = "Small StoneWood Walls",
				[3] = "Medium Stone Walls",
				[4] = "Large Stone Walls",
			}
			local CastleTable = {
				[0] = "No Castle",
				[1] = "Small Outpost",
				[2] = "Medium Stone House",
				[3] = "Medium Stone Castle",
				[4] = "Large Stone Castle"
			}
			local TavernTable = {
				[0] = "No Tavern",
				[1] = "Small Hangout",
				[2] = "Small Drinking House",
				[3] = "Medium Pub",
				[4] = "Large Tavern",
			}
			local TrainingGroundTable = {
				[0] = "No Training Ground",
				[1] = "Small Training Field",
				[2] = "Small Target Practice",
				[3] = "Medium Quarters",
				[4] = "Large Barracks",
			}
			if(HasDomain == 0) then
				message.channel:send{embed = {
					title = Domain,
					fields = {
						{name = "Walls",value = WallsTable[tonumber(Walls)],inline = false},
						{name = "Castle",value = CastleTable[tonumber(Castle)],inline = false},
						{name = "Tavern",value = TavernTable[tonumber(Tavern)],inline = false},
						{name = "Training Ground",value = TrainingGroundTable[tonumber(Training_Ground)],inline = false},
					},
					color = discordia.Color.fromRGB(114,137,218).value,
					timestamp = discordia.Date():toISO('T',"Z")
				}}
			end
		elseif(string.lower(string.sub(message.content,2,8)) == "upgrade") then
			local Target
			
			for word in string.gmatch(message.content, "%S+") do
				if(word ~= ".upgrade") then
					Target = word
				end
			end
			
			local LandExists = 0
			local Money = 0
			local WallTiers = 0
			local CastleTiers = 0
			local TavernTiers = 0
			local TrainingGroundTiers = 0

			sql = "select Coins from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = MoneyDB:exec(sql)
			
			if errorString == 0 then
				print("Gold Entry Does not exist in the MoneyDB")
			else
				for k, v in pairs(Rows) do
					if(k == "Coins") then
						Money = v[1]
					end
				end
			end

			sql = "select * from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			Rows,errorString = WorldDB:exec(sql)
			if errorString == 0 then
				LandExists = 1
				message.channel:send("You Dont Have Land To Your Name")
			else
				for k, v in pairs(Rows) do
					for m,n in pairs(v) do
						if(k == "Walls") then WallTiers = n end
						if(k == "Castle") then CastleTiers = n end
						if(k == "Tavern") then TavernTiers = n end
						if(k == "Training_Ground") then TrainingGroundTiers = n end
					end
				end
			end
			if(Target ~= nil) then
				if(string.lower(Target) == "walls" and LandExists == 0) then
					local UpgradeCost = (WallTiers + 1) * 50
					if(tonumber(Money) >= UpgradeCost and WallTiers + 1 < 5) then
						local LeftoverGold = Money - UpgradeCost
						sql = "UPDATE '" .. Guild .. "' SET Coins = " .. LeftoverGold .. " WHERE ID = " .. name .. ";"
						MoneyDB:exec(sql)
						local NewWallTier = WallTiers + 1
						sql = "UPDATE '" .. Guild .. "' SET Walls = " .. NewWallTier .. " WHERE ID = " .. name .. ";"
						WorldDB:exec(sql)
						message.channel:send("You Have Upgraded " .. Target .. " Leftover Gold:" .. LeftoverGold)
					else
						message.channel:send("Not Enough Money or you reached max upgrade limit")
					end
				elseif(string.lower(Target) == "castle" and LandExists == 0) then
					local UpgradeCost = (CastleTiers + 1) * 50
					if(tonumber(Money) >= UpgradeCost and CastleTiers + 1 < 5) then
						local LeftoverGold = Money - UpgradeCost
						sql = "UPDATE '" .. Guild .. "' SET Coins = " .. LeftoverGold .. " WHERE ID = " .. name .. ";"
						MoneyDB:exec(sql)
						local NewCastleTier = CastleTiers + 1
						sql = "UPDATE '" .. Guild .. "' SET Castle = " .. NewCastleTier .. " WHERE ID = " .. name .. ";"
						WorldDB:exec(sql)
						message.channel:send("You Have Upgraded " .. Target .. " Leftover Gold:" .. LeftoverGold)
					else
						message.channel:send("Not Enough Money or you reached max upgrade limit")
					end
				elseif(string.lower(Target) == "tavern" and LandExists == 0) then
					local UpgradeCost = (TavernTiers + 1) * 50
					if(tonumber(Money) >= UpgradeCost and TavernTiers + 1 < 5) then
						local LeftoverGold = Money - UpgradeCost
						sql = "UPDATE '" .. Guild .. "' SET Coins = " .. LeftoverGold .. " WHERE ID = " .. name .. ";"
						MoneyDB:exec(sql)
						local NewTavernTier = TavernTiers + 1
						sql = "UPDATE '" .. Guild .. "' SET Tavern = " .. NewTavernTier .. " WHERE ID = " .. name .. ";"
						WorldDB:exec(sql)
						message.channel:send("You Have Upgraded " .. Target .. " Leftover Gold:" .. LeftoverGold)
					else
						message.channel:send("Not Enough Money or you reached max upgrade limit")
					end
				elseif(string.lower(Target) == "training_ground" and LandExists == 0) then
					local UpgradeCost = (TrainingGroundTiers + 1) * 50
					print(UpgradeCost)
					if(tonumber(Money) >= UpgradeCost and TrainingGroundTiers + 1 < 5) then
						local LeftoverGold = Money - UpgradeCost
						sql = "UPDATE '" .. Guild .. "' SET Coins = " .. LeftoverGold .. " WHERE ID = " .. name .. ";"
						MoneyDB:exec(sql)
						local NewTrainingGroundsTier = TrainingGroundTiers + 1
						sql = "UPDATE '" .. Guild .. "' SET Training_Ground = " .. NewTrainingGroundsTier .. " WHERE ID = " .. name .. ";"
						WorldDB:exec(sql)
						message.channel:send("You Have Upgraded " .. Target .. " Leftover Gold:" .. LeftoverGold)
					else
						message.channel:send("Not Enough Money or you reached max upgrade limit")
					end
				end
			else
				message.channel:send("Upgrade What You Fool!!")
			end
		elseif(string.lower(string.sub(message.content,2,6)) == "train") then
			local Unit = string.lower(string.sub(message.content,8,#message.content))
			local domainName

			sql = "select Domain from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = WorldDB:exec(sql)
			if errorString == 0 then
				HasDomain = 1
				message.channel:send("Buy Piece Of Land.(.getdomain)")
			else
				--Get The Coins
				for k, v in pairs(Rows) do
					if(k == "Domain") then domainName = v end
				end
			end

			if(UnitsWiki[Unit] ~= nil and domainName ~= nil) then 

				sql = "select * from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				Rows,errorString = WorldDB:exec(sql)
				local Tier,Capacity,TroopsData

				if errorString == 0 then
					print(errorString)
				else
					for k, v in pairs(Rows) do
						for m,n in pairs(v) do
							if(k == "Troops") then TroopsData = n end
							if(k == "Training_Ground") then Tier = n end
						end
					end
				end
				Capacity = Tier * 50
				local Troops = GetTroops(TroopsData)
				local TotalTroopsNumber = 0,Coins

				for k,v in pairs(Troops) do
					TotalTroopsNumber = TotalTroopsNumber + v
				end

				sql = "select Coins from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				local Rows,errorString = MoneyDB:exec(sql)

				if errorString == 0 then
					print("Fucked Up")
				else
					for k, v in pairs(Rows) do
						if(k == "Coins") then
							Coins = v[1]
						end
					end
				end
				if(TotalTroopsNumber + UnitsWiki[Unit][1] <= Capacity) then
					if(Coins - UnitsWiki[Unit][2] >= 0) then
						local NewCoins = Coins - UnitsWiki[Unit][2]
						sql = "UPDATE '" .. Guild .. "' SET Coins = " .. NewCoins .. " WHERE ID = " .. name .. ";"
						MoneyDB:exec(sql)

						Troops[Unit] = Troops[Unit] + UnitsWiki[Unit][1]
						--"{Archers: 0|Swordsmen: 0|Casters: 0|Cavalry: 0|}"
						local TroopsData = "{Archers: " .. Troops["archers"] .. "|Swordsmen: " .. Troops["swordsmen"] .. "|Catapult: " .. Troops["catapult"] .. "|Cavalry: " .. Troops["cavalry"] .. "|}"
						sql = "UPDATE '" .. Guild .. "' SET Troops = '" .. TroopsData .. "' WHERE ID = " .. name .. ";"
						WorldDB:exec(sql)

						message.channel:send("You Trained " .. UnitsWiki[Unit][1] .. " " .. Unit .. " At the Cost of " .. UnitsWiki[Unit][2])
						----
					else
						message.channel:send("You Dont Have Enough Money To Train " .. Unit)
					end
				else
					message.channel:send("You Can't Hold That Many Soldiers. Upgrade Your Training Grounds To Train More Soldiers")
				end
			else
				message.channel:send("That's not an unit or you dont have a domain")
			end
		elseif(string.lower(string.sub(message.content,2,#message.content)) == "army") then
			local domainName

			sql = "select Domain from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = WorldDB:exec(sql)
			if errorString == 0 then
				HasDomain = 1
				message.channel:send("Buy Piece Of Land.(.getdomain)")
			else
				--Get The Coins
				for k, v in pairs(Rows) do
					if(k == "Domain") then domainName = v end
				end
			end

			if(domainName ~= nil) then

				sql = "select Troops from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				local Rows,errorString = WorldDB:exec(sql)
				local TroopsData

				if errorString == 0 then
					print("Gold Entry Does not exist in the MoneyDB")
				else
					for k, v in pairs(Rows) do
						if(k == "Troops") then
							TroopsData = v[1]
						end
					end
				end
				local Troops = GetTroops(TroopsData)

				sql = "select Training_Ground from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				Rows,errorString = WorldDB:exec(sql)
				local Tier,Capacity

				if errorString == 0 then
					print(errorString)
				else
					for k, v in pairs(Rows) do
						if(k == "Training_Ground") then
							Tier = v[1]
						end
					end
				end
				Capacity = Tier * 50

				message.channel:send{embed = {
					title = "Army of " .. message.author.name,
					fields = {
						{name = "Capacity",value = Capacity,inline = false},
						{name = "Archers",value = Troops["archers"],inline = false},
						{name = "Swordsmen",value = Troops["swordsmen"],inline = false},
						{name = "Catapult",value = Troops["catapult"],inline = false},
						{name = "Cavalry",value = Troops["cavalry"],inline = false},
					},
					color = discordia.Color.fromRGB(114,137,218).value,
					timestamp = discordia.Date():toISO('T',"Z")
				}}
			end
		elseif(string.lower(string.sub(message.content,2,11)) == "changename") then
			local NewName = string.sub(message.content,13,#message.content)
			sql = "UPDATE '" .. Guild .. "' SET Domain = '" .. NewName .. "' WHERE ID = " .. name .. ";"
			WorldDB:exec(sql)
			message.channel:send("You Changed Name of Your Domain !")
		elseif(string.lower(string.sub(message.content,2,13)) == "collecttaxes") then
			
			sql = "select Tavern from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = WorldDB:exec(sql)
			local TavernTier

			if errorString == 0 then
				print("Tavern Entry Does not exist in the MoneyDB")
			else
				for k, v in pairs(Rows) do
					if(k == "Tavern") then
						TavernTier = v[1]
					end
				end
			end
			if(CooldownTable2[Guild] == nil or CooldownTable2[Guild][name] == nil or CooldownTable2[Guild][name] == false) then
				if(TavernTier ~= nil and TavernTier ~= '0') then
					sql = "select Coins from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
					local Rows,errorString = MoneyDB:exec(sql)
					local PrevCoins

					if errorString == 0 then
						print("Problem Getting Money")
					else
						for k, v in pairs(Rows) do
							if(k == "Coins") then
								PrevCoins = v[1]
							end
						end
					end

					local NewCoins = PrevCoins + TavernTier * 60
					sql = "UPDATE '" .. Guild .. "' SET Coins = " .. NewCoins .. " WHERE ID = " .. name .. ";"
					MoneyDB:exec(sql)

					if(CooldownTable2[Guild] == nil) then
						CooldownTable2[Guild] = {}
						CooldownTable2[Guild][name] = true
					else
						CooldownTable2[Guild][name] = true
 					end

					timer.setTimeout(21600000,Cooldown2,name,Guild)
					message.channel:send("You Collected " .. TavernTier * 60 .. " Coins in Taxes")
				else
					message.channel:send("You Don't Have A Tavern")
				end
			else
				message.channel:send("You Already Collected Taxes for now")
			end
		end
	end
end)

client:on("messageCreate", function(message)
	local name = message.author.id
	local Guild = message.channel.guild.id
	local AuthorMentionName = message.author.mentionString

	local sql = "CREATE TABLE IF NOT EXISTS '" .. Guild .. "' (ID TEXT,Alliance TEXT,Members TEXT)"
	BattleDB:exec(sql)

	if(name ~= "485447275586519062" and string.sub(message.content,1,1) == ".") then
		if(string.lower(string.sub(message.content,2,15)) == "createalliance") then
			sql = "select Alliance from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = BattleDB:exec(sql)
			local AllianceName
			
			if errorString == 0 then
				local AllianceNewName = "Alliance Of " .. message.author.name
				BattleDB:exec("insert into '" .. Guild .. "' (ID,Alliance,Members) values('" .. name .. "','" .. AllianceNewName .. "','" .. name ..",')")
				message.channel:send(AllianceNewName .. " Has Been Created")
			else
				for k, v in pairs(Rows) do
					if(k == "Alliance") then
						AllianceName = v[1]
					end
				end
			end

			if(AllianceName ~= nil) then
				message.channel:send("You Already Have an Alliance")
			end
		elseif(string.lower(string.sub(message.content,2,14)) == "viewalliances") then
			sql = "select * from '" .. Guild .. "'"
			local Rows,errorString = BattleDB:exec(sql)
			local AllianceArray = {}
			local LeaderArray = {}

			if errorString == 0 then
				print("Somethings Wrong")
			else
				for k,v in pairs(Rows) do
					if(k == "Alliance") then
						local index = 1

						while true do
							local CurrName = v[index]
							if(CurrName == nil) then
								break
							else
								AllianceArray[index] = v[index]
								index=index+1
							end
						end
					end
					if(k == "ID") then
						local index = 1

						while true do
							local CurrName = v[index]
							if(CurrName == nil) then
								break
							else
								LeaderArray[index] = v[index]
								index=index+1
							end
						end
					end
				end
			end

			local Response = ""
			for i=1,#AllianceArray do
				local LeaderName = message.channel.guild:getMember(LeaderArray[i])
				if(LeaderName ~= nil ) then
					Response = Response .. AllianceArray[i] .. "( " .. LeaderName.name.. " )" .. "\n"
				end
			end

			message.channel:send{embed = {
				title = "Alliances",
				fields = {
					{name = "Alliances At The Moment",value = Response,inline = false},
				},
				color = discordia.Color.fromRGB(114,137,218).value,
				timestamp = discordia.Date():toISO('T',"Z")
			}}
		elseif(string.lower(string.sub(message.content,2,11)) == "myalliance") then
			sql = "select * from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = BattleDB:exec(sql)
			local AllianceName,AllianceMembers

			if errorString == 0 then
				print("Error At Displaying Members of Alliance")
			else
				for k, v in pairs(Rows) do
					if(k == "Alliance") then
						AllianceName = v[1]
					end
					if(k == "Members") then
						AllianceMembers = v[1]
					end
				end
			end
			if(AllianceName ~= nil and AllianceMembers ~= nil) then
				local AllianceMemberIDs = GetAllianceMembers(AllianceMembers)
				local Response = "---------------\n"
			
				for i=1,#AllianceMemberIDs do
					local Member = message.channel.guild:getMember(AllianceMemberIDs[i])

					if(Member ~= nil) then
						Response = Response .. Member.name .. "\n"
					else
						table.remove(AllianceMemberIDs,i)
					end
				end
				
				local AllianceTroops = GetAllianceTroops(AllianceMemberIDs,Guild)
				message.channel:send{embed = {
					title = AllianceName,
					fields = {
						{name = "Members of Your Alliance",value = Response,inline = false},
						{name = "Total Archers",value = AllianceTroops["archers"],inline = false},
						{name = "Total Swordsmen",value = AllianceTroops["swordsmen"],inline = false},
						{name = "Total Catapults",value = AllianceTroops["catapult"],inline = false},
						{name = "Total Cavalry",value = AllianceTroops["cavalry"],inline = false},
					},
					color = discordia.Color.fromRGB(114,137,218).value,
					timestamp = discordia.Date():toISO('T',"Z")
				}}			
			else
				message.channel:send("You Dont Have an Alliance")
			end
		elseif(string.lower(string.sub(message.content,2,5)) == "join") then
			local TargetUser = message.mentionedUsers.first
			
			local sql = "select Domain from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = WorldDB:exec(sql)
			local DomainName

			if errorString == 0 then
				message.channel:send("Buy Piece Of Land For 200 Gold.(.getdomain)")
			else
				--Get The Coins
				for k, v in pairs(Rows) do
					if(k == "Domain") then DomainName = v end
				end

				if(TargetUser ~= nil) then
					if(DomainName ~= nil and TargetUser.id ~= name and message.channel.guild:getMember(TargetUser.id) ~= nil) then
						sql = "select Alliance from '" .. Guild .. "' Where ID='" .. TargetUser.id .. "' LIMIT 1"
						local Rows,errorString = BattleDB:exec(sql)
						local TargetAlliance
		
						if errorString == 0 then
							print("Error At Joining Alliance")
						else
							for k, v in pairs(Rows) do
								if(k == "Alliance") then
									TargetAlliance = v[1]
								end
							end
						end
		
						if(TargetAlliance ~= nil) then
							sql = "select Members from '" .. Guild .. "' Where ID='" .. TargetUser.id .. "' LIMIT 1"
							local Rows,errorString = BattleDB:exec(sql)
							local AllianceMembers
		
							if errorString == 0 then
								print("Error At Joining Alliance 2")
							else
								for k, v in pairs(Rows) do
									if(k == "Members") then
										AllianceMembers = v[1]
									end
								end
							end
							AllianceMembers = AllianceMembers .. name .. ","
		
							sql = "UPDATE '" .. Guild .. "' SET Members = '" .. AllianceMembers .. "' WHERE ID = '" .. TargetUser.id .. "';"
							BattleDB:exec(sql)
							message.channel:send("You Joined The alliance")
						else
							message.channel:send("Target User is not a Leader of an Alliance")
						end
					else
						message.channel:send("You Can't Join Your Own Alliance or The alliance does not exist.You Also Need to Own A domain to join alliances")
					end
				else
					message.channel:send("Tag An User")
				end
			end
		elseif(string.lower(string.sub(message.content,2,5)) == "quit") then
			local TargetUser = message.mentionedUsers.first
			if(TargetUser ~= nil) then
				if(TargetUser.id == name) then
					local sql = "DELETE FROM '" .. Guild .. "' WHERE ID='" .. name .. "'"
					BattleDB:exec(sql)
					message.channel:send("Your Disbanded Your Alliance")
				else
					local sql = "select Members from '" .. Guild .. "' Where ID='" .. TargetUser.id .. "' LIMIT 1"
					local Rows,errorString = BattleDB:exec(sql)
					local AllianceMembers
					local isValidAllianse = false

					if errorString == 0 then
						print("Error At Joining Alliance 2")
					else
						for k, v in pairs(Rows) do
							if(k == "Members") then
								AllianceMembers = v[1]
								isValidAllianse = true
							end
						end
					end
				
					if(isValidAllianse) then
						local Done = false
						local AllianceMemberIDs = GetAllianceMembers(AllianceMembers)
						for i=1,#AllianceMemberIDs do
							local Member = message.channel.guild:getMember(AllianceMemberIDs[i])

							if(Member ~= nil) then
								if(Member.id == name) then
									AllianceMembers = string.gsub(AllianceMembers,name .. ",","")
									sql = "UPDATE '" .. Guild .. "' SET Members = '" .. AllianceMembers .. "' WHERE ID = '" .. TargetUser.id .. "';"
									BattleDB:exec(sql)	
									Done = true
									message.channel:send("You Quit The Alliance")	
									break						
								end
							end
						end
						if(Done	== false) then
							message.channel:send("You are not in that alliance")
						end
					end
				end
			else
				message.channel:send("You need to tag a user to quit alliance from")
			end
		elseif(string.lower(string.sub(message.content,2,13)) == "submitattack" and message.mentionedUsers.first ~= nil and message.mentionedUsers.first.id ~= author) then
			if(AttackQueue[name] == nil) then
				AttackQueue[name] = message.mentionedUsers.first.id
				print("Worked 1")
				message.channel:send(message.mentionedUsers.first.mentionString .. " is Challenged to a field battle by " .. message.author.mentionString)
			else
				message.channel:send("You Already have a challenge Pending")
			end
		elseif(string.lower(string.sub(message.content,2,13)) == "cancelattack" and message.mentionedUsers.first ~= nil and message.mentionedUsers.first.id ~= author) then
			if(AttackQueue[name] ~= nil) then
				AttackQueue[name] = nil
				print("Worked 2")
				message.channel:send(message.author.mentionString .. " Cancelled the field battle challenge against " .. message.mentionedUsers.first.mentionString)
			else
				message.channel:send("You Don't have a challenge pending")
			end
		elseif(string.lower(string.sub(message.content,2,13)) == "acceptattack" and message.mentionedUsers.first ~= nil and message.mentionedUsers.first.id ~= author) then
			if(AttackQueue[message.mentionedUsers.first.id] == name) then
				AcceptedQueue[message.mentionedUsers.first.id] = name
				AttackQueue[message.mentionedUsers.first.id] = nil
				print("Worked 3")
				message.channel:send(message.mentionedUsers.first.mentionString .. "'s challenge was accepted by " .. message.author.mentionString)
			else
				message.channel:send("You don't have a pending challenge from that lord")
			end
		elseif(string.lower(string.sub(message.content,2,7)) == "attack" and message.mentionedUsers.first ~= nil and message.mentionedUsers.first.id ~= author and AcceptedQueue[name] == message.mentionedUsers.first.id) then
			local Target = message.mentionedUsers.first
			local EnemyDomain,FriendlyDomain
			
			local sql = "select Domain from '" .. Guild .. "' Where ID='" .. Target.id .. "' LIMIT 1"
			local Rows,errorString = WorldDB:exec(sql)

			if errorString == 0 then
				print("Error At Joining Alliance 3")
			else
				for k, v in pairs(Rows) do
					if(k == "Domain") then
						EnemyDomain = v[1]
					end
				end
			end

			local sql = "select Domain from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = WorldDB:exec(sql)

			if errorString == 0 then
				print("Error At Joining Alliance 3")
			else
				for k, v in pairs(Rows) do
					if(k == "Domain") then
						FriendlyDomain = v[1]
					end
				end
			end
			if(FriendlyDomain ~= nil and EnemyDomain ~= nil) then
				local FightTranscript = ""
				local EnemyAllianceMembers,FriendlyAllianceMembers,EnemyAllianceName,FriendlyAllianceName
				local FriendlyCastleTier
				local EnemyCastleTier
				local EnemyAllianceMembers,FriendlyAllianceMembers
				local EnemyAllianceMemberIDs,FriendlyAllianceMemberIDs

				local sql = "select Castle from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				local Rows,errorString = WorldDB:exec(sql)

				if errorString == 0 then
					print("Error At Getting Alliance 99")
				else
					for k, v in pairs(Rows) do
						if(k == "Castle") then
							FriendlyCastleTier = v[1]
						end
					end
				end

				local sql = "select Castle from '" .. Guild .. "' Where ID='" .. Target.id .. "' LIMIT 1"
				local Rows,errorString = WorldDB:exec(sql)

				if errorString == 0 then
					print("Error At Getting Alliance 99")
				else
					for k, v in pairs(Rows) do
						if(k == "Castle") then
							EnemyCastleTier = v[1]
						end
					end
				end

				local sql = "select Members from '" .. Guild .. "' Where ID='" .. Target.id .. "' LIMIT 1"
				local Rows,errorString = BattleDB:exec(sql)

				if errorString == 0 then
					print("Error At Joining Alliance 3")
				else
					for k, v in pairs(Rows) do
						if(k == "Members") then
							EnemyAllianceMembers = v[1]
						end
					end
				end

				local sql = "select Alliance from '" .. Guild .. "' Where ID='" .. Target.id .. "' LIMIT 1"
				local Rows,errorString = BattleDB:exec(sql)

				if errorString == 0 then
					print("Error At Getting Alliance 34")
				else
					for k, v in pairs(Rows) do
						if(k == "Alliance") then
							EnemyAllianceName = v[1]
						end
					end
				end

				local sql = "select Alliance from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				local Rows,errorString = BattleDB:exec(sql)

				if errorString == 0 then
					print("Error At Getting Alliance 99")
				else
					for k, v in pairs(Rows) do
						if(k == "Alliance") then
							FriendlyAllianceName = v[1]
						end
					end
				end

				local FriendlyAllianceTroops
				local EnemyAllianceTroops
				local AllTroops = {
					["archers"] = 0,
					["swordsmen"] = 0,
					["catapult"] = 0,
					["cavalry"] = 0
				}
				local TotalTroopsNumber = 0
				local TotalFriendlyTroopsNumber = 0
				local FriendlyTroopsNumberAtBeginning = 0
				local EnemyTroopsNumberAtBeginning = 0
				local TotalEnemyTroopsNumber = 0
				local FriendlyTemplate = {}
				local EnemyTemplate = {}
				local FriendlyCasualities = {
					["archers"] = 0,
					["swordsmen"] = 0,
					["catapult"] = 0,
					["cavalry"] = 0
				}
				local EnemyCasualities = {
					["archers"] = 0,
					["swordsmen"] = 0,
					["catapult"] = 0,
					["cavalry"] = 0
				}

				local sql = "select Members from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				local Rows,errorString = BattleDB:exec(sql)

				if errorString == 0 then
					print("Error At Joining Alliance 4")
				else
					for k, v in pairs(Rows) do
						if(k == "Members") then
							FriendlyAllianceMembers = v[1]
						end
					end
				end
			
				if(EnemyAllianceMembers ~= nil) then
					EnemyAllianceMemberIDs = GetAllianceMembers(EnemyAllianceMembers)

					for i=1,#EnemyAllianceMemberIDs do
						local Member = message.channel.guild:getMember(EnemyAllianceMemberIDs[i])
						if(Member == nil) then
							table.remove(EnemyAllianceMemberIDs,i)
						end
					end

					EnemyAllianceTroops = GetAllianceTroops(EnemyAllianceMemberIDs,Guild)
				end
				if(FriendlyAllianceMembers ~= nil) then
					FriendlyAllianceMemberIDs = GetAllianceMembers(FriendlyAllianceMembers)

					for i=1,#FriendlyAllianceMemberIDs do
						local Member = message.channel.guild:getMember(FriendlyAllianceMemberIDs[i])
						if(Member == nil) then
							table.remove(FriendlyAllianceMemberIDs,i)
						end
					end

					FriendlyAllianceTroops = GetAllianceTroops(FriendlyAllianceMemberIDs,Guild)
				end
				if(EnemyAllianceMembers == nil) then
					EnemyAllianceMemberIDs = {Target.id}
					EnemyAllianceTroops = GetAllianceTroops({Target.id},Guild)
					print("ENEMY ALLIANCE NILL")
				end
				if(FriendlyAllianceMembers == nil) then
					FriendlyAllianceMemberIDs = {name}
					FriendlyAllianceTroops = GetAllianceTroops({name},Guild)
				end
				if(EnemyAllianceName == nil) then
					print("NILL")
					EnemyAllianceName = Target.name
				end
				if(FriendlyAllianceName == nil) then
					print("AJDSK")
					FriendlyAllianceName = message.author.name
				end

				AllTroops["archers"] = FriendlyAllianceTroops["archers"] + EnemyAllianceTroops["archers"]
				AllTroops["swordsmen"] = FriendlyAllianceTroops["swordsmen"] + EnemyAllianceTroops["swordsmen"]
				AllTroops["catapult"] = FriendlyAllianceTroops["catapult"] + EnemyAllianceTroops["catapult"]
				AllTroops["cavalry"] = FriendlyAllianceTroops["cavalry"] + EnemyAllianceTroops["cavalry"]

				TotalFriendlyTroopsNumber = FriendlyAllianceTroops["archers"] + FriendlyAllianceTroops["swordsmen"] + FriendlyAllianceTroops["catapult"] + FriendlyAllianceTroops["cavalry"]
				TotalEnemyTroopsNumber = EnemyAllianceTroops["archers"] + EnemyAllianceTroops["swordsmen"] + EnemyAllianceTroops["catapult"] + EnemyAllianceTroops["cavalry"]
				
				FriendlyTroopsNumberAtBeginning = TotalFriendlyTroopsNumber
				EnemyTroopsNumberAtBeginning = TotalEnemyTroopsNumber

				TotalTroopsNumber = AllTroops["archers"] + AllTroops["swordsmen"] + AllTroops["catapult"] + AllTroops["cavalry"]

				if(FriendlyAllianceTroops["archers"] > 0) then
					FriendlyTemplate[1] = "archers"
				end
				if(FriendlyAllianceTroops["swordsmen"] > 0) then
					FriendlyTemplate[2] = "swordsmen"
				end
				if(FriendlyAllianceTroops["catapult"] > 0) then
					FriendlyTemplate[3] = "catapult"
				end
				if(FriendlyAllianceTroops["cavalry"] > 0) then
					FriendlyTemplate[4] = "cavalry"
				end

				if(EnemyAllianceTroops["archers"] > 0) then
					EnemyTemplate[1] = "archers"
				end
				if(EnemyAllianceTroops["swordsmen"] > 0) then
					EnemyTemplate[2] = "swordsmen"
				end
				if(EnemyAllianceTroops["catapult"] > 0) then
					EnemyTemplate[3] = "catapult"
				end
				if(EnemyAllianceTroops["cavalry"] > 0) then
					EnemyTemplate[4] = "cavalry"
				end

				local FriendlyTurns = {}
				local EnemyTurns = {}
				math.randomseed(os.time())
				for i=1,TotalTroopsNumber do
					local turn = math.random(2)
					if((turn == 1 and TotalFriendlyTroopsNumber > 0) or (turn == 2 and TotalEnemyTroopsNumber <= 0)) then
						local keyset = {}
						local n = 0
						for k,v in pairs(FriendlyTemplate) do
							n=n+1
							keyset[n] = k
						end
						local unitchoice = math.random(#keyset)
						
						FriendlyTurns[i] = FriendlyTemplate[keyset[unitchoice]]
						FriendlyAllianceTroops[FriendlyTemplate[keyset[unitchoice]]] = FriendlyAllianceTroops[FriendlyTemplate[keyset[unitchoice]]] - 1
						if(FriendlyAllianceTroops[FriendlyTemplate[keyset[unitchoice]]] == 0) then
							local index
							for k,v in pairs(FriendlyTemplate) do
								if(v == FriendlyTemplate[keyset[unitchoice]]) then
									index = k
								end
							end
							table.remove(FriendlyTemplate,index)
						end
						TotalFriendlyTroopsNumber=TotalFriendlyTroopsNumber-1

						--[[print("Total Friendly Remain : " .. TotalFriendlyTroopsNumber)
						print("Friendly Archers : " ..  FriendlyAllianceTroops["archers"])
						print("Friendly Swordsmen : " ..  FriendlyAllianceTroops["swordsmen"])
						print("Friendly Casters : " ..  FriendlyAllianceTroops["casters"])
						print("Friendly Cavalry : " ..  FriendlyAllianceTroops["cavalry"])
						print("\n\n\n")]]
					elseif(turn == 2 and TotalEnemyTroopsNumber > 0) then
						local keyset = {}
						local n = 0
						for k,v in pairs(EnemyTemplate) do
							n=n+1
							keyset[n] = k
						end
						local unitchoice = math.random(#keyset)

						EnemyTurns[i] = EnemyTemplate[keyset[unitchoice]]
						EnemyAllianceTroops[EnemyTemplate[keyset[unitchoice]]] = EnemyAllianceTroops[EnemyTemplate[keyset[unitchoice]]] - 1
						if(EnemyAllianceTroops[EnemyTemplate[keyset[unitchoice]]] == 0) then
							local index
							for k,v in pairs(EnemyTemplate) do
								if(v == EnemyTemplate[keyset[unitchoice]]) then
									index = k
								end
							end
							table.remove(EnemyTemplate,index)
						end
						TotalEnemyTroopsNumber = TotalEnemyTroopsNumber - 1
						--[[print("Total Enemy Remain : " .. TotalEnemyTroopsNumber)
						print("Enemy Archers : " ..  EnemyAllianceTroops["archers"])
						print("Enemy Swordsmen : " ..  EnemyAllianceTroops["swordsmen"])
						print("Enemy Casters : " ..  EnemyAllianceTroops["casters"])
						print("Enemy Cavalry : " ..  EnemyAllianceTroops["cavalry"])
						print("\n\n\n")]]
					end
				end

				print("\n")
				math.randomseed(os.time())
				for i=1,TotalTroopsNumber do

					if(FriendlyTurns[i] ~= nil) then
						local keyset = {}
						local n = 0
						for k,v in pairs(EnemyTurns) do
							n=n+1
							keyset[n] = k
						end
						local unitchoice = math.random(#keyset)
						if(keyset[unitchoice] ~= nil) then
							local AttackRoll = math.random(20) + UnitsWiki2[FriendlyTurns[i]][1] + FriendlyCastleTier
							local DefenseRoll = math.random(20) + UnitsWiki2[EnemyTurns[keyset[unitchoice]]][2] + EnemyCastleTier
							--print("Friendly " .. FriendlyTurns[i] .. " VS Enemy " .. EnemyTurns[keyset[unitchoice]])
							FightTranscript = FightTranscript .. "Friendly " .. FriendlyTurns[i] .. " VS Enemy " .. EnemyTurns[keyset[unitchoice]] .. "\n"
							if(AttackRoll > DefenseRoll) then
								--print("Friendly " .. FriendlyTurns[i] .. " Killed Enemy " .. EnemyTurns[keyset[unitchoice]])
								FightTranscript = FightTranscript .. "Friendly " .. FriendlyTurns[i] .. " Killed Enemy " .. EnemyTurns[keyset[unitchoice]] .. " (" .. AttackRoll .. "," .. DefenseRoll .. ")\n"
								EnemyCasualities[EnemyTurns[keyset[unitchoice]]] = EnemyCasualities[EnemyTurns[keyset[unitchoice]]] + 1
								table.remove(EnemyTurns,keyset[unitchoice])
							else
								--print("Enemy " .. EnemyTurns[keyset[unitchoice]] .. " Survived")
								FightTranscript = FightTranscript .. "Enemy " .. EnemyTurns[keyset[unitchoice]] .. " Survived" .. " (" .. AttackRoll .. "," .. DefenseRoll .. ")\n"
							end
						else
							print("ATTACK NO ENEMY UNIT")
						end
					elseif(EnemyTurns[i] ~= nil) then
						local keyset = {}
						local n = 0
						for k,v in pairs(FriendlyTurns) do
							n=n+1
							keyset[n] = k
						end
						local unitchoice = math.random(#keyset)
						if(keyset[unitchoice] ~= nil) then
							local AttackRoll = math.random(20) + UnitsWiki2[EnemyTurns[i]][1] + EnemyCastleTier
							local DefenseRoll = math.random(20) + UnitsWiki2[FriendlyTurns[keyset[unitchoice]]][2] + FriendlyCastleTier
							--print("Enemy " .. EnemyTurns[i] .. " VS Friendly " .. FriendlyTurns[keyset[unitchoice]])
							FightTranscript = FightTranscript .. "Enemy " .. EnemyTurns[i] .. " VS Friendly " .. FriendlyTurns[keyset[unitchoice]] .. "\n"
							if(AttackRoll > DefenseRoll) then
								--print("Enemy " .. EnemyTurns[i] .. " Killed Friendly " .. FriendlyTurns[keyset[unitchoice]])
								FightTranscript = FightTranscript .. "Enemy " .. EnemyTurns[i] .. " Killed Friendly " .. FriendlyTurns[keyset[unitchoice]] .. " (" .. AttackRoll .. "," .. DefenseRoll .. ")\n"
								FriendlyCasualities[FriendlyTurns[keyset[unitchoice]]] = FriendlyCasualities[FriendlyTurns[keyset[unitchoice]]] + 1
								table.remove(FriendlyTurns,keyset[unitchoice])
							else
								--print("Friendly " .. FriendlyTurns[keyset[unitchoice]] .. " Survived")
								FightTranscript = FightTranscript .. "Friendly " .. FriendlyTurns[keyset[unitchoice]] .. " Survived" .. " (" .. AttackRoll .. "," .. DefenseRoll .. ")\n"
							end
						else
							print("ATTACK NO ENEMY UNIT")
						end
					end
				end
			
				local AverageFriendlyArcherLoss = math.floor(FriendlyCasualities["archers"] / #FriendlyAllianceMemberIDs)
				local AverageFriendlySwordsmanLoss = math.floor(FriendlyCasualities["swordsmen"] / #FriendlyAllianceMemberIDs)
				local AverageFriendlyCasterLoss = math.floor(FriendlyCasualities["catapult"] / #FriendlyAllianceMemberIDs)
				local AverageFriendlyCavalryLoss = math.floor(FriendlyCasualities["cavalry"] / #FriendlyAllianceMemberIDs)

				local AverageEnemyArcherLoss = math.floor(EnemyCasualities["archers"] / #EnemyAllianceMemberIDs)
				local AverageEnemySwordsmanLoss = math.floor(EnemyCasualities["swordsmen"] / #EnemyAllianceMemberIDs)
				local AverageEnemyCasterLoss = math.floor(EnemyCasualities["catapult"] / #EnemyAllianceMemberIDs)
				local AverageEnemyCavalryLoss = math.floor(EnemyCasualities["cavalry"] / #EnemyAllianceMemberIDs)
				
				for i=1,#FriendlyAllianceMemberIDs do
					local sql = "select Troops from '" .. Guild .. "' Where ID='" .. FriendlyAllianceMemberIDs[i] .. "' LIMIT 1"
					local Rows,errorString = WorldDB:exec(sql)
					local Troops,TroopsData

					if errorString == 0 then
						print(errorString)
					else
						for k, v in pairs(Rows) do
							if(k == "Troops") then TroopsData = v[1] end
						end
					end

					Troops = GetTroops(TroopsData)
					local Archers = Troops["archers"] - AverageFriendlyArcherLoss
					if(Archers < 0 ) then Archers = 0 end

					local Swordsmen = Troops["swordsmen"] - AverageFriendlySwordsmanLoss
					if(Swordsmen < 0 ) then Swordsmen = 0 end

					local Casters = Troops["catapult"] - AverageFriendlyCasterLoss
					if(Casters < 0 ) then Casters = 0 end

					local Cavalry = Troops["cavalry"] - AverageFriendlyCavalryLoss
					if(Cavalry < 0 ) then Cavalry = 0 end

					local TroopsData = "{Archers: " .. Archers .. "|Swordsmen: " .. Swordsmen .. "|Catapult: " .. Casters .. "|Cavalry: " .. Cavalry .. "|}"
					sql = "UPDATE '" .. Guild .. "' SET Troops = '" .. TroopsData .. "' WHERE ID = " .. FriendlyAllianceMemberIDs[i] .. ";"
					WorldDB:exec(sql)
				end

				for i=1,#EnemyAllianceMemberIDs do
					local sql = "select Troops from '" .. Guild .. "' Where ID='" .. EnemyAllianceMemberIDs[i] .. "' LIMIT 1"
					local Rows,errorString = WorldDB:exec(sql)
					local Troops,TroopsData

					if errorString == 0 then
						print(errorString)
					else
						for k, v in pairs(Rows) do
							if(k == "Troops") then TroopsData = v[1] end
						end
					end

					Troops = GetTroops(TroopsData)
					local Archers = Troops["archers"] - AverageEnemyArcherLoss
					if(Archers < 0 ) then Archers = 0 end

					local Swordsmen = Troops["swordsmen"] - AverageEnemySwordsmanLoss
					if(Swordsmen < 0 ) then Swordsmen = 0 end

					local Casters = Troops["catapult"] - AverageEnemyCasterLoss
					if(Casters < 0 ) then Casters = 0 end

					local Cavalry = Troops["cavalry"] - AverageEnemyCavalryLoss
					if(Cavalry < 0 ) then Cavalry = 0 end

					local TroopsData = "{Archers: " .. Archers .. "|Swordsmen: " .. Swordsmen .. "|Catapult: " .. Casters .. "|Cavalry: " .. Cavalry .. "|}"
					sql = "UPDATE '" .. Guild .. "' SET Troops = '" .. TroopsData .. "' WHERE ID = " .. EnemyAllianceMemberIDs[i] .. ";"
					WorldDB:exec(sql)
				end


				--print(#FightTranscript)
                --[[
				for k,v in pairs(StringChunck(FightTranscript,#FightTranscript/35)) do
					message.channel:send("```" .. v .. "```")
				end]]

				message.channel:send{embed = {
					title = "Battle Between " .. FriendlyAllianceName .. " And " .. EnemyAllianceName,
					fields = {
						--{name = "BATTLE",value = FightTranscript,inline = false},
						{name = FriendlyAllianceName .. " Archer Casualties",value = FriendlyCasualities["archers"],inline = false},
						{name = FriendlyAllianceName .. " Swordsman Casualties",value = FriendlyCasualities["swordsmen"],inline = false},
						{name = FriendlyAllianceName .. " Catapult Casualties",value = FriendlyCasualities["catapult"],inline = false},
						{name = FriendlyAllianceName .. " Cavalry Casualties",value = FriendlyCasualities["cavalry"],inline = false},

						{name = EnemyAllianceName .. " Archer Casualties",value = EnemyCasualities["archers"],inline = false},
						{name = EnemyAllianceName .. " Swordsman Casualties",value = EnemyCasualities["swordsmen"],inline = false},
						{name = EnemyAllianceName .. " Catapult Casualties",value = EnemyCasualities["catapult"],inline = false},
						{name = EnemyAllianceName .. " Cavalry Casualties",value = EnemyCasualities["cavalry"],inline = false},
					},
					color = discordia.Color.fromRGB(114,137,218).value,
					timestamp = discordia.Date():toISO('T',"Z")
				}}
				AcceptedQueue[name] = nil
			else
				message.channel:send("You and the Enemy Both Must Have a Domain (get one by .getdomain)")
			end
		elseif(string.lower(string.sub(message.content,2,13)) == "domainattack" and message.mentionedUsers.first ~= nil and message.mentionedUsers.first.id ~= author) then
			local Target = message.mentionedUsers.first
			local EnemyDomain,FriendlyDomain
			
			local sql = "select Domain from '" .. Guild .. "' Where ID='" .. Target.id .. "' LIMIT 1"
			local Rows,errorString = WorldDB:exec(sql)

			if errorString == 0 then
				print("Error At Joining Alliance 3")
			else
				for k, v in pairs(Rows) do
					if(k == "Domain") then
						EnemyDomain = v[1]
					end
				end
			end

			local sql = "select Domain from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = WorldDB:exec(sql)

			if errorString == 0 then
				print("Error At Joining Alliance 3")
			else
				for k, v in pairs(Rows) do
					if(k == "Domain") then
						FriendlyDomain = v[1]
					end
				end
			end
			if(FriendlyDomain ~= nil and EnemyDomain ~= nil) then
				local FightTranscript = ""
				local EnemyAllianceMembers,FriendlyAllianceMembers,EnemyAllianceName,FriendlyAllianceName,EnemyWallsTier
				local FriendlyCastleTier
				local EnemyCastleTier

				local sql = "select Walls from '" .. Guild .. "' Where ID='" .. Target.id .. "' LIMIT 1"
				local Rows,errorString = WorldDB:exec(sql)

				if errorString == 0 then
					print("Error At Getting Alliance 99")
				else
					for k, v in pairs(Rows) do
						if(k == "Walls") then
							EnemyWallsTier = v[1]
						end
					end
				end

				local sql = "select Castle from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				local Rows,errorString = WorldDB:exec(sql)

				if errorString == 0 then
					print("Error At Getting Alliance 99")
				else
					for k, v in pairs(Rows) do
						if(k == "Castle") then
							FriendlyCastleTier = v[1]
						end
					end
				end

				local sql = "select Castle from '" .. Guild .. "' Where ID='" .. Target.id .. "' LIMIT 1"
				local Rows,errorString = WorldDB:exec(sql)

				if errorString == 0 then
					print("Error At Getting Alliance 99")
				else
					for k, v in pairs(Rows) do
						if(k == "Castle") then
							EnemyCastleTier = v[1]
						end
					end
				end

				local sql = "select Alliance from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				local Rows,errorString = BattleDB:exec(sql)

				if errorString == 0 then
					print("Error At Getting Alliance 99")
				else
					for k, v in pairs(Rows) do
						if(k == "Alliance") then
							FriendlyAllianceName = v[1]
						end
					end
				end


				local EnemyAllianceMembers,FriendlyAllianceMembers
				local EnemyAllianceMemberIDs,FriendlyAllianceMemberIDs

				local FriendlyAllianceTroops
				local EnemyAllianceTroops
				local AllTroops = {
					["archers"] = 0,
					["swordsmen"] = 0,
					["catapult"] = 0,
					["cavalry"] = 0
				}
				local TotalTroopsNumber = 0
				local TotalFriendlyTroopsNumber = 0
				local FriendlyTroopsNumberAtBeginning = 0
				local TotalEnemyTroopsNumber = 0
				local EnemyTroopsNumberAtBeginning = 0
				local FriendlyTemplate = {}
				local EnemyTemplate = {}
				local FriendlyCasualities = {
					["archers"] = 0,
					["swordsmen"] = 0,
					["catapult"] = 0,
					["cavalry"] = 0
				}
				local EnemyCasualities = {
					["archers"] = 0,
					["swordsmen"] = 0,
					["catapult"] = 0,
					["cavalry"] = 0
				}

				local sql = "select Members from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
				local Rows,errorString = BattleDB:exec(sql)

				if errorString == 0 then
					print("Error At Joining Alliance 4")
				else
					for k, v in pairs(Rows) do
						if(k == "Members") then
							FriendlyAllianceMembers = v[1]
						end
					end
				end
			
				if(EnemyAllianceMembers ~= nil) then
					EnemyAllianceMemberIDs = GetAllianceMembers(EnemyAllianceMembers)

					for i=1,#EnemyAllianceMemberIDs do
						local Member = message.channel.guild:getMember(EnemyAllianceMemberIDs[i])
						if(Member == nil) then
							table.remove(EnemyAllianceMemberIDs,i)
						end
					end

					EnemyAllianceTroops = GetAllianceTroops(EnemyAllianceMemberIDs,Guild)
				end
				if(FriendlyAllianceMembers ~= nil) then
					FriendlyAllianceMemberIDs = GetAllianceMembers(FriendlyAllianceMembers)

					for i=1,#FriendlyAllianceMemberIDs do
						local Member = message.channel.guild:getMember(FriendlyAllianceMemberIDs[i])
						if(Member == nil) then
							table.remove(FriendlyAllianceMemberIDs,i)
						end
					end

					FriendlyAllianceTroops = GetAllianceTroops(FriendlyAllianceMemberIDs,Guild)
				end
				if(EnemyAllianceMembers == nil) then
					EnemyAllianceMemberIDs = {Target.id}
					EnemyAllianceTroops = GetAllianceTroops({Target.id},Guild)
				end
				if(FriendlyAllianceMembers == nil) then
					FriendlyAllianceMemberIDs = {name}
					FriendlyAllianceTroops = GetAllianceTroops({name},Guild)
				end
				if(EnemyAllianceName == nil) then
					print("mmm")
					EnemyAllianceName = Target.name
				end
				if(FriendlyAllianceName == nil) then
					print("nn")
					FriendlyAllianceName = message.author.name
				end

				AllTroops["archers"] = FriendlyAllianceTroops["archers"] + EnemyAllianceTroops["archers"]
				AllTroops["swordsmen"] = FriendlyAllianceTroops["swordsmen"] + EnemyAllianceTroops["swordsmen"]
				AllTroops["catapult"] = FriendlyAllianceTroops["catapult"] + EnemyAllianceTroops["catapult"]
				AllTroops["cavalry"] = FriendlyAllianceTroops["cavalry"] + EnemyAllianceTroops["cavalry"]

				TotalFriendlyTroopsNumber = FriendlyAllianceTroops["archers"] + FriendlyAllianceTroops["swordsmen"] + FriendlyAllianceTroops["catapult"] + FriendlyAllianceTroops["cavalry"]
				TotalEnemyTroopsNumber = EnemyAllianceTroops["archers"] + EnemyAllianceTroops["swordsmen"] + EnemyAllianceTroops["catapult"] + EnemyAllianceTroops["cavalry"]
				FriendlyTroopsNumberAtBeginning = TotalFriendlyTroopsNumber
				EnemyTroopsNumberAtBeginning = TotalEnemyTroopsNumber

				TotalTroopsNumber = AllTroops["archers"] + AllTroops["swordsmen"] + AllTroops["catapult"] + AllTroops["cavalry"]

				if(FriendlyAllianceTroops["archers"] > 0) then
					FriendlyTemplate[1] = "archers"
				end
				if(FriendlyAllianceTroops["swordsmen"] > 0) then
					FriendlyTemplate[2] = "swordsmen"
				end
				if(FriendlyAllianceTroops["catapult"] > 0) then
					FriendlyTemplate[3] = "catapult"
				end
				if(FriendlyAllianceTroops["cavalry"] > 0) then
					FriendlyTemplate[4] = "cavalry"
				end

				if(EnemyAllianceTroops["archers"] > 0) then
					EnemyTemplate[1] = "archers"
				end
				if(EnemyAllianceTroops["swordsmen"] > 0) then
					EnemyTemplate[2] = "swordsmen"
				end
				if(EnemyAllianceTroops["catapult"] > 0) then
					EnemyTemplate[3] = "catapult"
				end
				if(EnemyAllianceTroops["cavalry"] > 0) then
					EnemyTemplate[4] = "cavalry"
				end

				local FriendlyTurns = {}
				local EnemyTurns = {}
				math.randomseed(os.time())

				for i=1,TotalTroopsNumber do
					local turn = math.random(2)
					if((turn == 1 and TotalFriendlyTroopsNumber > 0) or (turn == 2 and TotalEnemyTroopsNumber <= 0)) then
						local keyset = {}
						local n = 0
						for k,v in pairs(FriendlyTemplate) do
							n=n+1
							keyset[n] = k
						end
						local unitchoice = math.random(#keyset)

						FriendlyTurns[i] = FriendlyTemplate[keyset[unitchoice]]
						FriendlyAllianceTroops[FriendlyTemplate[keyset[unitchoice]]] = FriendlyAllianceTroops[FriendlyTemplate[keyset[unitchoice]]] - 1
						if(FriendlyAllianceTroops[FriendlyTemplate[keyset[unitchoice]]] == 0) then
							local index
							for k,v in pairs(FriendlyTemplate) do
								if(v == FriendlyTemplate[keyset[unitchoice]]) then
									index = k
								end
							end
							table.remove(FriendlyTemplate,index)
						end
						TotalFriendlyTroopsNumber=TotalFriendlyTroopsNumber-1

						--[[print("Total Friendly Remain : " .. TotalFriendlyTroopsNumber)
						print("Friendly Archers : " ..  FriendlyAllianceTroops["archers"])
						print("Friendly Swordsmen : " ..  FriendlyAllianceTroops["swordsmen"])
						print("Friendly Casters : " ..  FriendlyAllianceTroops["casters"])
						print("Friendly Cavalry : " ..  FriendlyAllianceTroops["cavalry"])
						print("\n\n\n")]]
					elseif(turn == 2 and TotalEnemyTroopsNumber > 0) then
						local keyset = {}
						local n = 0
						for k,v in pairs(EnemyTemplate) do
							n=n+1
							keyset[n] = k
						end
						local unitchoice = math.random(#keyset)

						EnemyTurns[i] = EnemyTemplate[keyset[unitchoice]]
						EnemyAllianceTroops[EnemyTemplate[keyset[unitchoice]]] = EnemyAllianceTroops[EnemyTemplate[keyset[unitchoice]]] - 1
						if(EnemyAllianceTroops[EnemyTemplate[keyset[unitchoice]]] == 0) then
							local index
							for k,v in pairs(EnemyTemplate) do
								if(v == EnemyTemplate[keyset[unitchoice]]) then
									index = k
								end
							end
							table.remove(EnemyTemplate,index)
						end
						TotalEnemyTroopsNumber = TotalEnemyTroopsNumber - 1
						--[[print("Total Enemy Remain : " .. TotalEnemyTroopsNumber)
						print("Enemy Archers : " ..  EnemyAllianceTroops["archers"])
						print("Enemy Swordsmen : " ..  EnemyAllianceTroops["swordsmen"])
						print("Enemy Casters : " ..  EnemyAllianceTroops["casters"])
						print("Enemy Cavalry : " ..  EnemyAllianceTroops["cavalry"])
						print("\n\n\n")]]
					end
				end

				print("\n")
				math.randomseed(os.time())
				local EnemyHasNoTroops = false
				local FriendlyHasNoTroops = false

				for i=1,TotalTroopsNumber do

					if(FriendlyTurns[i] ~= nil) then
						local keyset = {}
						local n = 0
						for k,v in pairs(EnemyTurns) do
							n=n+1
							keyset[n] = k
						end
						local unitchoice = math.random(#keyset)
						if(keyset[unitchoice] ~= nil) then
							local AttackRoll = math.random(20) + UnitsWiki2[FriendlyTurns[i]][1] + FriendlyCastleTier
							local DefenseRoll = math.random(20) + UnitsWiki2[EnemyTurns[keyset[unitchoice]]][2] + (2 * EnemyWallsTier) + EnemyCastleTier
							--print("Friendly " .. FriendlyTurns[i] .. " VS Enemy " .. EnemyTurns[keyset[unitchoice]])
							FightTranscript = FightTranscript .. "Friendly " .. FriendlyTurns[i] .. " VS Enemy " .. EnemyTurns[keyset[unitchoice]] .. "\n"
							if(AttackRoll > DefenseRoll) then
								--print("Friendly " .. FriendlyTurns[i] .. " Killed Enemy " .. EnemyTurns[keyset[unitchoice]])
								FightTranscript = FightTranscript .. "Friendly " .. FriendlyTurns[i] .. " Killed Enemy " .. EnemyTurns[keyset[unitchoice]] .. " (" .. AttackRoll .. "," .. DefenseRoll .. ")\n"
								EnemyCasualities[EnemyTurns[keyset[unitchoice]]] = EnemyCasualities[EnemyTurns[keyset[unitchoice]]] + 1
								table.remove(EnemyTurns,keyset[unitchoice])
							else
								--print("Enemy " .. EnemyTurns[keyset[unitchoice]] .. " Survived")
								FightTranscript = FightTranscript .. "Enemy " .. EnemyTurns[keyset[unitchoice]] .. " Survived" .. " (" .. AttackRoll .. "," .. DefenseRoll .. ")\n"
							end
						else
							EnemyHasNoTroops = true
						end
					elseif(EnemyTurns[i] ~= nil) then
						local keyset = {}
						local n = 0
						for k,v in pairs(FriendlyTurns) do
							n=n+1
							keyset[n] = k
						end
						local unitchoice = math.random(#keyset)
						if(keyset[unitchoice] ~= nil) then
							local AttackRoll = math.random(20) + UnitsWiki2[EnemyTurns[i]][1] + (2 * EnemyWallsTier) + EnemyCastleTier
							local DefenseRoll = math.random(20) + UnitsWiki2[FriendlyTurns[keyset[unitchoice]]][2] + FriendlyCastleTier
							--print("Enemy " .. EnemyTurns[i] .. " VS Friendly " .. FriendlyTurns[keyset[unitchoice]])
							FightTranscript = FightTranscript .. "Enemy " .. EnemyTurns[i] .. " VS Friendly " .. FriendlyTurns[keyset[unitchoice]] .. "\n"
							if(AttackRoll > DefenseRoll) then
								--print("Enemy " .. EnemyTurns[i] .. " Killed Friendly " .. FriendlyTurns[keyset[unitchoice]])
								FightTranscript = FightTranscript .. "Enemy " .. EnemyTurns[i] .. " Killed Friendly " .. FriendlyTurns[keyset[unitchoice]] .. " (" .. AttackRoll .. "," .. DefenseRoll .. ")\n"
								FriendlyCasualities[FriendlyTurns[keyset[unitchoice]]] = FriendlyCasualities[FriendlyTurns[keyset[unitchoice]]] + 1
								table.remove(FriendlyTurns,keyset[unitchoice])
							else
								--print("Friendly " .. FriendlyTurns[keyset[unitchoice]] .. " Survived")
								FightTranscript = FightTranscript .. "Friendly " .. FriendlyTurns[keyset[unitchoice]] .. " Survived" .. " (" .. AttackRoll .. "," .. DefenseRoll .. ")\n"
							end
						else
							FriendlyHasNoTroops = true
						end
					end
				end
				
				local TotalFriendlyCasualties = FriendlyCasualities["archers"] + FriendlyCasualities["swordsmen"] + FriendlyCasualities["catapult"] + FriendlyCasualities["cavalry"]
				local AverageFriendlyArcherLoss = math.floor(FriendlyCasualities["archers"] / #FriendlyAllianceMemberIDs)
				local AverageFriendlySwordsmanLoss = math.floor(FriendlyCasualities["swordsmen"] / #FriendlyAllianceMemberIDs)
				local AverageFriendlyCasterLoss = math.floor(FriendlyCasualities["catapult"] / #FriendlyAllianceMemberIDs)
				local AverageFriendlyCavalryLoss = math.floor(FriendlyCasualities["cavalry"] / #FriendlyAllianceMemberIDs)

				local TotalEnemyTroopsCasualties = EnemyCasualities["archers"] + EnemyCasualities["swordsmen"] + EnemyCasualities["catapult"] + EnemyCasualities["cavalry"]
				local AverageEnemyArcherLoss = math.floor(EnemyCasualities["archers"] / #EnemyAllianceMemberIDs)
				local AverageEnemySwordsmanLoss = math.floor(EnemyCasualities["swordsmen"] / #EnemyAllianceMemberIDs)
				local AverageEnemyCasterLoss = math.floor(EnemyCasualities["catapult"] / #EnemyAllianceMemberIDs)
				local AverageEnemyCavalryLoss = math.floor(EnemyCasualities["cavalry"] / #EnemyAllianceMemberIDs)
				
				for i=1,#FriendlyAllianceMemberIDs do
					local sql = "select Troops from '" .. Guild .. "' Where ID='" .. FriendlyAllianceMemberIDs[i] .. "' LIMIT 1"
					local Rows,errorString = WorldDB:exec(sql)
					local Troops,TroopsData

					if errorString == 0 then
						print(errorString)
					else
						for k, v in pairs(Rows) do
							if(k == "Troops") then TroopsData = v[1] end
						end
					end

					Troops = GetTroops(TroopsData)
					local Archers = Troops["archers"] - AverageFriendlyArcherLoss
					if(Archers < 0 ) then Archers = 0 end

					local Swordsmen = Troops["swordsmen"] - AverageFriendlySwordsmanLoss
					if(Swordsmen < 0 ) then Swordsmen = 0 end

					local Casters = Troops["catapult"] - AverageFriendlyCasterLoss
					if(Casters < 0 ) then Casters = 0 end

					local Cavalry = Troops["cavalry"] - AverageFriendlyCavalryLoss
					if(Cavalry < 0 ) then Cavalry = 0 end

					local TroopsData = "{Archers: " .. Archers .. "|Swordsmen: " .. Swordsmen .. "|Catapult: " .. Casters .. "|Cavalry: " .. Cavalry .. "|}"
					sql = "UPDATE '" .. Guild .. "' SET Troops = '" .. TroopsData .. "' WHERE ID = " .. FriendlyAllianceMemberIDs[i] .. ";"
					WorldDB:exec(sql)
				end

				for i=1,#EnemyAllianceMemberIDs do
					local sql = "select Troops from '" .. Guild .. "' Where ID='" .. EnemyAllianceMemberIDs[i] .. "' LIMIT 1"
					local Rows,errorString = WorldDB:exec(sql)
					local Troops,TroopsData

					if errorString == 0 then
						print(errorString)
					else
						for k, v in pairs(Rows) do
							if(k == "Troops") then TroopsData = v[1] end
						end
					end

					Troops = GetTroops(TroopsData)
					local Archers = Troops["archers"] - AverageEnemyArcherLoss
					if(Archers < 0 ) then Archers = 0 end

					local Swordsmen = Troops["swordsmen"] - AverageEnemySwordsmanLoss
					if(Swordsmen < 0 ) then Swordsmen = 0 end

					local Casters = Troops["catapult"] - AverageEnemyCasterLoss
					if(Casters < 0 ) then Casters = 0 end

					local Cavalry = Troops["cavalry"] - AverageEnemyCavalryLoss
					if(Cavalry < 0 ) then Cavalry = 0 end

					local TroopsData = "{Archers: " .. Archers .. "|Swordsmen: " .. Swordsmen .. "|Catapult: " .. Casters .. "|Cavalry: " .. Cavalry .. "|}"
					sql = "UPDATE '" .. Guild .. "' SET Troops = '" .. TroopsData .. "' WHERE ID = " .. EnemyAllianceMemberIDs[i] .. ";"
					WorldDB:exec(sql)
				end


				--print(#FightTranscript)
                --[[
				for k,v in pairs(StringChunck(FightTranscript,#FightTranscript/35)) do
					message.channel:send("```" .. v .. "```")
				end
                ]]
				local winner = ""
				local ResultString = ""
				print(TotalFriendlyCasualties)
				print(FriendlyTroopsNumberAtBeginning)
				print(TotalEnemyTroopsCasualties)
				print(EnemyTroopsNumberAtBeginning)
				if((TotalFriendlyCasualties / FriendlyTroopsNumberAtBeginning + 0.3 < TotalEnemyTroopsCasualties / EnemyTroopsNumberAtBeginning) or EnemyHasNoTroops) then
					winner = FriendlyAllianceName

					sql = "select Coins from '" .. Guild .. "' Where ID='" .. Target.id .. "' LIMIT 1"
					--Get Coins in a table
					local Rows,errorString = MoneyDB:exec(sql)
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
						local coins =  math.floor(Prev * 3/4)
						--Calculate The Left Over Gold
						local Sum = tonumber(Prev) - coins
						
						sql = "select Coins from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
						--Get the Coins in a Table of the guy being Payed
						Rows,errorString = MoneyDB:exec(sql)
	
						for k, v in pairs(Rows) do
							if(k == "Coins") then
								New = v[1]
							end
						end
						--Check if The Guy Paying Can Afford it
						if Sum > 0 then
							sql = "UPDATE '" .. Guild .. "' SET Coins = " .. Sum .. " WHERE ID = " .. Target.id .. ";"
							--Update the Leftover Gold
							MoneyDB:exec(sql)
							Sum = New + coins
							sql = "UPDATE '" .. Guild .. "' SET Coins = " .. Sum .. " WHERE ID = " .. name .. ";"
							--Update Money for the Guy Being Payed
							MoneyDB:exec(sql)
							--Display the MSG
							ResultString = message.author.name .. " Looted " .. Target.mentionString .. " For " .. coins
						end
					end
				else
					winner = EnemyAllianceName
					ResultString = Target.mentionString .. "Defended Against " .. message.author.name
				end

				message.channel:send{embed = {
					title = "Siege Of " .. FriendlyAllianceName .. " On " .. EnemyAllianceName .. " Was Won By " .. winner,
					fields = {
						{name = "RESULT",value = ResultString,inline = false},
						{name = FriendlyAllianceName .. " Archer Casualties",value = FriendlyCasualities["archers"],inline = false},
						{name = FriendlyAllianceName .. " Swordsman Casualties",value = FriendlyCasualities["swordsmen"],inline = false},
						{name = FriendlyAllianceName .. " Catapult Casualties",value = FriendlyCasualities["catapult"],inline = false},
						{name = FriendlyAllianceName .. " Cavalry Casualties",value = FriendlyCasualities["cavalry"],inline = false},

						{name = EnemyAllianceName .. " Archer Casualties",value = EnemyCasualities["archers"],inline = false},
						{name = EnemyAllianceName .. " Swordsman Casualties",value = EnemyCasualities["swordsmen"],inline = false},
						{name = EnemyAllianceName .. " Catapult Casualties",value = EnemyCasualities["catapult"],inline = false},
						{name = EnemyAllianceName .. " Cavalry Casualties",value = EnemyCasualities["cavalry"],inline = false},
					},
					color = discordia.Color.fromRGB(114,137,218).value,
					timestamp = discordia.Date():toISO('T',"Z")
				}}
			else
				message.channel:send("You and the Enemy Both Must Have a Domain (get one by .getdomain)")
			end
		elseif(string.lower(string.sub(message.content,2,11)) == "changealliancename") then
			local NewName = string.sub(message.content,13,#message.content)


			local sql = "select Alliance from '" .. Guild .. "' Where ID='" .. name .. "' LIMIT 1"
			local Rows,errorString = BattleDB:exec(sql)
			local OldName

			if errorString == 0 then
				print("Error At Joining Alliance 4")
			else
				for k, v in pairs(Rows) do
					if(k == "Alliance") then
						OldName = v[1]
					end
				end
			end

			if(OldName ~= nil) then
				sql = "UPDATE '" .. Guild .. "' SET Alliance = '" .. NewName .. "' WHERE ID = '" .. name .. "';"
				BattleDB:exec(sql)
				message.channel:send("Changed The Name !")
			else
				message.channel:send("You Dont Lead An Alliance to change name of")
			end
		end
	end
end)

client:run('Bot ')