--MADE BY DAVID ZUROSHVILI (DARKNINJAD)
local discordia = require('discordia')
local sql = require("sqlite3")
local timer = require("timer")
local client = discordia.Client()

client:on('ready', function()
	-- client.user is the path for your bot
	print('Logged in as '.. client.user.username)
end)

local MoneyDB = sql.open("MoneyDB.db")
local WorldDB = sql.open("WorldDB.db")

local sql = "PRAGMA journal_mode=WAL"
WorldDB:exec(sql)
MoneyDB:exec(sql)

function GetTroops(TroopsData)
	local Template = {"archers","swordsmen","casters","cavalry"}
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
	["casters"] = {2,50},
	["cavalry"] = {10,40},
}

local CooldownTable = {}

function Cooldown(name,guild)
	CooldownTable[guild][name] = false
end

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
			local Troops = "{Archers: 0|Swordsmen: 0|Casters: 0|Cavalry: 0|}"
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

                	if(tonumber(Money) >= 200) then
                    	WorldDB:exec("insert into '" .. Guild .. "' (ID,Domain,Walls,Castle,Tavern,Training_Ground,Troops) values('" .. name .. "','" .. Domain .."',0,0,0,0,'" .. Troops .."');")
						message.channel:send("You Pleased Me. Here Have This Land")
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
				message.channel:send("Buy Piece Of Land For 200 Gold.(.getdomain)")
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
						message.channel:send("You Have Upgraded " .. Target)
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
						message.channel:send("You Have Upgraded " .. Target)
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
						message.channel:send("You Have Upgraded " .. Target)
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
						message.channel:send("You Have Upgraded " .. Target)
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
				message.channel:send("Buy Piece Of Land For 200 Gold.(.getdomain)")
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
				Capacity = Tier * 30
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
						local TroopsData = "{Archers: " .. Troops["archers"] .. "|Swordsmen: " .. Troops["swordsmen"] .. "|Casters: " .. Troops["casters"] .. "|Cavalry: " .. Troops["cavalry"] .. "|}"
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
				message.channel:send("Buy Piece Of Land For 200 Gold.(.getdomain)")
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
				Capacity = Tier * 30

				message.channel:send{embed = {
					title = "Army of " .. message.author.name,
					fields = {
						{name = "Capacity",value = Capacity,inline = false},
						{name = "Archers",value = Troops["archers"],inline = false},
						{name = "Swordsmen",value = Troops["swordsmen"],inline = false},
						{name = "Casters",value = Troops["casters"],inline = false},
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
				print("Gold Entry Does not exist in the MoneyDB")
			else
				for k, v in pairs(Rows) do
					if(k == "Tavern") then
						TavernTier = v[1]
					end
				end
			end
			if(CooldownTable[Guild] == nil or CooldownTable[Guild][name] == nil or CooldownTable[Guild][name] == false) then
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

					local NewCoins = PrevCoins + TavernTier * 30
					sql = "UPDATE '" .. Guild .. "' SET Coins = " .. NewCoins .. " WHERE ID = " .. name .. ";"
					MoneyDB:exec(sql)

					if(CooldownTable[Guild] == nil) then
						CooldownTable[Guild] = {}
						CooldownTable[Guild][name] = true
					else
						CooldownTable[Guild][name] = true
 					end

					timer.setTimeout(21600000,Cooldown,name,Guild)
					message.channel:send("You Collected " .. TavernTier * 30 .. " Coins in Taxes")
				else
					message.channel:send("You Don't Have A Tavern")
				end
			else
				message.channel:send("You Already Collected Taxes for now")
			end
		end
	end
end)

client:run('Bot ')