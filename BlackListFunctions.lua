function BlackList:AddPlayer(player, realm, reason, level, class, race)
	local name, added
	
	if(string.find(player, "(.*)-(.*)") ~= nil) then
		 _, _, player, realm = string.find(player, "(.*)-(.*)")
	end

	if (player == nil or player == "") then
		return
	end
	
	if(realm == nil and (player == UnitName("player") or UnitName("target") == UnitName("player"))) then
				return
	end

	if (player == "target" or player == UnitName("target")) then
		if UnitIsPlayer("target") then
			name, realm = UnitName("target")
			level = tostring(UnitLevel("target"))
			_, class = UnitClass("target")
			_, race = UnitRace("target")
			
		else
			StaticPopup_Show("BL_PLAYER")
			return
		end
	else
		name = player
	end
	
	-- check double
	if (BlackList:GetIndexByName(name, realm) > 0) then
		BlackList:AddMessage(name .. " " .. "is already in Black List.", "yellow")
	else

		-- handle realm
		if (realm == nil) then
			realm = BlackList.realm
		end
		
		-- handle level
		if (level == nil) then
			level = ""
		end
		
		-- handle class
		if (class == nil) then
			class = ""
		end
		
		-- handle race
		if (race == nil) then
			race = ""
		end	
		
		-- handle race Scourge
		if (race == "Scourge") then
			race = "UNDEAD"
		end
	
		-- handle reason
		if (reason == nil) then
			reason = ""
		end
	
		-- timestamp
		added = time()
	
		-- lower the name and upper the first letter, not for chinese and korean though
		if ((GetLocale() ~= "zhTW") and (GetLocale() ~= "zhCN") and (GetLocale() ~= "koKR")) then
			local _, len = string.find(name, "[%z\1-\127\194-\244][\128-\191]*")
			name = string.upper(string.sub(name, 1, len)) .. string.lower(string.sub(name, len + 1))
		end
		
		player = {["name"] = name, ["realm"] = realm, ["level"] = level, ["class"] = class, ["race"] = race, ["added"] = added, ["reason"] = reason}
		table.insert(BlackListedPlayers, player)
		BlackList:sort()
		
		BlackList:HandleEvent("GROUP_ROSTER_UPDATE")
	
		BlackList:AddMessage(name .. " " .. "added to Black List.", "yellow")
	end

	PanelTemplates_Tab_OnClick(FriendsTabHeaderTab3, FriendsTabHeader)
	if(not BlackListOptionsFrame:IsVisible()) then
		FriendsFrame:Show()
	end
	
	BlackList:SetSelectedBlackList(BlackList:GetIndexByName(name))
	FriendsFrame_Update()
	BlackList:ShowDetails()
end

function BlackList:RemovePlayer()
	local index = BlackList:GetSelectedBlackList()

	if (index == 0) then
		BlackList:AddMessage("Player not found.", "yellow")
		return
	end

	local name = BlackListedPlayers[index]["name"]

	table.remove(BlackListedPlayers, index)

	BlackList:AddMessage(name .. " removed from Black List.", "yellow")

	BlackList:UpdateUI()
end

function BlackList:UpdateDetails(index, realm, reason, level, class, race)

	if(not realm) then 
		local realm = GetRealmName()
	end 
	
	-- update player
	local player = BlackList:GetPlayerByIndex(index)
	-- for old version i have to convert old name format (there was no format...) in new "Name" format
	if ((GetLocale() ~= "zhTW") and (GetLocale() ~= "zhCN") and (GetLocale() ~= "koKR")) then
		local _, len = string.find(player["name"], "[%z\1-\127\194-\244][\128-\191]*")
		player["name"] = string.upper(string.sub(player["name"], 1, len)) .. string.lower(string.sub(player["name"], len + 1))
	end
	
	if (realm ~= nil) then
		player["realm"] = realm
	else
		player["realm"] = BlackListedPlayers[index]["realm"]
	end		
		
	if (level ~= nil) then
		player["level"] = level
	else
		player["level"] = BlackListedPlayers[index]["level"]
	end
	
	if (class ~= nil) then
		player["class"] = class
	else
		player["class"] = BlackListedPlayers[index]["class"]
	end
	
	if (race ~= nil) then
		player["race"] = race
	else
		player["race"] = BlackListedPlayers[index]["race"]
	end

	if (reason ~= nil) then
		player["reason"] = reason
	else
		player["reason"] = BlackListedPlayers[index]["reason"]
	end

	tremove(BlackListedPlayers, index)
	tinsert(BlackListedPlayers, index, player)
