-- Rundes Logo im Optionsfenster: ersetzt das eckige Titelschild des AceGUI-Fensters. Je nach
-- gewähltem Reiter zeigt es das Bild des Moduls (module.logo), sonst Globus mit Bronzering der
-- Uhr. Das Fenster stammt aus einem Pool, deshalb wird beim Schließen alles zurückgesetzt,
-- damit andere Addons ihr Titelschild behalten.
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, T = ns.Clock, ns.T

local PLATE_TEXTURE = 131080 -- Interface\DialogFrame\UI-DialogBox-Header
local LOGO_SIZE = 64
local LOGO_PATH = 'Interface\\AddOns\\CantPlayForever\\Media\\Logos\\'
local DIAMOND_ATLAS = 'UI-Frame-DiamondMetal-CornerTopLeft' -- 32x32, Spielgrafik
local DIAMOND_ATLAS_RIGHT = 'UI-Frame-DiamondMetal-CornerTopRight'
local PICTURE_SIZE = 88 -- Ringhöhe aller Bilder ist gleich (191 von 256 px)

local logos = setmetatable({}, { __mode = 'k' })

function Clock:ApplyDiamonds(logo)
    logos[logo] = true
    if logo.parentFrame then
        logo:ClearAllPoints()
        logo:SetPoint('TOP', logo.parentFrame, 'TOP', T.LOGO_X, T.LOGO_Y)
    end
    for _, diamond in ipairs(logo.diamonds) do
        local side = diamond.side
        local atlas, flip = side == -1 and DIAMOND_ATLAS or DIAMOND_ATLAS_RIGHT, false
        if not C_Texture.GetAtlasInfo(atlas) then atlas, flip = DIAMOND_ATLAS, side == 1 end
        if C_Texture.GetAtlasInfo(atlas) then
            diamond:SetAtlas(atlas)
            if flip then diamond:SetTexCoord(1, 0, 0, 1) end
            diamond:SetDesaturated(T.DIAMOND_DESAT == 1)
            diamond:SetVertexColor(T.DIAMOND_R, T.DIAMOND_G, T.DIAMOND_B)
            diamond:SetRotation(-side * math.pi / 4)
        else
            diamond:SetTexture(LOGO_PATH .. 'diamond')
        end
        diamond:SetSize(T.DIAMOND_SIZE, T.DIAMOND_SIZE)
        diamond:ClearAllPoints()
        diamond:SetPoint('CENTER', logo, 'CENTER', side * T.DIAMOND_X, T.DIAMOND_Y)
    end
end

function Clock:RefreshDiamonds()
    for logo in pairs(logos) do self:ApplyDiamonds(logo) end
end

