local SelectedIndex = 1
local Races = {"", "HUMAN", "DWARF", "NIGHTELF", "GNOME", "ORC", "UNDEAD", "TAUREN", "TROLL"}
local Classes = {"", "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"}

--[[local Classes = {
	"", 
	LOCALIZED_CLASS_NAMES_MALE["DRUID"],
	LOCALIZED_CLASS_NAMES_MALE["HUNTER"],
	LOCALIZED_CLASS_NAMES_MALE["MAGE"],
	LOCALIZED_CLASS_NAMES_MALE["PALADIN"],
	LOCALIZED_CLASS_NAMES_MALE["PRIEST"],
	LOCALIZED_CLASS_NAMES_MALE["ROGUE"],
	LOCALIZED_CLASS_NAMES_MALE["SHAMAN"],
	LOCALIZED_CLASS_NAMES_MALE["WARLOCK"],
	LOCALIZED_CLASS_NAMES_MALE["WARRIOR"],
	LOCALIZED_CLASS_NAMES_MALE["DEATHKNIGHT"]
}]]

-- Inserts all of the UI elements
function BlackList:InsertUI()

	-- Add the tab itself
	tinsert(FRIENDSFRAME_SUBFRAMES, "BlackListFrame")
	
	PanelTemplates_SetNumTabs(FriendsTabHeader, 3)
	PanelTemplates_UpdateTabs(FriendsTabHeader)

	-- Create name prompt
	StaticPopupDialogs["BL_PLAYER"] = {
		text = "Enter name of Player to add in Black List:",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnShow = function(self)
			self.editBox:SetText("")
		end,
		OnAccept = function(self)
			BlackList:AddPlayer(self.editBox:GetText())
		end,
		EditBoxOnEnterPressed = function(self)	
			BlackList:AddPlayer(self:GetParent().editBox:GetText())
			self:GetParent():Hide()
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		hasEditBox = true,
		maxLetters = 50,
		timeout = 0,
		exclusive = true,
		whileDead = true,
		hideOnEscape = true
	}
end

function BlackList:ClickBlackList(sel)
	index = sel:GetID()
	BlackList:SetSelectedBlackList(index)
	BlackList:UpdateUI()
 	BlackList:ShowDetails()
end

function BlackList:SetSelectedBlackList(index)
	SelectedIndex = index
end

function BlackList:GetSelectedBlackList()
	return SelectedIndex
end

function BlackList:ShowDetails()

	-- get player
	local player = BlackList:GetPlayerByIndex(BlackList:GetSelectedBlackList())

	-- update details
	_G["BlackListDetailsName"]:SetText("Black List Details of " .. player["name"])
	
	if (IsInGuild() == nil) then
		BlackListEditDetailsFrameShareButton:Disable()
	else
		BlackListEditDetailsFrameShareButton:Enable()
	end

	BlackListDetailsBlackListedText:SetText(date("%I:%M%p on %b %d, 20%y", player["added"]))
	BlackListDetailsFrameReasonTextBox:SetText(player["reason"])
	BlackListEditDetailsFrameLevel:SetText(player["level"])
	BlackListEditDetailsFrameRealm:SetText(player["realm"])
	BlackListEditDetailsFrameRace:SetText(player["race"])
	BlackListEditDetailsFrameClass:SetText(player["class"])
	BlackListDetailsFrame.hideOnEscape = true
	BlackListDetailsFrame:Show()
	
end

function BlackListEditDetailsSaveButton_OnClick()

	local index = BlackList:GetSelectedBlackList()
	local level = BlackListEditDetailsFrameLevel:GetText()
	local realm = BlackListEditDetailsFrameRealm:GetText()
	local class = BlackListEditDetailsFrameClass:GetText()
	local race = BlackListEditDetailsFrameRace:GetText()


	BlackList:UpdateDetails(index, realm, nil, level, class, race)
	BlackListDetailsFrame:Hide()
	BlackList:UpdateUI()
end

function BlackList:UpdateUI(setIndex)
	local numBlackLists = BlackList:GetNumBlackLists()
	local nameText, name, player, faction
	local blacklistButton
	local selectedBlackList = BlackList:GetSelectedBlackList()
	
	FauxScrollFrame_Update(FriendsFrameBlackListScrollFrame, numBlackLists, 19, 16)

	if (numBlackLists > 0) then
		if (selectedBlackList == 0 or selectedBlackList > numBlackLists) then
			BlackList:SetSelectedBlackList(1)
			selectedBlackList = 1
		end
		
		FriendsFrameRemovePlayerButton:Enable()
	else
		FriendsFrameRemovePlayerButton:Disable()
	end

	local blacklistOffset = FauxScrollFrame_GetOffset(FriendsFrameBlackListScrollFrame)
	local blacklistIndex
	
	for i=1, 19, 1 do
		blacklistIndex = i + blacklistOffset	
		
		player = BlackList:GetPlayerByIndex(blacklistIndex)
		if(player ~= nil) then
			faction = BlackList:GetFaction(player["race"])
			nameText = _G["FriendsFrameBlackListButton" .. i .. "TextName"]
			nameText:SetText(player["name"])
			
			realmText = _G["FriendsFrameBlackListButton" .. i .. "RealmName"]
			realmText:SetText("("..player["realm"]..")")
		end
		
		blacklistButton = _G["FriendsFrameBlackListButton" .. i]
		blacklistButton:SetID(blacklistIndex)
		
		if (faction ~= nil and faction > 0) then
			factionIcon = _G["FriendsFrameBlackListButton" .. i .. "FactionFrameInsignia"]
			if (faction == 1) then
				factionIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
				factionIcon:SetTexCoord(0, 0.5, 0, 1)
			else 
				factionIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
				factionIcon:SetTexCoord(0.5, 1, 0, 1)
			end
		end

		-- Update the highlight
		if (blacklistIndex == selectedBlackList) then
			blacklistButton:LockHighlight()
		else
			blacklistButton:UnlockHighlight()
		end

		if (blacklistIndex > numBlackLists) then
			blacklistButton:Hide()
		else
			blacklistButton:Show()
		end
	end
end