end

function BlackList:GuildShare()
	local player = BlackList:GetPlayerByIndex(BlackList:GetSelectedBlackList())
	local shareString = format("%s,%s,%s,%s,%s,%s", player["name"], player["level"], player["class"], player["race"], player["reason"], player["realm"])
	C_ChatInfo.SendAddonMessage("BlackList", shareString, "GUILD")
	BlackList:AddMessage(format("BlackList Data of \"%s\" send to Guild.", player["name"]), "yellow")
	return
end

function BlackList:ShareAll()
	for i = 1, BlackList:GetNumBlackLists() do
--	local player = BlackList:GetPlayerByIndex(BlackList:GetSelectedBlackList())
	local player = BlackList:GetPlayerByIndex(i)
	local shareString = format("%s,%s,%s,%s,%s,%s", player["name"], player["level"], player["class"], player["race"], player["reason"], player["realm"])
	C_ChatInfo.SendAddonMessage("BlackList", shareString, "GUILD")
	BlackList:AddMessage(format("BlackList Data of \"%s\" send to Guild.", player["name"]), "yellow")
	end
	return
end

-- Returns the number of blacklisted players
function BlackList:GetNumBlackLists()
	if(BlackListedPlayers == nil) then 
		return 0 
	end
	
	return table.getn(BlackListedPlayers)
end

-- Returns the index of the player given by name (and realm)
function BlackList:GetIndexByName(name, realm)
	if (name == nil) then 
		return 0
	end
	
	if(BlackListedPlayers == nil) then 
		return 0 
	end	
	
	if (realm ~= nil and realm ~= "") then
		for i = 1, BlackList:GetNumBlackLists() do
			if (strlower(BlackListedPlayers[i]["name"]) == strlower(name) and strlower(BlackListedPlayers[i]["realm"]) == strlower(realm)) then
				return i
			end	
		end
	else
		for i = 1, BlackList:GetNumBlackLists() do
			if (strlower(BlackListedPlayers[i]["name"]) == strlower(name) and strlower(BlackListedPlayers[i]["realm"]) == strlower(BlackList.realm)) then	
				return i
			end
		end
	end

	return 0
end

function BlackList:GetPlayerByIndex(index)

	if (index ~= nil and index < 1 or index > BlackList:GetNumBlackLists()) then
		return nil
	end

	return BlackListedPlayers[index]
end

function BlackList:AddMessage(msg, color)

	if (not BlackListConfig.Chat) then return end

	local r, g, b = 0, 0, 0

	if (color == "red") then
		r = 1
	elseif (color == "yellow") then
		r, g = 1, 1
	elseif (color == "green") then
		g = 1
	end

	DEFAULT_CHAT_FRAME:AddMessage(msg, r, g, b)
end

function BlackList:AddErrorMessage(msg, color, timeout)
	if (not BlackListConfig.Center) then return end

	local r, g, b = 0, 0, 0

	if (color == "red") then
		r = 1
	elseif (color == "yellow") then
		r, g = 1, 1
	end

	UIErrorsFrame:AddMessage(msg, r, g, b, nil, timeout)
end

function BlackList:AddSound()
	if (not BlackListConfig.Sound) then return end
	PlaySound(SOUNDKIT.PVPTHROUGHQUEUE or 8459)
end

function BlackList:TooltipInfo(tooltip, unitid)
	if (BlackListConfig.Tooltip == true and unitid and UnitIsPlayer(unitid)) then
		local name, realm = UnitName(unitid)
		
		local player = BlackList:GetPlayerByIndex(BlackList:GetIndexByName(name, realm))
		local ttline

		if(player ~= nil) then
			local reason = player["reason"]
			if(reason ~= "") then
				if reason:len() > 30 then reason = reason:sub(1, 30) .. "..." end
				ttline = "Black List: |cFFFFFFFF"..reason
			else
				ttline = "on your Black List"
			end
		
			GameTooltip:AddLine(ttline, 1, 0, 0, 0)
			GameTooltip:Show()
			return
		end
	end
