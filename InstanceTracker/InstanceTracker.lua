-- 1. Database creation and config
local charKey = UnitName("player") .. "-" .. GetRealmName()

local function InitializeDB()
    if not InstanceTrackerDB then InstanceTrackerDB = {} end
    if not InstanceTrackerGlobalDB then InstanceTrackerGlobalDB = {} end
    if not InstanceTrackerGlobalDB[charKey] then InstanceTrackerGlobalDB[charKey] = {} end
    if not InstanceTrackerPos then InstanceTrackerPos = { "CENTER", nil, "CENTER", 0, 0 } end
end

-- 2. Principal frame
local ui = CreateFrame("Frame", "InstanceTrackerFrame", UIParent, "BackdropTemplate")
ui:SetSize(220, 60)
ui:SetMovable(true)
ui:EnableMouse(true)
ui:RegisterForDrag("LeftButton")
ui:SetScript("OnDragStart", ui.StartMoving)
ui:SetScript("OnDragStop", ui.StopMovingOrSizing)
ui:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
ui:SetBackdropColor(0, 0, 0, 0.8)

local nameText = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
nameText:SetPoint("LEFT", 10, 5)
nameText:SetText("Ninguna")

local runText = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
runText:SetPoint("RIGHT", -25, 5)

local speedText = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
speedText:SetPoint("BOTTOM", 0, 8)

local closeBtn = CreateFrame("Button", nil, ui, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", 2, 2)
closeBtn:SetSize(24, 24)
closeBtn:SetScript("OnClick", function() ui:Hide() end)

-- 3. History
local statsFrame = CreateFrame("Frame", "IT_StatsFrame", UIParent, "BackdropTemplate")
statsFrame:SetSize(400, 300)
statsFrame:SetPoint("CENTER")
statsFrame:Hide()
statsFrame:SetMovable(true)
statsFrame:EnableMouse(true)
statsFrame:RegisterForDrag("LeftButton")
statsFrame:SetScript("OnDragStart", statsFrame.StartMoving)
statsFrame:SetScript("OnDragStop", statsFrame.StopMovingOrSizing)
statsFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
statsFrame:SetBackdropColor(0, 0, 0, 0.9)

local statsContent = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
statsContent:SetPoint("TOPLEFT", 20, -40)
statsContent:SetJustifyH("LEFT")

local function RefreshStats()
    local text = "|cFFFFFF00Characters|r\n\n"
    for char, instances in pairs(InstanceTrackerGlobalDB) do
        text = text .. "|cFF00FF00[" .. char .. "]|r\n"
        for name, count in pairs(instances) do
            text = text .. "  - " .. name .. ": " .. count .. " runs\n"
        end
        text = text .. "\n"
    end
    statsContent:SetText(text)
end

local closeStats = CreateFrame("Button", nil, statsFrame, "UIPanelCloseButton")
closeStats:SetPoint("TOPRIGHT", 0, 0)

-- 4. BOTÓN DEL MINIMAPA
local minimapBtn = CreateFrame("Button", "IT_MinimapButton", Minimap)
minimapBtn:SetSize(31, 31)
minimapBtn:SetFrameLevel(8)
minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimapBtn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -5, -5)

local btnIcon = minimapBtn:CreateTexture(nil, "BACKGROUND")
btnIcon:SetTexture("Interface\\Icons\\Inv_misc_pocketwatch_01")
btnIcon:SetSize(20, 20)
btnIcon:SetPoint("CENTER", 0, 0)

local btnBorder = minimapBtn:CreateTexture(nil, "OVERLAY")
btnBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
btnBorder:SetSize(52, 52)
btnBorder:SetPoint("TOPLEFT", 0, 0)

minimapBtn:SetScript("OnClick", function()
    if statsFrame:IsShown() then
        statsFrame:Hide()
    else
        RefreshStats(); statsFrame:Show()
    end
end)

-- 5. Logic
local function UpdateDisplay()
    if not InstanceTrackerDB then return end
    local oneHourAgo = time() - 3600
    for i = #InstanceTrackerDB, 1, -1 do
        if InstanceTrackerDB[i].timestamp < oneHourAgo then table.remove(InstanceTrackerDB, i) end
    end
    local count = #InstanceTrackerDB
    local lastInstance = count > 0 and InstanceTrackerDB[count].name or "Ninguna"
    nameText:SetText(lastInstance)
    runText:SetText(string.format("%s%d|r/10", (count >= 9 and "|cFFFF0000" or "|cFFFFFFFF"), count))
end

ui:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer > 0.1 then
        local speed = GetUnitSpeed("player")
        speedText:SetText(string.format("Speed: %d%%", (speed / 7) * 100))
        self.timer = 0
    end
end)

ui:RegisterEvent("ADDON_LOADED")
ui:RegisterEvent("PLAYER_ENTERING_WORLD")
ui:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "InstanceTracker" then
        InitializeDB()
        local p = InstanceTrackerPos
        ui:ClearAllPoints()
        ui:SetPoint(p[1], p[2], p[3], p[4], p[5])
        UpdateDisplay()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local name, instanceType = GetInstanceInfo()
        if instanceType == "party" or instanceType == "raid" then
            if #InstanceTrackerDB == 0 or (time() - InstanceTrackerDB[#InstanceTrackerDB].timestamp > 10) then
                table.insert(InstanceTrackerDB, { name = name, timestamp = time() })
                InstanceTrackerGlobalDB[charKey][name] = (InstanceTrackerGlobalDB[charKey][name] or 0) + 1
            end
        end
        UpdateDisplay()
    end
end)

-- 6. Commands
SLASH_ITRACKER1 = "/it"
SlashCmdList["ITRACKER"] = function()
    if ui:IsShown() then ui:Hide() else ui:Show() end
end
