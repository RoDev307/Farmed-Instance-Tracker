-- 1. LOCAL VARIABLES
local charKey = UnitName("player") .. "-" .. GetRealmName()
local currentRealm = GetRealmName()

-- 2. INITIALIZATION
local function InitializeDB()
    if _G["InstanceTrackerDB"] == nil then _G["InstanceTrackerDB"] = {} end
    if _G["InstanceTrackerDB"][currentRealm] == nil then _G["InstanceTrackerDB"][currentRealm] = {} end
    if _G["InstanceTrackerGlobalDB"] == nil then _G["InstanceTrackerGlobalDB"] = {} end
    if _G["InstanceTrackerGlobalDB"][charKey] == nil then _G["InstanceTrackerGlobalDB"][charKey] = {} end
    if _G["InstanceTrackerPos"] == nil then _G["InstanceTrackerPos"] = { "CENTER", nil, "CENTER", 0, 0 } end
    -- Ampliado el tamaño base para evitar colisiones visuales
    if _G["InstanceTrackerSize"] == nil then _G["InstanceTrackerSize"] = { 260, 75 } end
    if _G["InstanceTrackerFirstLoad"] == nil then _G["InstanceTrackerFirstLoad"] = true end
end

-- 3. MAIN TRACKER FRAME
local ui = CreateFrame("Frame", "InstanceTrackerFrame", UIParent, "BackdropTemplate")
ui:SetMovable(true)
ui:SetResizable(true)
if ui.SetResizeBounds then ui:SetResizeBounds(230, 70, 600, 200) end
ui:EnableMouse(true)
ui:RegisterForDrag("LeftButton")
ui:SetScript("OnDragStart", ui.StartMoving)
ui:SetScript("OnDragStop", ui.StopMovingOrSizing)
ui:Hide() 

ui:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
ui:SetBackdropColor(0, 0, 0, 0.85)

-- Nombre de la estancia (con padding izquierdo)
local nameText = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
nameText:SetPoint("TOPLEFT", 15, -15)
nameText:SetText("None")
nameText:SetJustifyH("LEFT")
nameText:SetWidth(140) -- Limita el ancho para que no choque con los números

-- Contenedor para los controles: - N +
local runText = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
runText:SetTextColor(1, 1, 1)

