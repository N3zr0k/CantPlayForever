-- Dev/Tuning.lua: gespeicherte FD-Werte gelten nur, wenn der Standardwert im Addon unveraendert ist.
local registered
local Clock = {HOLIDAY_STYLE_KEYS = {}, tune = {A = 5, B = 7}, tuneDefaults = {A = 5, B = 7, C = 1}, db = {global = {}}}
function Clock:RefreshStage() end
LibStub = function() return {GetAddon = function() return Clock end} end
FrameDebugger = {Register = function(_, _, def) registered = def end}
CPFTuneDB = {CantPlayForever = {
    A = 9, B = 3,                      -- A gespeichert bei Standard 5 -> bleibt; B bei Standard 4 -> veraltet
    C = 2,                             -- ohne Basis (Altbestand) -> verworfen
    _base = {A = 5, B = 4},
}}
assert(loadfile('CantPlayForever/Dev/Tuning.lua'))('CantPlayForever', {HOLIDAY_STYLES = {}})
local saved = CPFTuneDB.CantPlayForever
assert(saved.A == 9, 'unveraenderter Standard: Abweichung bleibt')
assert(saved.B == nil, 'geaenderter Standard: veralteter Wert faellt weg')
assert(saved.C == nil, 'Altbestand ohne Basis faellt weg')
assert(registered, 'Register aufgerufen')
saved.A = 11
registered.apply('A')
assert(saved._base.A == 5, 'Basis wird beim Aendern gemerkt')
print('Tuning baseline OK')
