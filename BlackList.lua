BlackList = {}
BlackListedPlayers = {}
BlackListOptions = {}

BlackList.realm = GetRealmName()

--BlackList.debug = true

local BL_Blocked_Channels = {"SAY", "YELL", "WHISPER", "WHISPER_INFORM", "PARTY", "RAID", "RAID_WARNING", "EMOTE", "TEXT_EMOTE", "CHANNEL", "CHANNEL_JOIN", "CHANNEL_LEAVE"}

local Already_Warned_For = {}
Already_Warned_For["WHISPER"] = {}
Already_Warned_For["TARGET"] = {}
Already_Warned_For["PARTY_INVITE"] = {}
Already_Warned_For["PARTY"] = {}
Already_Warned_For["MOUSEOVER"] = {}
Already_Warned_For["GUILD_ROSTER"] = {}

local Orig_FriendsFrame_Update
local Orig_ChatFrame_MessageEventHandler

local BL_Default = {
	Sound = true,
	Center = true,
	Chat = true,
	Tooltip = true,
	MItem = true,
}

-- Function to handle onload event
function BlackList:OnLoad()

	C_ChatInfo.RegisterAddonMessagePrefix("BlackList")
	if (not BlackListConfig) then BlackListConfig = BL_Default end
	if BlackListConfig.Sound == nil or "" then BlackListConfig.Sound = true end
	if BlackListConfig.Center == nil or "" then BlackListConfig.Center = true end
	if BlackListConfig.Chat == nil or "" then BlackListConfig.Chat = true end
	if BlackListConfig.Tooltip == nil or "" then BlackListConfig.Tooltip = true end

	-- constructions
	BlackList:RegisterEvents()
	BlackList:HookFunctions()
	BlackList:RegisterSlashCmds()


	return
end

-- Registers events to be recieved
function BlackList:RegisterEvents()

	local frame = _G["BlackListTopFrame"]

	-- register events
	frame:RegisterEvent("VARIABLES_LOADED")
	frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	frame:RegisterEvent("PARTY_INVITE_REQUEST")
	frame:RegisterEvent("GROUP_ROSTER_UPDATE")
	frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	frame:RegisterEvent("WHO_LIST_UPDATE")
	frame:RegisterEvent("CHAT_MSG_SYSTEM")
	frame:RegisterEvent("CHAT_MSG_ADDON")
	frame:RegisterEvent("GUILD_ROSTER_UPDATE")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("CHAT_MSG_WHISPER")

	return
end

local function blackListButton(self)
if self.value == "BlacklistButton" then
--	 print("RedButton clicked")
	local dropdownMenu = _G["UIDROPDOWNMENU_INIT_MENU"]
		if(dropdownMenu.name ~= UnitName("player")) then
			BlackList:AddPlayer(dropdownMenu.name)
 		end
	 else
	 print(" WTF how did I fail?")
	end
   end

   hooksecurefunc("UnitPopup_ShowMenu", function()
	if (UIDROPDOWNMENU_MENU_LEVEL > 1) then
	 return
	end
	local info = UIDropDownMenu_CreateInfo()
	info.text = "Add to BlackList"
	info.owner = which
	info.notCheckable = 1
	info.func = blackListButton
	 info.colorCode = "|cffff0000"
	 info.value = "BlacklistButton"
--target = GetUnitName("target", true)
--player = GetUnitName("player", true)
--if target ~= player then
	UIDropDownMenu_AddButton(info)
--end
--end
   end)


-- Hooks onto the functions needed
function BlackList:HookFunctions()
	GameTooltip:HookScript("OnTooltipSetUnit",
	function(self)
		local name, unitid = self:GetUnit()
		if (not unitid) then
			unitid = "mouseover"
		end
		BlackList:TooltipInfo(self, unitid)
	end)
end

hooksecurefunc("FriendsFrame_Update", function(self)
   if (FriendsFrame.selectedTab == 1 and FriendsTabHeader.selectedTab == 3) then
      FriendsTabHeader:Show()
      FriendsFrameTitleText:SetText("Black List")
      FriendsFrame_ShowSubFrame("BlackListFrame")
      BlackList:UpdateUI()
   end
end)

-- Registers slash cmds
function BlackList:RegisterSlashCmds()
	SlashCmdList["BlackList"]   = function(args) BlackList:HandleSlashCmd(1, args) end
	SLASH_BlackList1 = "/blacklist"
	SLASH_BlackList2 = "/bl"
