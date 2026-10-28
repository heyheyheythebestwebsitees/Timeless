--[[
    RCLR SaveManager - Linoria-style config manager
    Usage:
        local SaveManager = loadstring(game:HttpGet(...))()
        SaveManager:SetLibrary(Library)
        SaveManager:SetFolder("RCLR_Prem")
        SaveManager:BuildConfigSection(SettingsTab)
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.__index = SaveManager

SaveManager.Folder = "RCLR_Prem"
SaveManager.Library = nil
SaveManager.Ignore = {}

local function ensureFolder(path)
    if not isfolder then return end
    pcall(function()
        if not isfolder(path) then makefolder(path) end
    end)
end

function SaveManager:SetLibrary(lib)
    self.Library = lib
end

function SaveManager:SetFolder(name)
    self.Folder = tostring(name or "RCLR_Prem")
    ensureFolder(self.Folder)
    ensureFolder(self.Folder .. "/configs")
end

function SaveManager:IgnoreThemeSettings()
    -- optional no-op for Linoria compat
end

function SaveManager:GetConfigPath(name)
    return self.Folder .. "/configs/" .. tostring(name) .. ".json"
end

function SaveManager:GetConfigList()
    local list = {}
    if type(listfiles) ~= "function" then return list end
    local ok, files = pcall(listfiles, self.Folder .. "/configs")
    if not ok or type(files) ~= "table" then return list end
    for _, f in ipairs(files) do
        local n = tostring(f):match("([^/\\]+)%.json$")
        if n then table.insert(list, n) end
    end
    table.sort(list)
    return list
end

function SaveManager:BuildSaveTable()
    local lib = self.Library
    local toggles = (lib and lib.Toggles) or (getgenv and getgenv().RCLR_Toggles) or (getgenv and getgenv().Toggles) or {}
    local options = (lib and lib.Options) or (getgenv and getgenv().RCLR_Options) or (getgenv and getgenv().Options) or {}
    local data = { toggles = {}, options = {}, version = 1 }

    for idx, t in pairs(toggles) do
        if type(t) == "table" and t.Value ~= nil and not self.Ignore[idx] then
            data.toggles[idx] = t.Value
        end
    end
    for idx, o in pairs(options) do
        if type(o) == "table" and not self.Ignore[idx] then
            if o.Type == "ColorPicker" and o.Value then
                local c = o.Value
                if typeof(c) == "Color3" then
                    data.options[idx] = { __type = "Color3", R = c.R, G = c.G, B = c.B }
                end
            elseif o.Value ~= nil then
                data.options[idx] = o.Value
            end
        end
    end
    return data
end

function SaveManager:ApplySaveTable(data)
    if type(data) ~= "table" then return false end
    local lib = self.Library
    local toggles = (lib and lib.Toggles) or (getgenv and getgenv().RCLR_Toggles) or (getgenv and getgenv().Toggles) or {}
    local options = (lib and lib.Options) or (getgenv and getgenv().RCLR_Options) or (getgenv and getgenv().Options) or {}

    if type(data.toggles) == "table" then
        for idx, val in pairs(data.toggles) do
            local t = toggles[idx]
            if t and t.SetValue then
                pcall(function() t:SetValue(val) end)
            end
        end
    end
    if type(data.options) == "table" then
        for idx, val in pairs(data.options) do
            local o = options[idx]
            if o and o.SetValue then
                pcall(function()
                    if type(val) == "table" and val.__type == "Color3" then
                        o:SetValue(Color3.new(val.R or 1, val.G or 1, val.B or 1))
                    else
                        o:SetValue(val)
                    end
                end)
            elseif o and o.SetValueRGB and type(val) == "table" and val.__type == "Color3" then
                pcall(function() o:SetValueRGB(Color3.new(val.R or 1, val.G or 1, val.B or 1)) end)
            end
        end
    end
    return true
end

function SaveManager:Save(name)
    if type(writefile) ~= "function" then return false, "writefile missing" end
    name = tostring(name or ""):gsub("[^%w%-%_ ]", "")
    if name == "" then return false, "empty name" end
    ensureFolder(self.Folder .. "/configs")
    local data = self:BuildSaveTable()
    local ok, enc = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return false, enc end
    local ok2, err = pcall(writefile, self:GetConfigPath(name), enc)
    return ok2, err
end

function SaveManager:Load(name)
    if type(readfile) ~= "function" then return false, "readfile missing" end
    name = tostring(name or "")
    local ok, raw = pcall(readfile, self:GetConfigPath(name))
    if not ok or type(raw) ~= "string" then return false, "not found" end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or type(data) ~= "table" then return false, data end
    self:ApplySaveTable(data)
    return true
end

function SaveManager:Delete(name)
    if type(delfile) ~= "function" then return false end
    local ok, err = pcall(delfile, self:GetConfigPath(name))
    return ok, err
end

function SaveManager:SetAutoLoad(name)
    if type(writefile) ~= "function" then return end
    ensureFolder(self.Folder)
    pcall(writefile, self.Folder .. "/autoload_config.txt", tostring(name or ""))
end

function SaveManager:GetAutoLoad()
    if type(readfile) ~= "function" then return nil end
    local ok, raw = pcall(readfile, self.Folder .. "/autoload_config.txt")
    if ok and type(raw) == "string" and raw ~= "" then
        return (raw:gsub("%s+$", ""))
    end
    return nil
end

function SaveManager:LoadAutoloadConfig()
    local name = self:GetAutoLoad()
    if name and name ~= "" then
        local ok = self:Load(name)
        local lib = self.Library
        if ok and lib and lib.Notify then
            lib:Notify("Config auto-loaded: " .. name, 3)
        end
        return ok
    end
    return false
end

function SaveManager:TryAutoLoad()
    return self:LoadAutoloadConfig()
end

function SaveManager:BuildConfigSection(tab)
    local lib = self.Library
    if not lib or not tab then return end
    local box = tab:AddLeftGroupbox("Config Manager")

    local list = self:GetConfigList()
    if #list == 0 then list = { "(none)" } end

    box:AddDropdown("SM_ConfigList", {
        Text = "Config List",
        Values = list,
        Default = 1,
    })

    box:AddInput("SM_ConfigName", {
        Text = "Config Name",
        Default = "",
        Placeholder = "my config",
    })

    local function refreshList()
        local opt = (lib.Options and lib.Options.SM_ConfigList) or (Options and Options.SM_ConfigList)
        local names = self:GetConfigList()
        if #names == 0 then names = { "(none)" } end
        if opt and opt.SetValues then opt:SetValues(names) end
    end

    local function selectedName()
        return (lib.Options and lib.Options.SM_ConfigList and lib.Options.SM_ConfigList.Value)
            or (Options and Options.SM_ConfigList and Options.SM_ConfigList.Value)
    end

    local function inputName()
        return (lib.Options and lib.Options.SM_ConfigName and lib.Options.SM_ConfigName.Value)
            or (Options and Options.SM_ConfigName and Options.SM_ConfigName.Value)
    end

    box:AddButton("Create Config", function()
        local name = inputName()
        if not name or name == "" then
            if lib.Notify then lib:Notify("Enter a config name", 3) end
            return
        end
        local ok, err = self:Save(name)
        if lib.Notify then
            lib:Notify(ok and ("Config created: " .. name) or ("Create failed: " .. tostring(err)), 3)
        end
        refreshList()
    end)

    box:AddButton("Save Config", function()
        local name = selectedName()
        if not name or name == "(none)" then
            name = inputName()
        end
        if not name or name == "" or name == "(none)" then
            if lib.Notify then lib:Notify("Select or enter a config name", 3) end
            return
        end
        local ok, err = self:Save(name)
        if lib.Notify then
            lib:Notify(ok and ("Config saved: " .. name) or ("Save failed: " .. tostring(err)), 3)
        end
        refreshList()
    end)

    box:AddButton("Load Config", function()
        local name = selectedName()
        if not name or name == "(none)" then
            if lib.Notify then lib:Notify("Select a config", 3) end
            return
        end
        local ok = self:Load(name)
        if lib.Notify then
            lib:Notify(ok and ("Config loaded: " .. name) or "Load failed", 3)
        end
    end)

    box:AddButton("Delete Config", function()
        local name = selectedName()
        if not name or name == "(none)" then return end
        local ok = self:Delete(name)
        if lib.Notify then
            lib:Notify(ok and ("Deleted: " .. name) or "Delete failed", 3)
        end
        refreshList()
    end)

    box:AddButton("Set Auto-Load Config", function()
        local name = selectedName()
        if name and name ~= "(none)" then
            self:SetAutoLoad(name)
            if lib.Notify then lib:Notify("Auto-load config: " .. name, 3) end
        end
    end)

    box:AddButton("Clear Auto-Load Config", function()
        self:SetAutoLoad("")
        if lib.Notify then lib:Notify("Auto-load config cleared", 3) end
    end)

    box:AddButton("Refresh List", function()
        refreshList()
        if lib.Notify then lib:Notify("Config list refreshed", 2) end
    end)
end

function SaveManager:ApplyToGroupbox(box)
    if not box then return end
    local fake = {
        AddLeftGroupbox = function() return box end,
        AddRightGroupbox = function() return box end,
    }
    self:BuildConfigSection(fake)
end

return SaveManager