end

function BlackList:GetFaction(race)

	local faction = 0

	if (race == "Human" or race == "Dwarf" or race == "NightElf" or race == "Gnome") then
		faction = 1
	elseif (race == "Orc" or race == "Undead" or race == "Tauren" or race == "Troll") then
		faction = 2
	end

	return faction
end

function BlackList:Convert()

	local converted = {}

	-- each realm
	for rindex,rvalue in pairs(BlackListedPlayers) do
		-- each player on realm
		if(type(rindex) == "string" and rvalue ~= nil) then 
			for pindex,pvalue in pairs(BlackListedPlayers[rindex]) do 
				BlackListedPlayers[rindex][pindex]["realm"] = rindex
				BlackListedPlayers[rindex][pindex]["warn"] = nil
				table.insert(converted, BlackListedPlayers[rindex][pindex])
			end
		end
	end	
	
	BlackListedPlayers = {}
	BlackListedPlayers = converted
	BlackList:sort()
end

function BlackList:sort()
	table.sort(BlackListedPlayers, BlackList.comparator)
end

function BlackList.comparator(a, b)

	local strA = a["name"]
	local strB = b["name"]
	
	local lenA = strlen(strA)
	local lenB = strlen(strB)
	
	local length = 0
	if (lenA > lenB) then
		length = lenA
	else
		length = lenB
	end
	
	local byteA = 0
	local byteB = 0
	
	local returnValue = true
	for i=1,length do
		byteA = strbyte(strA, i)
		byteB = strbyte(strB, i)
		
		if (byteA == nil) then byteA = 0 end
		if (byteB == nil) then byteB = 0 end
		
		if (byteA < byteB) then
			returnValue = true
			break
			
		elseif (byteA > byteB) then
			returnValue = false
			break		
		end
	end
	return returnValue
end

function BlackList:ExportBlacklist()
    local exportFrame = CreateFrame("Frame", "BlackListExportFrame", UIParent, "BasicFrameTemplateWithInset")
    exportFrame:SetSize(500, 300)
    exportFrame:SetPoint("CENTER", 0, 200)
    exportFrame.title = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    exportFrame.title:SetPoint("CENTER", exportFrame.TitleBg, "CENTER", 0, 0)
    exportFrame.title:SetText("BlackList Export")
    exportFrame:SetMovable(true)
    exportFrame:EnableMouse(true)
    exportFrame:RegisterForDrag("LeftButton")
    exportFrame:SetScript("OnDragStart", exportFrame.StartMoving)
    exportFrame:SetScript("OnDragStop", exportFrame.StopMovingOrSizing)

    local scrollFrame = CreateFrame("ScrollFrame", "BlackListExportScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(430, 220)
    scrollFrame:SetPoint("TOP", exportFrame, "TOP", 0, -30)

    exportFrame.editBox = CreateFrame("EditBox", nil, scrollFrame)
    exportFrame.editBox:SetMultiLine(true)
    exportFrame.editBox:SetFontObject(ChatFontNormal)
    exportFrame.editBox:SetWidth(430)
    exportFrame.editBox:SetAutoFocus(true)
    exportFrame.editBox:SetText(BlackList:GenerateCSV())
	exportFrame.editBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

    scrollFrame:SetScrollChild(exportFrame.editBox)

    local copyButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    copyButton:SetSize(100, 25)
    copyButton:SetText("Highlight")
    copyButton:SetPoint("BOTTOMLEFT", exportFrame, "BOTTOMLEFT", 20, 20)
	copyButton:SetScript("OnClick", function() exportFrame.editBox:HighlightText() end)

    local closeButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 25)
    closeButton:SetText("Close")
    closeButton:SetPoint("BOTTOMRIGHT", exportFrame, "BOTTOMRIGHT", -20, 20)
    closeButton:SetScript("OnClick", function() exportFrame:Hide() end)

    exportFrame:Show()