end

-- Handles the slash cmds
function BlackList:HandleSlashCmd(type, args)
	if (type == 1) then
		if (args == "") then
			BlackList:AddPlayer("target")
		else
			BlackList:AddPlayer(args)
		end
	end
end

function split(inputstr, sep) 
	local t={} 
	for field,s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do 
		table.insert(t,field) 
		if s=="" then 
			return t 
		end 
	end 
end

--[[function split(s, delimiter)
	result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match);
	end
	return result;
end]]

-- Function to handle events
function BlackList:HandleEvent(self, event, ...)

	local arg1 = ...

	if (event == "VARIABLES_LOADED") then

		if (BlackListedPlayers[BlackList.realm]) then
			BlackList:Convert()
			return
		end

		if (not BlackListedPlayers) then
			BlackListedPlayers = {}
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		BlackList:InsertUI()
	elseif (event == "CHAT_MSG_ADDON") then
		local prefix, message, distType, sender = ...
		local pname = split(sender,"-")
--		print(message)

		if(prefix ~= "BlackList" or pname[1] == UnitName("player") or message == nil) then
--		if(prefix ~= "BlackList" or message == nil) then
			return
		end

	local t = split(message,",")
	player = t[1]
--	print(player)
	level = t[2]
--	print(level)
	class = t[3]
--	print(class)
	race = t[4]
--	print(race)
	reason = t[5]
--	print(reason)
	realm = t[6]
