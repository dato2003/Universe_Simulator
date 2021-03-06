--MADE BY DAVID ZUROSHVILI (DARKNINJAD)
local sql = require("sqlite3")
local discordia = require("discordia")
local client = discordia.Client()

client:on("ready", function()
	-- client.user is the path for your bot
	print("Logged in as ".. client.user.username)
end)

local BattleDB = sql.open("BattleDB.db")
local WorldDB = sql.open("WorldDB.db")
local MoneyDB = sql.open("MoneyDB.db")

local sql = "PRAGMA journal_mode=WAL"
WorldDB:exec(sql)
MoneyDB:exec(sql)

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

function GetAllianceTroops(AllianceMemberIDs,GuildID,WorldDB)
	local AllianceTroops = {
		["archers"] = 0,
		["swordsmen"] = 0,
		["casters"] = 0,
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
		AllianceTroops["casters"] = AllianceTroops["casters"] + Troops["casters"]
		AllianceTroops["cavalry"] = AllianceTroops["cavalry"] + Troops["cavalry"]
	end

	return AllianceTroops
end

local UnitsWiki = {
	["archers"] = {2,1},
	["swordsmen"] = {3,2},
	["casters"] = {10,1},
	["cavalry"] = {5,3},
}

client:on("messageCreate", function(message)
	local name = message.author.id
	local Guild = message.channel.guild.id
	local AuthorMentionName = message.author.mentionString

	local sql = "CREATE TABLE IF NOT EXISTS '" .. Guild .. "' (ID TEXT,Alliance TEXT,Members TEXT)"
	BattleDB:exec(sql)

	if(name ~= "485447275586519062" and string.sub(message.content,1,1) == "|") then
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
				
				local AllianceTroops = GetAllianceTroops(AllianceMemberIDs,Guild,WorldDB)
				message.channel:send{embed = {
					title = AllianceName,
					fields = {
						{name = "Members of Your Alliance",value = Response,inline = false},
						{name = "Total Archers",value = AllianceTroops["archers"],inline = false},
						{name = "Total Swordsmen",value = AllianceTroops["swordsmen"],inline = false},
						{name = "Total Casters",value = AllianceTroops["casters"],inline = false},
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
			end

			if(TargetUser.id ~= name and message.channel.guild:getMember(TargetUser.id) ~= nil and DomainName ~= nil) then
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
		elseif(string.lower(string.sub(message.content,2,7)) == "attack" and message.mentionedUsers.first ~= nil) then
			print("Normal")
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


				local EnemyAllianceMembers,FriendlyAllianceMembers
				local EnemyAllianceMemberIDs,FriendlyAllianceMemberIDs

				local FriendlyAllianceTroops
				local EnemyAllianceTroops
				local AllTroops = {
					["archers"] = 0,
					["swordsmen"] = 0,
					["casters"] = 0,
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
					["casters"] = 0,
					["cavalry"] = 0
				}
				local EnemyCasualities = {
					["archers"] = 0,
					["swordsmen"] = 0,
					["casters"] = 0,
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

					EnemyAllianceTroops = GetAllianceTroops(EnemyAllianceMemberIDs,Guild,WorldDB)
				end
				if(FriendlyAllianceMembers ~= nil) then
					FriendlyAllianceMemberIDs = GetAllianceMembers(FriendlyAllianceMembers)

					for i=1,#FriendlyAllianceMemberIDs do
						local Member = message.channel.guild:getMember(FriendlyAllianceMemberIDs[i])
						if(Member == nil) then
							table.remove(FriendlyAllianceMemberIDs,i)
						end
					end

					FriendlyAllianceTroops = GetAllianceTroops(FriendlyAllianceMemberIDs,Guild,WorldDB)
				end
				if(EnemyAllianceMembers == nil) then
					EnemyAllianceMemberIDs = {Target.id}
					EnemyAllianceTroops = GetAllianceTroops({Target.id},Guild,WorldDB)
				end
				if(FriendlyAllianceMembers == nil) then
					FriendlyAllianceMemberIDs = {name}
					FriendlyAllianceTroops = GetAllianceTroops({name},Guild,WorldDB)
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
				AllTroops["casters"] = FriendlyAllianceTroops["casters"] + EnemyAllianceTroops["casters"]
				AllTroops["cavalry"] = FriendlyAllianceTroops["cavalry"] + EnemyAllianceTroops["cavalry"]

				TotalFriendlyTroopsNumber = FriendlyAllianceTroops["archers"] + FriendlyAllianceTroops["swordsmen"] + FriendlyAllianceTroops["casters"] + FriendlyAllianceTroops["cavalry"]
				TotalEnemyTroopsNumber = EnemyAllianceTroops["archers"] + EnemyAllianceTroops["swordsmen"] + EnemyAllianceTroops["casters"] + EnemyAllianceTroops["cavalry"]
				
				FriendlyTroopsNumberAtBeginning = TotalFriendlyTroopsNumber
				EnemyTroopsNumberAtBeginning = TotalEnemyTroopsNumber

				TotalTroopsNumber = AllTroops["archers"] + AllTroops["swordsmen"] + AllTroops["casters"] + AllTroops["cavalry"]

				if(FriendlyAllianceTroops["archers"] > 0) then
					FriendlyTemplate[1] = "archers"
				end
				if(FriendlyAllianceTroops["swordsmen"] > 0) then
					FriendlyTemplate[2] = "swordsmen"
				end
				if(FriendlyAllianceTroops["casters"] > 0) then
					FriendlyTemplate[3] = "casters"
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
				if(EnemyAllianceTroops["casters"] > 0) then
					EnemyTemplate[3] = "casters"
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
						local AttackRoll = math.random(20) + UnitsWiki[FriendlyTurns[i]][1] + (2 * FriendlyCastleTier)
						local DefenseRoll = math.random(20) + UnitsWiki[EnemyTurns[keyset[unitchoice]]][2] + (2 * EnemyCastleTier)
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
					
					elseif(EnemyTurns[i] ~= nil) then
						local keyset = {}
						local n = 0
						for k,v in pairs(FriendlyTurns) do
							n=n+1
							keyset[n] = k
						end
						local unitchoice = math.random(#keyset)

						local AttackRoll = math.random(20) + UnitsWiki[EnemyTurns[i]][1] + (2 * EnemyCastleTier)
						local DefenseRoll = math.random(20) + UnitsWiki[FriendlyTurns[keyset[unitchoice]]][2] + (2 * FriendlyCastleTier)
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
					end
				end
			
				local AverageFriendlyArcherLoss = FriendlyCasualities["archers"] / #FriendlyAllianceMemberIDs
				local AverageFriendlySwordsmanLoss = FriendlyCasualities["swordsmen"] / #FriendlyAllianceMemberIDs
				local AverageFriendlyCasterLoss = FriendlyCasualities["casters"] / #FriendlyAllianceMemberIDs
				local AverageFriendlyCavalryLoss = FriendlyCasualities["cavalry"] / #FriendlyAllianceMemberIDs

				local AverageEnemyArcherLoss = EnemyCasualities["archers"] / #EnemyAllianceMemberIDs
				local AverageEnemySwordsmanLoss = EnemyCasualities["swordsmen"] / #EnemyAllianceMemberIDs
				local AverageEnemyCasterLoss = EnemyCasualities["casters"] / #EnemyAllianceMemberIDs
				local AverageEnemyCavalryLoss = EnemyCasualities["cavalry"] / #EnemyAllianceMemberIDs
				
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

					local Casters = Troops["casters"] - AverageFriendlyCasterLoss
					if(Casters < 0 ) then Casters = 0 end

					local Cavalry = Troops["cavalry"] - AverageFriendlyCavalryLoss
					if(Cavalry < 0 ) then Cavalry = 0 end

					local TroopsData = "{Archers: " .. Archers .. "|Swordsmen: " .. Swordsmen .. "|Casters: " .. Casters .. "|Cavalry: " .. Cavalry .. "|}"
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

					local Casters = Troops["casters"] - AverageEnemyCasterLoss
					if(Casters < 0 ) then Casters = 0 end

					local Cavalry = Troops["cavalry"] - AverageEnemyCavalryLoss
					if(Cavalry < 0 ) then Cavalry = 0 end

					local TroopsData = "{Archers: " .. Archers .. "|Swordsmen: " .. Swordsmen .. "|Casters: " .. Casters .. "|Cavalry: " .. Cavalry .. "|}"
					sql = "UPDATE '" .. Guild .. "' SET Troops = '" .. TroopsData .. "' WHERE ID = " .. EnemyAllianceMemberIDs[i] .. ";"
					WorldDB:exec(sql)
				end


				--print(#FightTranscript)

				for k,v in pairs(StringChunck(FightTranscript,#FightTranscript/35)) do
					message.channel:send("```" .. v .. "```")
				end

				message.channel:send{embed = {
					title = "Battle Between " .. FriendlyAllianceName .. " And " .. EnemyAllianceName,
					fields = {
						--{name = "BATTLE",value = FightTranscript,inline = false},
						{name = FriendlyAllianceName .. " Archer Casualties",value = FriendlyCasualities["archers"],inline = false},
						{name = FriendlyAllianceName .. " Swordsman Casualties",value = FriendlyCasualities["swordsmen"],inline = false},
						{name = FriendlyAllianceName .. " Caster Casualties",value = FriendlyCasualities["casters"],inline = false},
						{name = FriendlyAllianceName .. " Cavalry Casualties",value = FriendlyCasualities["cavalry"],inline = false},

						{name = EnemyAllianceName .. " Archer Casualties",value = EnemyCasualities["archers"],inline = false},
						{name = EnemyAllianceName .. " Swordsman Casualties",value = EnemyCasualities["swordsmen"],inline = false},
						{name = EnemyAllianceName .. " Caster Casualties",value = EnemyCasualities["casters"],inline = false},
						{name = EnemyAllianceName .. " Cavalry Casualties",value = EnemyCasualities["cavalry"],inline = false},
					},
					color = discordia.Color.fromRGB(114,137,218).value,
					timestamp = discordia.Date():toISO('T',"Z")
				}}
			else
				message.channel:send("You and the Enemy Both Must Have a Domain (get one by .getdomain)")
			end
		elseif(string.lower(string.sub(message.content,2,13)) == "domainattack" and message.mentionedUsers.first ~= nil) then
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
					["casters"] = 0,
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
					["casters"] = 0,
					["cavalry"] = 0
				}
				local EnemyCasualities = {
					["archers"] = 0,
					["swordsmen"] = 0,
					["casters"] = 0,
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
				AllTroops["casters"] = FriendlyAllianceTroops["casters"] + EnemyAllianceTroops["casters"]
				AllTroops["cavalry"] = FriendlyAllianceTroops["cavalry"] + EnemyAllianceTroops["cavalry"]

				TotalFriendlyTroopsNumber = FriendlyAllianceTroops["archers"] + FriendlyAllianceTroops["swordsmen"] + FriendlyAllianceTroops["casters"] + FriendlyAllianceTroops["cavalry"]
				TotalEnemyTroopsNumber = EnemyAllianceTroops["archers"] + EnemyAllianceTroops["swordsmen"] + EnemyAllianceTroops["casters"] + EnemyAllianceTroops["cavalry"]
				FriendlyTroopsNumberAtBeginning = TotalFriendlyTroopsNumber
				EnemyTroopsNumberAtBeginning = TotalEnemyTroopsNumber

				TotalTroopsNumber = AllTroops["archers"] + AllTroops["swordsmen"] + AllTroops["casters"] + AllTroops["cavalry"]

				if(FriendlyAllianceTroops["archers"] > 0) then
					FriendlyTemplate[1] = "archers"
				end
				if(FriendlyAllianceTroops["swordsmen"] > 0) then
					FriendlyTemplate[2] = "swordsmen"
				end
				if(FriendlyAllianceTroops["casters"] > 0) then
					FriendlyTemplate[3] = "casters"
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
				if(EnemyAllianceTroops["casters"] > 0) then
					EnemyTemplate[3] = "casters"
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

						local AttackRoll = math.random(20) + UnitsWiki[FriendlyTurns[i]][1] + (2 * FriendlyCastleTier)
						local DefenseRoll = math.random(20) + UnitsWiki[EnemyTurns[keyset[unitchoice]]][2] + (2 * EnemyWallsTier) + (2 * EnemyCastleTier)
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
					
					elseif(EnemyTurns[i] ~= nil) then
						local keyset = {}
						local n = 0
						for k,v in pairs(FriendlyTurns) do
							n=n+1
							keyset[n] = k
						end
						local unitchoice = math.random(#keyset)

						local AttackRoll = math.random(20) + UnitsWiki[EnemyTurns[i]][1] + (2 * EnemyWallsTier) + (2 * EnemyCastleTier)
						local DefenseRoll = math.random(20) + UnitsWiki[FriendlyTurns[keyset[unitchoice]]][2] + (2 * FriendlyCastleTier)
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
					end
				end
				
				local TotalFriendlyCasualties = FriendlyCasualities["archers"] + FriendlyCasualities["swordsmen"] + FriendlyCasualities["casters"] + FriendlyCasualities["cavalry"]
				local AverageFriendlyArcherLoss = FriendlyCasualities["archers"] / #FriendlyAllianceMemberIDs
				local AverageFriendlySwordsmanLoss = FriendlyCasualities["swordsmen"] / #FriendlyAllianceMemberIDs
				local AverageFriendlyCasterLoss = FriendlyCasualities["casters"] / #FriendlyAllianceMemberIDs
				local AverageFriendlyCavalryLoss = FriendlyCasualities["cavalry"] / #FriendlyAllianceMemberIDs

				local TotalEnemyTroopsCasualties = EnemyCasualities["archers"] + EnemyCasualities["swordsmen"] + EnemyCasualities["casters"] + EnemyCasualities["cavalry"]
				local AverageEnemyArcherLoss = EnemyCasualities["archers"] / #EnemyAllianceMemberIDs
				local AverageEnemySwordsmanLoss = EnemyCasualities["swordsmen"] / #EnemyAllianceMemberIDs
				local AverageEnemyCasterLoss = EnemyCasualities["casters"] / #EnemyAllianceMemberIDs
				local AverageEnemyCavalryLoss = EnemyCasualities["cavalry"] / #EnemyAllianceMemberIDs
				
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

					local Casters = Troops["casters"] - AverageFriendlyCasterLoss
					if(Casters < 0 ) then Casters = 0 end

					local Cavalry = Troops["cavalry"] - AverageFriendlyCavalryLoss
					if(Cavalry < 0 ) then Cavalry = 0 end

					local TroopsData = "{Archers: " .. Archers .. "|Swordsmen: " .. Swordsmen .. "|Casters: " .. Casters .. "|Cavalry: " .. Cavalry .. "|}"
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

					local Casters = Troops["casters"] - AverageEnemyCasterLoss
					if(Casters < 0 ) then Casters = 0 end

					local Cavalry = Troops["cavalry"] - AverageEnemyCavalryLoss
					if(Cavalry < 0 ) then Cavalry = 0 end

					local TroopsData = "{Archers: " .. Archers .. "|Swordsmen: " .. Swordsmen .. "|Casters: " .. Casters .. "|Cavalry: " .. Cavalry .. "|}"
					sql = "UPDATE '" .. Guild .. "' SET Troops = '" .. TroopsData .. "' WHERE ID = " .. EnemyAllianceMemberIDs[i] .. ";"
					WorldDB:exec(sql)
				end


				--print(#FightTranscript)

				for k,v in pairs(StringChunck(FightTranscript,#FightTranscript/35)) do
					message.channel:send("```" .. v .. "```")
				end

				local winner = ""
				local ResultString = ""
				
				if(TotalFriendlyCasualties / FriendlyTroopsNumberAtBeginning < TotalEnemyTroopsCasualties / EnemyTroopsNumberAtBeginning) then
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
						local coins =  Prev * 3/4
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
						{name = FriendlyAllianceName .. " Caster Casualties",value = FriendlyCasualities["casters"],inline = false},
						{name = FriendlyAllianceName .. " Cavalry Casualties",value = FriendlyCasualities["cavalry"],inline = false},

						{name = EnemyAllianceName .. " Archer Casualties",value = EnemyCasualities["archers"],inline = false},
						{name = EnemyAllianceName .. " Swordsman Casualties",value = EnemyCasualities["swordsmen"],inline = false},
						{name = EnemyAllianceName .. " Caster Casualties",value = EnemyCasualities["casters"],inline = false},
						{name = EnemyAllianceName .. " Cavalry Casualties",value = EnemyCasualities["cavalry"],inline = false},
					},
					color = discordia.Color.fromRGB(114,137,218).value,
					timestamp = discordia.Date():toISO('T',"Z")
				}}
			else
				message.channel:send("You and the Enemy Both Must Have a Domain (get one by .getdomain)")
			end
		elseif(string.lower(string.sub(message.content,2,11)) == "changename") then
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


client:run("Bot ")