local function BuildLogo(parent)
    local logo = CreateFrame('Frame', nil, parent)
    logo:SetSize(LOGO_SIZE, LOGO_SIZE)
    logo.parentFrame = parent
    logo:SetPoint('TOP', parent, 'TOP', T.LOGO_X, T.LOGO_Y)
    logo:SetFrameLevel(parent:GetFrameLevel() + 20)

    -- Standardlogo: Globus mit Ring (wie die Uhr)
    local default = CreateFrame('Frame', nil, logo)
    default:SetAllPoints(logo)
    local shadow = default:CreateTexture(nil, 'BACKGROUND', nil, -8)
    shadow:SetColorTexture(0, 0, 0, T.SHADOW_ALPHA)
    shadow:SetAllPoints(default)
    local globe = default:CreateTexture(nil, 'BACKGROUND', nil, -4)
    globe:SetTexture(ns.GLOBE_TEXTURE)
    globe:SetAllPoints(default)
    if type(default.CreateMaskTexture) == 'function' then
        local function NewMask()
            local mask = default:CreateMaskTexture()
            mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask',
                'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
            return mask
        end
        local gm, sm = NewMask(), NewMask()
        gm:SetSize(T.GLOBE_MASK, T.GLOBE_MASK)
        gm:SetPoint('CENTER', default, 'CENTER', T.GLOBE_MASK_DX, T.GLOBE_MASK_DY)
        globe:AddMaskTexture(gm)
        sm:SetSize(T.SHADOW_SIZE, T.SHADOW_SIZE)
        sm:SetPoint('CENTER', default, 'CENTER', T.GLOBE_MASK_DX, T.GLOBE_MASK_DY - 0.25 - T.SHADOW_DROP)
        shadow:AddMaskTexture(sm)
    end
    local ring = Clock:CreateRing(default, true)
    ring:SetFrameLevel(default:GetFrameLevel() + 2)
    Clock:LayoutRing(ring, 1, default, 'TOPLEFT',
        -T.RING_OFFSET + T.RING_X0, T.RING_OFFSET - T.RING_Y0)
    logo.default = default

    -- Eckgrafik des Spiels (Raute), um 45° gedreht, Linien laufen schräg zum Kreis.
    -- Lage/Größe/Farbe: T.DIAMOND_* (im Probe-Tuning-Fenster einstellbar).
    logo.diamonds = {}
    for side = -1, 1, 2 do
        local diamond = logo:CreateTexture(nil, 'BACKGROUND', nil, 1)
        diamond.side = side
        logo.diamonds[#logo.diamonds + 1] = diamond
    end
    Clock:ApplyDiamonds(logo)

    -- Modulbild (fertig gerendertes rundes Logo mit eigenem Rand)
    local picture = logo:CreateTexture(nil, 'ARTWORK')
    picture:SetSize(PICTURE_SIZE, PICTURE_SIZE)
    picture:SetPoint('CENTER', logo, 'CENTER', 0, 0)
    picture:Hide()
    logo.picture = picture
    return logo
end

-- Hauptreiter (Schlüssel der Optionsgruppe) -> Bild. Unterreiter ändern das Bild nicht.
local TAB_LOGOS = {
    general = LOGO_PATH .. 'allgemein_logo',
    options = LOGO_PATH .. 'optionen_logo',
    alarms = LOGO_PATH .. 'alarm_logo',
    timer = LOGO_PATH .. 'timer_logo',
}

local function SelectedTab()
    local status = Clock.aceDialog:GetStatusTable('CantPlayForever')
    return status and status.groups and status.groups.selected
end

local function SelectedLogo()
    local selected = SelectedTab()
    return selected and TAB_LOGOS[selected] or nil
end

-- "Alle Wecker deaktivieren": außerhalb des Scrollfensters, links neben "Schließen", in jedem Reiter.
local function UpdateDisarmButton(open)
    local button = open.cpfDisarm
    if not button then return end
    local show = Clock:IsModuleEnabled('alarms')
    button:SetShown(show)
    if show then button:SetEnabled(Clock:CountArmedAlarms() > 0) end
end

local function BuildDisarmButton(open)
    local button = CreateFrame('Button', nil, open.frame, 'UIPanelButtonTemplate')
    button:SetText(ns.L.DISARM_ALL)
    button:SetSize(math.max(140, button:GetFontString():GetStringWidth() + 30), 24)
    -- Rechtes Ende der Statuszeile (dort steht links die Version), direkt links neben "Schließen"
    local statusbg = open.statustext:GetParent()
    button:SetHeight(22)
    button:SetPoint('RIGHT', statusbg, 'RIGHT', -2, 0)
    button:SetScript('OnClick', function()
        Clock:DisarmAlarms()
        UpdateDisarmButton(open)
    end)
    return button
end

local function ApplyLogo(logo)
    local path = SelectedLogo()
    if logo.current == path and logo.currentSet then return end
    logo.current, logo.currentSet = path, true
    if path then
        logo.picture:SetTexture(path)
        local size = PICTURE_SIZE
        logo.picture:SetSize(size, size)
        logo.picture:Show()
        logo.default:Hide()
    else
        logo.picture:Hide()
        logo.default:Show()
    end
end

-- Größe des Optionsfensters fest: Anfasser (unten rechts, unten, rechts) aus. Das Fenster kommt
-- aus einem Pool, beim Schließen wird alles zurückgesetzt.
local function SetResizable(widget, resizable)
    if widget.frame.SetResizable then widget.frame:SetResizable(resizable) end
    for _, name in ipairs({'sizer_se', 'sizer_s', 'sizer_e'}) do
        if widget[name] then widget[name]:SetShown(resizable) end
    end
end

local function SetPlate(widget, shown)
    widget.titlebg:SetShown(shown)
    for _, region in ipairs({widget.frame:GetRegions()}) do
        local texture = region.GetTexture and region:GetTexture()
        if texture == PLATE_TEXTURE
            or (type(texture) == 'string' and texture:lower():find('dialogbox%-header')) then
            region:SetShown(shown)
        end
    end
end

function Clock:StyleOptionsFrame()
    local open = self.aceDialog.OpenFrames and self.aceDialog.OpenFrames.CantPlayForever
    if not (open and open.frame and open.titlebg and open.titletext) then return end
    if type(self.CreateRing) ~= 'function' or not ns.GLOBE_TEXTURE then return end
    if not open.cpfLogo then
        open.cpfLogo = BuildLogo(open.frame)
        -- Reiterwechsel erkennen (leichtes Abfragen, solange das Fenster offen ist).
        local elapsedTotal = 0
        open.cpfLogo:SetScript('OnUpdate', function(logo, elapsed)
            elapsedTotal = elapsedTotal + elapsed
            if elapsedTotal >= 0.15 then
                elapsedTotal = 0
                ApplyLogo(logo)
                UpdateDisarmButton(open)
            end
        end)
    end
    SetPlate(open, false)
    SetResizable(open, false)
    open.cpfDisarm = open.cpfDisarm or BuildDisarmButton(open)
    UpdateDisarmButton(open)
    open.cpfLogo:Show()
    open.cpfLogo.currentSet = false
    ApplyLogo(open.cpfLogo)
    open.titletext:Hide() -- der Name steht nicht mehr im Kopf, nur das Logo
    -- Unten: statt des Statuskastens die Version aus der .toc.
    local statusbg = open.statustext:GetParent()
    if statusbg and statusbg.SetBackdropColor and not open.cpfStatusSaved then
        open.cpfStatusSaved = {
            {statusbg:GetBackdropColor()}, {statusbg:GetBackdropBorderColor()},
        }
        statusbg:SetBackdropColor(0, 0, 0, 0)
        statusbg:SetBackdropBorderColor(0, 0, 0, 0)
    end
    local getMeta = _G.C_AddOns and _G.C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
    local version = getMeta and getMeta(ADDON_NAME, 'Version') or '?'
    open:SetStatusText(string.format(ns.L.VERSION_SHORT, tostring(version)))
    if not open.cpfStatusColor then open.cpfStatusColor = {open.statustext:GetTextColor()} end
    open.statustext:SetTextColor(0.55, 0.55, 0.55, 1) -- Version in Grau
    if not open.cpfHooked then
        open.cpfHooked = true
        open.frame:HookScript('OnHide', function()
            -- Fenster geht zurück in den Pool: Titelschild wiederherstellen.
            if open.cpfLogo then open.cpfLogo:Hide() end
            if open.cpfDisarm then open.cpfDisarm:Hide() end
            SetPlate(open, true)
            SetResizable(open, true)
            open.titletext:Show()
            open:SetStatusText('')
            if open.cpfStatusColor then
                open.statustext:SetTextColor(unpack(open.cpfStatusColor))
                open.cpfStatusColor = nil
            end
            local saved = open.cpfStatusSaved
            local statusbg = open.statustext:GetParent()
            if saved and statusbg and statusbg.SetBackdropColor then
                statusbg:SetBackdropColor(unpack(saved[1]))
                statusbg:SetBackdropBorderColor(unpack(saved[2]))
            end
            open.cpfStatusSaved = nil
        end)
    end
end