local function UpdateDisplay()
    if not _G["InstanceTrackerDB"] or not _G["InstanceTrackerDB"][currentRealm] then return end
    local db = _G["InstanceTrackerDB"][currentRealm]
    local oneHourAgo = time() - 3600
    for i = #db, 1, -1 do
        if db[i].timestamp < oneHourAgo then table.remove(db, i) end
    end
    local count = #db
    nameText:SetText(count > 0 and db[#db].name or "None")
    runText:SetText(tostring(count))
end

-- Botón Menos (-)
local btnMinus = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
btnMinus:SetSize(18, 18)
btnMinus:SetText("-")
btnMinus:SetPoint("TOPRIGHT", ui, "TOPRIGHT", -65, -12)
btnMinus:SetScript("OnClick", function()
    local db = _G["InstanceTrackerDB"][currentRealm]
    if #db > 0 then
        table.remove(db, #db)
        UpdateDisplay()
    end
end)

-- Posicionar el número entre los botones
runText:SetPoint("LEFT", btnMinus, "RIGHT", 5, 0)

-- Botón Más (+)
local btnPlus = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
btnPlus:SetSize(18, 18)
btnPlus:SetText("+")
btnPlus:SetPoint("LEFT", runText, "RIGHT", 5, 0)
btnPlus:SetScript("OnClick", function()
    table.insert(_G["InstanceTrackerDB"][currentRealm], { name = "Manual Adj.", timestamp = time() })
    UpdateDisplay()
end)

-- Velocidad y Reset (Fila inferior)
local speedText = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
speedText:SetPoint("BOTTOMLEFT", 15, 10)

local resetBtn = CreateFrame("Button", nil, ui)
resetBtn:SetSize(16, 16)
resetBtn:SetPoint("BOTTOMRIGHT", -35, 8)
resetBtn:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
resetBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
resetBtn:SetScript("OnClick", function() ResetInstances() end)

local closeBtn = CreateFrame("Button", nil, ui, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", 2, 2)
closeBtn:SetSize(22, 22)
closeBtn:SetScript("OnClick", function() ui:Hide() end)

local resizer = CreateFrame("Button", nil, ui)
resizer:SetSize(16, 16)
resizer:SetPoint("BOTTOMRIGHT", -2, 2)
resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizer:SetScript("OnMouseDown", function() ui:StartSizing() end)
resizer:SetScript("OnMouseUp", function() 
    ui:StopMovingOrSizing() 
    _G["InstanceTrackerSize"] = { ui:GetWidth(), ui:GetHeight() }
end)

-- 4. HISTORY FRAME (Sin cambios de lógica)
local statsFrame = CreateFrame("Frame", "IT_StatsFrame", UIParent, "BackdropTemplate")
statsFrame:SetSize(420, 380)
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
    edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
statsFrame:SetBackdropColor(0, 0, 0, 0.95)

local statsTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
statsTitle:SetPoint("TOP", 0, -15)
statsTitle:SetText("ACCOUNT INSTANCE STATUS")

local scrollFrame = CreateFrame("ScrollFrame", "IT_StatsScrollFrame", statsFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -45)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 15)

local scrollChild = CreateFrame("Frame")
scrollChild:SetSize(370, 1)
scrollFrame:SetScrollChild(scrollChild)

local statsContent = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
statsContent:SetPoint("TOPLEFT", 0, 0)
statsContent:SetWidth(340)
statsContent:SetJustifyH("LEFT")

local closeStats = CreateFrame("Button", nil, statsFrame, "UIPanelCloseButton")
closeStats:SetPoint("TOPRIGHT", 0, 0)
closeStats:SetScript("OnClick", function() statsFrame:Hide() end)

local function RefreshStats()
    local hourlyDB = _G["InstanceTrackerDB"] or {}
    local globalDB = _G["InstanceTrackerGlobalDB"] or {}
    local realms = {}
    for fullCharKey, instances in pairs(globalDB) do
        local name, realm = string.split("-", fullCharKey)
        if realm then
            if not realms[realm] then realms[realm] = { chars = {} } end
            local totalRuns = 0
            for _, count in pairs(instances) do totalRuns = totalRuns + count end
            table.insert(realms[realm].chars, { name = name, data = instances, total = totalRuns })
        end
    end
    local text = "|cFFFFFF00Use /it to toggle the tracker panel|r\n\n"
    for realmName, realmData in pairs(realms) do
        local hourlyRuns = hourlyDB[realmName] or {}
        local oneHourAgo = time() - 3600
        local activeRuns = 0
        for i = #hourlyRuns, 1, -1 do
            if hourlyRuns[i].timestamp > oneHourAgo then activeRuns = activeRuns + 1 end
        end
        local status = (activeRuns >= 10) and "|cFFFF0000[LOCKED]|r" or "|cFF00FF00[READY]|r"
        text = text .. "|cFFFFFF00> SERVER: " .. realmName .. "|r  " .. status .. " (" .. activeRuns .. "/10)\n"
        table.sort(realmData.chars, function(a, b) return a.total > b.total end)
        for _, char in ipairs(realmData.chars) do
            text = text .. "   |cFF00FF00" .. char.name .. "|r (Total: " .. char.total .. ")\n"
            for instName, count in pairs(char.data) do
                text = text .. "      - " .. instName .. ": " .. count .. "\n"
            end
        end
        text = text .. "\n"
    end
    statsContent:SetText(text == "" and "No history found." or text)
    scrollChild:SetHeight(statsContent:GetStringHeight() + 50)
end

-- 5. MINIMAP BUTTON
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
    if statsFrame:IsShown() then statsFrame:Hide() else RefreshStats(); statsFrame:Show() end
end)

-- 6. LOGIC CORE & SPEED FIX
ui:SetScript("OnUpdate", function(self, elapsed)
    if InCombatLockdown() then return end
    self.timer = (self.timer or 0) + elapsed
    if self.timer > 0.1 then
        local speed = GetUnitSpeed("player")
        if speed and type(speed) == "number" then
            local speedPercent = (speed / 7) * 100
            speedText:SetText(string.format("Speed: %d%%", speedPercent))
        else
            speedText:SetText("Speed: 0%")
        end
        self.timer = 0
    end
end)

ui:RegisterEvent("ADDON_LOADED")
ui:RegisterEvent("PLAYER_ENTERING_WORLD")
ui:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        InitializeDB()
        ui:SetSize(_G["InstanceTrackerSize"][1], _G["InstanceTrackerSize"][2])
        local p = _G["InstanceTrackerPos"]
        ui:ClearAllPoints()
        ui:SetPoint(p[1], p[2], p[3], p[4], p[5])
        UpdateDisplay()
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1.5, function()
            local name, instanceType = GetInstanceInfo()
            local db = _G["InstanceTrackerDB"][currentRealm]
            if db and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario") then
                if #db == 0 or (time() - db[#db].timestamp > 15) then
                    table.insert(db, { name = name, timestamp = time() })
                    local global = _G["InstanceTrackerGlobalDB"]
                    if global[charKey] then
                        global[charKey][name] = (global[charKey][name] or 0) + 1
                    end
                end
            end
            UpdateDisplay()
        end)
    end
end)

ui:SetScript("OnHide", function()
    local point, relativeTo, relativePoint, xOfs, yOfs = ui:GetPoint()
    _G["InstanceTrackerPos"] = { point, nil, relativePoint, xOfs, yOfs }
end)

SLASH_ITRACKER1 = "/it"
SlashCmdList["ITRACKER"] = function()
    if ui:IsShown() then ui:Hide() else ui:Show() end
end