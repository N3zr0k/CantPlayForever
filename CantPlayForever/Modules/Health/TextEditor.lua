-- Health-Texte: mehrzeiliges AceGUI-Feld ohne den eingebauten "Annehmen"-Knopf.
-- Der Entwurf wird waehrend des Tippens aktualisiert; gespeichert wird er erst
-- durch die explizite Aktion "Speichern" in den Health-Optionen.
local ADDON_NAME = ...
local AceGUI = LibStub and LibStub('AceGUI-3.0', true)
if not AceGUI then return end

local WIDGET_TYPE = 'CPFHealthTextEditor'
local VERSION = 1
if (AceGUI:GetWidgetVersion(WIDGET_TYPE) or 0) >= VERSION then return end

local function Constructor()
    -- Die Blizzard-/Ace3-Mehrzeilenfunktionen bleiben erhalten, einschliesslich
    -- Scrollen und Zeilenumbruch. Wir verwenden nur ein eigenes Widget-Profil.
    local widget = AceGUI:Create('MultiLineEditBox')
    local baseAcquire = widget.OnAcquire
    widget.type = WIDGET_TYPE
    widget.OnAcquire = function(self)
        baseAcquire(self)
        self:DisableButton(true)
        self:SetCallback('OnTextChanged', function(editor, _, text)
            -- AceConfig registriert nur OnEnterPressed. Entwurfsdaten direkt
            -- aktualisieren, ohne die Optionsansicht bei jedem Zeichen neu aufzubauen.
            local option = editor:GetUserData('option')
            if option and type(option.set) == 'function' then
                option.set(nil, text)
            end
        end)
    end
    return widget
end

AceGUI:RegisterWidgetType(WIDGET_TYPE, Constructor, VERSION)