--	print(realm)
		if (BlackList:GetIndexByName(player, realm) == 0) then
			BlackList:AddPlayer(player, realm, reason, level, class, race)
			BlackList:AddMessage(format("Blacklist Data of \"%s\" received from %s.", player, sender), "yellow")
		end
	elseif (event == "PLAYER_TARGET_CHANGED") then
		-- search for player name
		if (not UnitIsPlayer("target")) then
			return
		end

		local name, realm = UnitName("target")
		if (BlackList:GetIndexByName(name) > 0) then
			local player = BlackList:GetPlayerByIndex(BlackList:GetIndexByName(name, realm))

			-- warn player
			local alreadywarned = false
			for warnedname, timepassed in pairs(Already_Warned_For["TARGET"]) do
				if ((name == warnedname) and (GetTime() < timepassed+10)) then
					alreadywarned = true
				end
			end

			if (not alreadywarned) then
				Already_Warned_For["TARGET"][name]=GetTime()
				BlackList:AddSound()
				BlackList:AddErrorMessage(name .. " is on your Black List (targeted)", "red", 5)
				BlackList:AddMessage(name .. " is on your Black List for reason: " .. player["reason"], "yellow")
			end
		end
	elseif (event == "UPDATE_MOUSEOVER_UNIT") then
		-- search for player name
		local name, realm = UnitName("mouseover")
		local index = BlackList:GetIndexByName(name, realm)
		if (index > 0) then
			local player = BlackList:GetPlayerByIndex(index)

			-- warn player
			local alreadywarned = false
			for warnedname, timepassed in pairs(Already_Warned_For["TARGET"]) do
				if ((name == warnedname) and (GetTime() < timepassed+10)) then
					alreadywarned = true
				end
			end

			if (not alreadywarned) then
				Already_Warned_For["TARGET"][name]=GetTime()
				BlackList:AddSound()
				BlackList:AddErrorMessage(name .. " is on your Black List (mouseover)", "red", 5)
				if(player["reason"] ~= "") then
					BlackList:AddMessage(name .. " is on your Black List for reason: " .. player["reason"], "red")
				else
					BlackList:AddMessage(name .. " is on your Black List.", "red")
				end
				-- also update character info
				local _, class = UnitClass("mouseover")
				local _, race = UnitRace("mouseover")
				BlackList:UpdateDetails(index, nil, nil, UnitLevel("mouseover"), class, race)
			end
		end
	elseif (event == "PARTY_INVITE_REQUEST") then
		-- search for player name
		local name = arg1
		local index = BlackList:GetIndexByName(name)
		if (index > 0) then
			local player = BlackList:GetPlayerByIndex(index)

			local alreadywarned = false
			for warnedname, timepassed in pairs(Already_Warned_For["TARGET"]) do
				if ((name == warnedname) and (GetTime() < timepassed+10))  then
					alreadywarned = true
				end
			end
			if (not alreadywarned) then
				Already_Warned_For["TARGET"][name]=GetTime()+300
				BlackList:AddSound()
				BlackList:AddErrorMessage(name .. " is on your Black List (invited to party).", "red", 10)
			end
		end
	elseif (event == "GROUP_ROSTER_UPDATE") then
		for i = 0, GetNumSubgroupMembers() do
			-- search for player name
			local name, realm = UnitName("party" .. i)
			local index = BlackList:GetIndexByName(name, realm)
			if (index > 0) then
				local player = BlackList:GetPlayerByIndex(index)

				local alreadywarned = false
				for warnedname, timepassed in pairs(Already_Warned_For["TARGET"]) do
					if ((name == warnedname) and (GetTime() < timepassed+10))  then
						alreadywarned = true
					end
				end
				if (not alreadywarned) then
					Already_Warned_For["TARGET"][name]=GetTime()+300
					BlackList:AddSound()
					BlackList:AddMessage(name .. " is on your Black List (in your party)", "red")
					if player["reason"] ~= "" then
						BlackList:AddMessage("for: " .. player["reason"], "red")
					end
				end
			end
		end
	elseif (event == "WHO_LIST_UPDATE") then
		local numWhos = C_FriendList.GetNumWhoResults()
		for i = 1, numWhos do
		  local info = C_FriendList.GetWhoInfo(i)
		  local whoname = info.fullName
		  
			if (BlackList:GetIndexByName(whoname) > 0) then
				BlackList:AddMessage(whoname .. " is on your Black List (from your who search).", "red")
			end
		end
	elseif (event == "GUILD_ROSTER_UPDATE" and IsInGuild() ~= nil) then
		local bootNum = 0
		for i = 1, GetNumGuildMembers() do
			local name, rank, rankIndex, level, classLocale, zone, note, officernote, online, status, class = GetGuildRosterInfo(i)

			-- check for blacklist
			local index = BlackList:GetIndexByName(name)
			if (index > 0) then
				local player = BlackList:GetPlayerByIndex(index)

				local alreadywarned = false
				for warnedname, timepassed in pairs(Already_Warned_For["GUILD_ROSTER"]) do
					if ((name == warnedname) and (GetTime() < timepassed+10)) then
						alreadywarned = true
					end
				end
				if (not alreadywarned) then
					Already_Warned_For["GUILD_ROSTER"][name]=GetTime()+300
					BlackList:AddSound()
					BlackList:UpdateDetails(index, nil, nil, level, class, nil)
					BlackList:AddErrorMessage(name .. " is on your Black List and is in your GUILD.", "red", 5)
                    if(player["reason"] ~= "") then
						BlackList:AddMessage(name .. " is on your Black List and is in your GUILD, reason:" .. player["reason"], "red")
				    else
						BlackList:AddMessage(name .. " is on your Black List and in your GUILD", "red")
					end

					-- auto kick from guild
					if (CanGuildRemove() and BlackList:GetIndexByName(name) > 0) then
						GuildUninvite(name)
						if player["reason"] ~= "" then
							local bannedmsg = name .. " has been removed from the Guild for: " .. player["reason"] .. ". Do not reinvite!"
						else
							local bannedmsg = name .. " has been banned from the Guild. Do not reinvite!"
						end
						SendChatMessage(bannedmsg, "GUILD", nil, index)
					end
				end
			end
		end
	elseif (event == "CHAT_MSG_SYSTEM" and arg1 ~= nil) then
		local whoname = string.match(arg1, "(%a+)", 10)
		if (BlackList:GetIndexByName(whoname) > 0) then
			BlackList:AddMessage(whoname .. " is on your Black List", "red")
		end
	elseif (event == "CHAT_MSG_WHISPER") then
		name, realm = select(6, GetPlayerInfoByGUID(select(12, ...)))
		if BlackList:GetIndexByName(name, realm) == 0 then
			return
		end
		local alreadywarned = false
		for key, warnedname in pairs(Already_Warned_For["WHISPER"]) do
			if (name == warnedname) then
				alreadywarned = true
			end
		end
		if (not alreadywarned) then
			tinsert(Already_Warned_For["WHISPER"], name)
			BlackList:AddMessage(name .. " is on your blacklist", "red")
		end
	end
end
