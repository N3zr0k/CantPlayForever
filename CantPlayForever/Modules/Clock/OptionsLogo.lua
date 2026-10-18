-- Optionsfenster im Rahmen des Blizzard-Uhrenfensters (Metallrahmen, rotes X, Logo links oben).
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
    logo.ring = ring

    -- Eckgrafik des Spiels (Raute), um 45° gedreht, Linien laufen schräg zum Kreis.
    -- Lage/Größe/Farbe: T.DIAMOND_* (im Probe-Tuning-Fenster einstellbar).
    logo.diamonds = {}
    for side = -1, 1, 2 do
        local diamond = logo:CreateTexture(nil, 'BACKGROUND', nil, 1)
        diamond.side = side
        logo.diamonds[#logo.diamonds + 1] = diamond
    end
    Clock:ApplyDiamonds(logo)
    -- Der Metallrahmen bringt seine eigene Ecke mit: keine zusaetzlichen Rauten.
    for _, diamond in ipairs(logo.diamonds) do diamond:Hide() end

    -- Modulbild (fertig gerendertes rundes Logo mit eigenem Rand)
    local picture = logo:CreateTexture(nil, 'ARTWORK')
    picture:SetSize(PICTURE_SIZE, PICTURE_SIZE)
    picture:SetPoint('CENTER', logo, 'CENTER', 0, 0)
    picture:Hide()
    logo.picture = picture
    -- Laufende Uhrzeit, nur im Reiter Allgemein sichtbar (wie im Uhrenfenster von Blizzard).
    local timeFrame = CreateFrame('Frame', nil, logo)
    timeFrame:SetAllPoints(logo)
    timeFrame:SetFrameLevel(logo:GetFrameLevel() + 10)
    local time = timeFrame:CreateFontString(nil, 'OVERLAY')
    time:SetFont(_G.STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')
    time:SetPoint('CENTER', timeFrame, 'CENTER', 0, 0)
    time:SetTextColor(1, 1, 1, 1)
    time:Hide()
    logo.time = time
    return logo
end

-- Hauptreiter (Schlüssel der Optionsgruppe) -> Bild. Unterreiter ändern das Bild nicht.
local TAB_LOGOS = {
    -- general: kein Bild, sondern die laufende Uhr (Standardlogo mit Uhrzeit)
    options = LOGO_PATH .. 'optionen_logo',
    alarms = LOGO_PATH .. 'alarm_logo',
    timer = LOGO_PATH .. 'timer_logo',
    health = LOGO_PATH .. 'pause_logo', -- Platzhalter bis zum eigenen Health-Icon
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

local function UpdateLogoTime(logo)
    local tab = SelectedTab()
    -- Im Blizzard-Rahmen zeigt jeder Reiter den Uhrenkreis; ohne Rahmen nur Allgemein.
    local show = logo.skinned or tab == 'general' or tab == nil
    if show then
        local text = Clock:FormatClock()
        if logo.timeText ~= text then logo.timeText = text; logo.time:SetText(text) end
    end
    if logo.time:IsShown() ~= show then logo.time:SetShown(show) end
end

local function ApplyLogo(logo)
    local path = SelectedLogo()
    UpdateLogoTime(logo)
    if logo.skinned then
        -- Im Blizzard-Rahmen sitzt in der Ecke nur die Uhrzeit auf dem Hintergrund der
        -- Minimap-Uhr (Globus, ohne eigenen Ring: den liefert die Rahmenecke).
        logo.picture:Hide()
        logo.ring:Hide()
        logo.default:Show()
        logo.current, logo.currentSet = nil, false
        return
    end
    if logo.ring and not logo.ring:IsShown() then
        logo.ring:Show()
    end
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

-- Rahmen des Blizzard-Uhrenfensters (Metallrahmen mit Eckstuecken, Kopfleiste, rotes X).
-- Alle Grafiken sind Spiel-Atlanten; fehlt einer, bleibt der Ace-Rahmen unveraendert.
local FRAME_ATLASES = {
    'UI-Frame-PortraitMetal-CornerTopLeft', 'UI-Frame-Metal-CornerTopRight',
    'UI-Frame-Metal-CornerBottomLeft', 'UI-Frame-Metal-CornerBottomRight',
    '_UI-Frame-Metal-EdgeTop', '_UI-Frame-Metal-EdgeBottom',
    '!UI-Frame-Metal-EdgeLeft', '!UI-Frame-Metal-EdgeRight',
}
local BACKGROUND_TEXTURE = 374155 -- Hintergrund des Uhrenfensters
local STREAKS_ATLAS = '_UI-Frame-TopTileStreaks'
local CLOSE_ATLASES = {normal = 'RedButton-Exit', pushed = 'RedButton-exit-pressed',
    disabled = 'RedButton-Exit-Disabled', highlight = 'RedButton-Highlight'}
local HEADER_HEIGHT = 37

local function AtlasesAvailable()
    if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
    for _, atlas in ipairs(FRAME_ATLASES) do
        if not C_Texture.GetAtlasInfo(atlas) then return false end
    end
    return true
end

local function BuildSkin(open)
    local frame = open.frame
    local skin = {}
    local function Tex(layer, sublevel)
        local tex = frame:CreateTexture(nil, layer, nil, sublevel)
        skin[#skin + 1] = tex
        return tex
    end
    local bg = Tex('BACKGROUND', -7)
    bg:SetTexture(BACKGROUND_TEXTURE, 'REPEAT', 'REPEAT')
    bg:SetHorizTile(true)
    bg:SetVertTile(true)
    bg:SetPoint('TOPLEFT', frame, 'TOPLEFT', 2, -2)
    bg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -2, -2) -- 4 px tiefer, bis unter den Rahmen
    if C_Texture.GetAtlasInfo(STREAKS_ATLAS) then
        local streaks = Tex('BACKGROUND', -6)
        streaks:SetAtlas(STREAKS_ATLAS)
        streaks:SetHorizTile(true)
        streaks:SetPoint('TOPLEFT', frame, 'TOPLEFT', 6, -3)
        streaks:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -2, -3)
        streaks:SetHeight(HEADER_HEIGHT)
    end
    local function Corner(atlas, point, x, y)
        local tex = Tex('OVERLAY', 2)
        tex:SetAtlas(atlas, true)
        tex:SetPoint(point, frame, point, x, y)
        return tex
    end
    local tl = Corner(FRAME_ATLASES[1], 'TOPLEFT', -12, 16)
    skin.corner = tl
    local tr = Corner(FRAME_ATLASES[2], 'TOPRIGHT', 4, 16)
    local bl = Corner(FRAME_ATLASES[3], 'BOTTOMLEFT', -12, -16)
    local br = Corner(FRAME_ATLASES[4], 'BOTTOMRIGHT', 4, -16)
    local function Edge(atlas, horizontal, a, aPoint, b, bPoint)
        local tex = Tex('OVERLAY', 1)
        tex:SetAtlas(atlas, true)
        if horizontal then tex:SetHorizTile(true) else tex:SetVertTile(true) end
        tex:SetPoint(aPoint[1], a, aPoint[2], 0, 0)
        tex:SetPoint(bPoint[1], b, bPoint[2], 0, 0)
        return tex
    end
    Edge(FRAME_ATLASES[5], true, tl, {'TOPLEFT', 'TOPRIGHT'}, tr, {'BOTTOMRIGHT', 'BOTTOMLEFT'})
    Edge(FRAME_ATLASES[6], true, bl, {'TOPLEFT', 'TOPRIGHT'}, br, {'BOTTOMRIGHT', 'BOTTOMLEFT'})
    Edge(FRAME_ATLASES[7], false, tl, {'TOPLEFT', 'BOTTOMLEFT'}, bl, {'BOTTOMRIGHT', 'TOPRIGHT'})
    Edge(FRAME_ATLASES[8], false, tr, {'TOPLEFT', 'BOTTOMLEFT'}, br, {'BOTTOMRIGHT', 'TOPRIGHT'})

    -- Rotes X oben rechts (ersetzt den Schliessen-Knopf unten).
    local close = CreateFrame('Button', nil, frame)
    close:SetSize(T.OPT_CLOSE_SIZE, T.OPT_CLOSE_SIZE)
    close:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', T.OPT_CLOSE_X, T.OPT_CLOSE_Y)
    close:SetFrameLevel(frame:GetFrameLevel() + 30)
    close:SetNormalAtlas(CLOSE_ATLASES.normal)
    close:SetPushedAtlas(CLOSE_ATLASES.pushed)
    close:SetDisabledAtlas(CLOSE_ATLASES.disabled)
    close:SetHighlightAtlas(CLOSE_ATLASES.highlight)
    close:SetScript('OnClick', function() Clock.aceDialog:Close('CantPlayForever') end)
    skin.close = close

    -- Name und Untertitel rechts neben dem Logo.
    local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    title:SetPoint('TOPLEFT', frame, 'TOPLEFT', T.OPT_TITLE_X, T.OPT_TITLE_Y)
    title:SetText("Can't play Forever")
    skin.title = title
    local tagline = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    tagline:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, T.OPT_TAGLINE_DY)
    tagline:SetTextColor(0.6, 0.6, 0.6)
    tagline:SetText(ns.L.ADDON_TAGLINE)
    skin.tagline = tagline
    return skin
end

-- Der Schliessen-Knopf des AceGUI-Fensters ist kein Feld des Widgets: ueber den Text suchen.
local function AceCloseButton(open)
    if open.cpfAceClose then return open.cpfAceClose end
    for _, child in ipairs({open.frame:GetChildren()}) do
        if child.obj == open and child:GetObjectType() == 'Button'
            and child.GetText and child:GetText() == _G.CLOSE then
            open.cpfAceClose = child
            return child
        end
    end
end

-- Verschiebe-Flaeche des AceGUI-Fensters: haengt am (versteckten) Titelschild. Im Rahmen
-- soll die ganze Kopfzeile (inkl. Uhrenkreis) das Fenster ziehen.
local function MoverFrame(open)
    if open.cpfMover then return open.cpfMover end
    for _, child in ipairs({open.frame:GetChildren()}) do
        if child:GetObjectType() == 'Frame' and child:IsMouseEnabled()
            and select(2, child:GetPoint(1)) == open.titlebg then
            open.cpfMover = child
            return child
        end
    end
end

local function PlaceMover(open, wide)
    local mover = MoverFrame(open)
    if not mover then return end
    mover:ClearAllPoints()
    if wide then
        mover:SetPoint('TOPLEFT', open.frame, 'TOPLEFT', 0, 0)
        mover:SetPoint('TOPRIGHT', open.frame, 'TOPRIGHT', -(T.OPT_CLOSE_SIZE or 26), 0)
        mover:SetHeight((T.OPT_CONTENT_TOP or 60) - 5)
    else
        mover:SetAllPoints(open.titlebg)
    end
end

-- Lage aller Elemente des Rahmens aus den Tuning-Werten (Clock.tune, T.OPT_*);
-- wird auch vom Frame_Debugger nach einer Wertaenderung aufgerufen.
function Clock:ApplyOptionsLayout()
    local open = self.aceDialog.OpenFrames and self.aceDialog.OpenFrames.CantPlayForever
    local skin = open and open.cpfSkin
    if not (skin and open.cpfLogo and open.cpfLogo.skinned) then return end
    local logo = open.cpfLogo
    logo:ClearAllPoints()
    logo:SetPoint('CENTER', skin.corner, 'CENTER', T.OPT_CLOCK_DX, T.OPT_CLOCK_DY)
    logo:SetScale(T.OPT_CLOCK_SIZE / 64)
    logo.time:SetFont(_G.STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF', T.OPT_TIME_SIZE, 'OUTLINE')
    logo.time:ClearAllPoints()
    logo.time:SetPoint('CENTER', logo.time:GetParent(), 'CENTER', T.OPT_TIME_DX, T.OPT_TIME_DY)
    skin.close:SetSize(T.OPT_CLOSE_SIZE, T.OPT_CLOSE_SIZE)
    skin.close:ClearAllPoints()
    skin.close:SetPoint('TOPRIGHT', open.frame, 'TOPRIGHT', T.OPT_CLOSE_X, T.OPT_CLOSE_Y)
    skin.title:ClearAllPoints()
    skin.title:SetPoint('TOPLEFT', open.frame, 'TOPLEFT', T.OPT_TITLE_X, T.OPT_TITLE_Y)
    skin.tagline:ClearAllPoints()
    skin.tagline:SetPoint('TOPLEFT', skin.title, 'BOTTOMLEFT', 0, T.OPT_TAGLINE_DY)
    open.content:SetPoint('TOPLEFT', open.frame, 'TOPLEFT', 17, -T.OPT_CONTENT_TOP)
    PlaceMover(open, true)
end

local function SetSkin(open, shown)
    if shown then
        if not open.cpfSkin then
            if not AtlasesAvailable() then return false end
            open.cpfSkin = BuildSkin(open)
        end
        -- Ace-Rahmen unsichtbar machen (Farben fuer den Pool merken).
        local frame = open.frame
        if frame.SetBackdropColor and not open.cpfBackdropSaved then
            open.cpfBackdropSaved = {{frame:GetBackdropColor()}, {frame:GetBackdropBorderColor()}}
            frame:SetBackdropColor(0, 0, 0, 0)
            frame:SetBackdropBorderColor(0, 0, 0, 0)
        end
    end
    local skin = open.cpfSkin
    if not skin then return false end
    for _, region in ipairs(skin) do region:SetShown(shown) end
    skin.close:SetShown(shown)
    skin.title:SetShown(shown)
    skin.tagline:SetShown(shown)
    PlaceMover(open, shown)
    local aceClose = AceCloseButton(open)
    if aceClose then aceClose:SetShown(not shown) end
    -- Inhalt unter die Kopfzeile (Name, Untertitel, Logo) schieben.
    local content = open.content
    if content then
        content:SetPoint('TOPLEFT', open.frame, 'TOPLEFT', 17, shown and -T.OPT_CONTENT_TOP or -27)
    end
    if open.cpfLogo and not shown then open.cpfLogo:SetScale(1) end
    -- Ohne unteren Schliessen-Knopf darf die Statuszeile bis zum rechten Rand reichen.
    local statusbg = open.statustext and open.statustext:GetParent()
    if statusbg and statusbg.GetPoint then
        if shown and not open.cpfStatusPoint then
            local point, relative, relPoint, x, y = statusbg:GetPoint(2)
            if point == 'BOTTOMRIGHT' then
                open.cpfStatusPoint = {point, relative, relPoint, x, y}
                statusbg:SetPoint('BOTTOMRIGHT', open.frame, 'BOTTOMRIGHT', -17, y or 15)
            end
        elseif not shown and open.cpfStatusPoint then
            statusbg:SetPoint(unpack(open.cpfStatusPoint))
            open.cpfStatusPoint = nil
        end
    end
    if not shown and open.cpfBackdropSaved then
        local saved = open.cpfBackdropSaved
        open.frame:SetBackdropColor(unpack(saved[1]))
        open.frame:SetBackdropBorderColor(unpack(saved[2]))
        open.cpfBackdropSaved = nil
    end
    return true
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
    local skinned = SetSkin(open, true)
    open.cpfLogo:ClearAllPoints()
    open.cpfLogo.skinned = skinned
    if skinned then
        self:ApplyOptionsLayout()
    else
        open.cpfLogo:SetPoint('TOP', open.frame, 'TOP', T.LOGO_X, T.LOGO_Y)
    end
    open.cpfDisarm = open.cpfDisarm or BuildDisarmButton(open)
    UpdateDisarmButton(open)
    open.cpfLogo:Show()
    open.cpfLogo.currentSet = false
    ApplyLogo(open.cpfLogo)
    open.titletext:Hide() -- Name und Untertitel stehen im eigenen Kopfbereich
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
            SetSkin(open, false)
            open.titletext:Show()
            open:SetStatusText('')
            if open.cpfStatusColor then
                open.statustext:SetTextColor(unpack(open.cpfStatusColor))
                open.cpfStatusColor = nil
            end
            local saved = open.cpfStatusSaved
            local plate = open.statustext:GetParent()
            if saved and plate and plate.SetBackdropColor then
                plate:SetBackdropColor(unpack(saved[1]))
                plate:SetBackdropBorderColor(unpack(saved[2]))
            end
            open.cpfStatusSaved = nil
        end)
    end
end