end


-- Import function
function BlackList:ImportBlacklist(data)
	BlackList:AddMessage("***PLEASE MAKE SURE YOU'VE BACKED UP YOUR CURRENT BLACKLIST TO AVOID HAVING TO WIPE AND RESTART***", "red")
	BlackList:AddMessage("How to use:", "yellow")
	BlackList:AddMessage("Copy the text within a CSV formatted blacklist generated by this add-on by yourself or another user.", "yellow")
	BlackList:AddMessage("Paste into the Import window and hit Import.", "yellow")
    local importFrame = CreateFrame("Frame", "BlackListImportFrame", UIParent, "BasicFrameTemplateWithInset")
    importFrame:SetSize(500, 300)
    importFrame:SetPoint("CENTER", 0, 200)
    importFrame.title = importFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    importFrame.title:SetPoint("CENTER", importFrame.TitleBg, "CENTER", 0, 0)
    importFrame.title:SetText("BlackList Import")
	importFrame:SetMovable(true)
    importFrame:EnableMouse(true)
    importFrame:RegisterForDrag("LeftButton")
    importFrame:SetScript("OnDragStart", importFrame.StartMoving)
    importFrame:SetScript("OnDragStop", importFrame.StopMovingOrSizing)

    local scrollFrame = CreateFrame("ScrollFrame", "BlackListImportScrollFrame", importFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(430, 220)
    scrollFrame:SetPoint("TOP", importFrame, "TOP", 0, -30)

    importFrame.editBox = CreateFrame("EditBox", nil, scrollFrame)
    importFrame.editBox:SetMultiLine(true)
    importFrame.editBox:SetFontObject(ChatFontNormal)
    importFrame.editBox:SetWidth(430)
    importFrame.editBox:SetAutoFocus(true)
    importFrame.editBox:SetText(data or "") -- Set the default text if provided
	importFrame.editBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

    scrollFrame:SetScrollChild(importFrame.editBox)

    importFrame.importButton = CreateFrame("Button", nil, importFrame, "UIPanelButtonTemplate")
    importFrame.importButton:SetSize(100, 25)
    importFrame.importButton:SetText("Import")
    importFrame.importButton:SetPoint("BOTTOMLEFT", importFrame, "BOTTOMLEFT", 20, 20)
    importFrame.importButton:SetScript("OnClick", function() BlackList:ProcessImportData(importFrame.editBox:GetText()); importFrame:Hide() end)

    importFrame.closeButton = CreateFrame("Button", nil, importFrame, "UIPanelButtonTemplate")
    importFrame.closeButton:SetSize(100, 25)
    importFrame.closeButton:SetText("Close")
    importFrame.closeButton:SetPoint("BOTTOMRIGHT", importFrame, "BOTTOMRIGHT", -20, 20)
    importFrame.closeButton:SetScript("OnClick", function() importFrame:Hide() end)

    importFrame:Show()
end

function BlackList:ImportDetails(index, name, realm, reason, level, class, race)
    if not realm then 
        realm = GetRealmName()
    end 

    -- update player
    local player = BlackList:GetPlayerByIndex(index)

    -- for old version i have to convert old name format (there was no format...) in new "Name" format
    if ((GetLocale() ~= "zhTW") and (GetLocale() ~= "zhCN") and (GetLocale() ~= "koKR")) then
        local _, len = string.find(player["name"], "[%z\1-\127\194-\244][\128-\191]*")
        player["name"] = string.upper(string.sub(player["name"], 1, len)) .. string.lower(string.sub(player["name"], len + 1))
    end

    if realm then
        player["realm"] = realm
    else
        player["realm"] = BlackListedPlayers[index]["realm"]
    end        

    if level then
        player["level"] = level
    else
        player["level"] = BlackListedPlayers[index]["level"]
    end

    if class then
        player["class"] = class
    else
        player["class"] = BlackListedPlayers[index]["class"]
    end

    if race then
        player["race"] = race
    else
        player["race"] = BlackListedPlayers[index]["race"]
    end

    if reason and reason ~= "" then
        local existingReason = BlackListedPlayers[index]["reason"]
        -- Append the new reason to the existing reason if the imported reason is not blank and different
        if existingReason ~= reason then
            player["reason"] = existingReason .. " AND " .. reason
        else
            player["reason"] = existingReason
        end
    else
        player["reason"] = BlackListedPlayers[index]["reason"]
    end

    tremove(BlackListedPlayers, index)
    tinsert(BlackListedPlayers, index, player)
end

-- Process imported data and add players
function BlackList:ProcessImportData(importData)
    if not importData or importData == "" then
        BlackList:AddMessage("No data to import.", "yellow")
        return
    end

    local lines = {strsplit("\n", importData)}

    for _, line in ipairs(lines) do
        local fields = {strsplit(",", line)}
        local playerName = fields[1]
        local playerRealm = fields[6]
        local playerReason = fields[5]
        local playerLevel = fields[2]
        local playerClass = fields[3]
        local playerRace = fields[4]

        if playerName and playerRealm then
            -- Check for duplicates
            local index = BlackList:GetIndexByName(playerName, playerRealm)
            if index > 0 then
                -- Update Notes section if duplicate is found
                BlackList:ImportDetails(index, playerName, playerRealm, playerReason, playerLevel, playerClass, playerRace)
                BlackList:AddMessage(playerName .. " already in Black List, updated Notes section.", "yellow")
            else
                -- Add player if not a duplicate
                BlackList:AddPlayer(playerName, playerRealm, playerReason, playerLevel, playerClass, playerRace)
            end
        end
    end
end

-- Function to generate CSV from BlackList table
function BlackList:GenerateCSV()
    local csv = ""
    for _, player in ipairs(BlackListedPlayers) do
        local sanitizedReason = string.gsub(player.reason, ",", ".") -- Replace commas with periods
        csv = csv .. player.name .. "," .. player.level .. "," .. player.class .. "," .. player.race .. "," .. sanitizedReason .. "," .. player.realm .. "\n"
    end
    return csv
end

-- Add this function at the end of your code
function BlackList:DataNuke()
    -- Show confirmation dialog
    BlackList:DataNukeConfirmation()
end

-- StaticPopupDialogs block and additional functions should be at the same level as DataNuke function
StaticPopupDialogs["BLACKLIST_CONFIRM_NUKE"] = {
    text = "Are you sure you want to nuke all data? This action cannot be undone.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        BlackList:PerformDataNuke()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function BlackList:DataNukeConfirmation()
    StaticPopup_Show("BLACKLIST_CONFIRM_NUKE")
end

function BlackList:PerformDataNuke()
    local numPlayers = BlackList:GetNumBlackLists()

    for i = numPlayers, 1, -1 do
        BlackList:RemovePlayer(i)
    end

    BlackList:AddMessage("All data nuked. BlackList table is empty now.", "yellow")
end

-- Help Info
function BlackList:PrintHelpInfo()
	BlackList:AddMessage("************", "red")
	BlackList:AddMessage("Simple Blacklist for Classic", "red")
	BlackList:AddMessage("Available Commands:", "yellow")
	BlackList:AddMessage("/blhelp, /blacklisthelp - Shows this info.", "green")
	BlackList:AddMessage("/bl, /blacklist - Add a player to the blacklist. Adds the currently targetted player first, if no target then it will pop up and ask for a name. Can also do /bl *name* to add a name quick.", "green")
	BlackList:AddMessage("/blexport, /blacklistexport - Starts the exporting process.", "green")
	BlackList:AddMessage("/blimport, /blacklistimport - Starts the importing process. Please backup your list before you do this just to be safe.", "green")
	BlackList:AddMessage("/bldatanuke, /blacklistdatanuke - Starts the data nuke process, has a confirmation dialog but once it is done it is not reversable. Use only when you need a clean slate.", "red")
	BlackList:AddMessage("Add-on managed by EffinOwen, official discord server with community driven blacklists available at: https://discord.gg/9CMhszeJfu", "green")
	BlackList:AddMessage("************", "red")
end
