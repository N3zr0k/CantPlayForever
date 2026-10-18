-- Prueft, dass alle uebergebenen Lua-Dateien syntaktisch laden (nur Parsen, kein Ausfuehren).
local bad = 0
for _, file in ipairs(arg) do
    local chunk, err = loadfile(file)
    if not chunk then print(err); bad = bad + 1 end
end
if bad > 0 then os.exit(1) end
print('Syntax OK')
