--[[
    RCLR ThemeManager - Linoria-style
    Usage:
        local ThemeManager = loadstring(game:HttpGet(...))()
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetFolder("RCLR_Prem")
        ThemeManager:ApplyToTab(SettingsTab)
]]

local HttpService = game:GetService("HttpService")

local ThemeManager = {}
ThemeManager.__index = ThemeManager

ThemeManager.Folder = "RCLR_Prem"
ThemeManager.Library = nil
ThemeManager.BuiltIn = {
    ["Default"] = {
        FontColor = Color3.fromRGB(220, 220, 220),
        MainColor = Color3.fromRGB(28, 28, 28),
        BackgroundColor = Color3.fromRGB(18, 18, 18),
        AccentColor = Color3.fromRGB(200, 200, 200),
        OutlineColor = Color3.fromRGB(50, 50, 50),
    },
    ["Black & White"] = {
        FontColor = Color3.fromRGB(240, 240, 240),
        MainColor = Color3.fromRGB(22, 22, 22),
        BackgroundColor = Color3.fromRGB(12, 12, 12),
        AccentColor = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(60, 60, 60),
    },
    ["Dark Blue"] = {
        FontColor = Color3.fromRGB(220, 230, 255),
        MainColor = Color3.fromRGB(20, 24, 36),
        BackgroundColor = Color3.fromRGB(12, 14, 22),
        AccentColor = Color3.fromRGB(80, 140, 255),
        OutlineColor = Color3.fromRGB(40, 50, 70),
    },
    ["Matrix"] = {
        FontColor = Color3.fromRGB(180, 255, 180),
        MainColor = Color3.fromRGB(10, 18, 10),
        BackgroundColor = Color3.fromRGB(5, 10, 5),
        AccentColor = Color3.fromRGB(0, 255, 100),
        OutlineColor = Color3.fromRGB(20, 50, 20),
    },
    ["Blood"] = {
        FontColor = Color3.fromRGB(255, 210, 210),
        MainColor = Color3.fromRGB(28, 12, 12),
        BackgroundColor = Color3.fromRGB(14, 6, 6),
        AccentColor = Color3.fromRGB(220, 40, 40),
        OutlineColor = Color3.fromRGB(70, 25, 25),
    },
    ["Purple"] = {
        FontColor = Color3.fromRGB(235, 220, 255),
        MainColor = Color3.fromRGB(24, 18, 34),
        BackgroundColor = Color3.fromRGB(14, 10, 20),
        AccentColor = Color3.fromRGB(170, 90, 255),
        OutlineColor = Color3.fromRGB(55, 40, 75),
    },
    ["Ocean"] = {
        FontColor = Color3.fromRGB(210, 245, 255),
        MainColor = Color3.fromRGB(14, 28, 36),
        BackgroundColor = Color3.fromRGB(8, 16, 22),
        AccentColor = Color3.fromRGB(40, 190, 220),
        OutlineColor = Color3.fromRGB(30, 55, 70),
    },
    ["Rivals Red"] = {
        FontColor = Color3.fromRGB(245, 245, 245),
        MainColor = Color3.fromRGB(24, 24, 28),
        BackgroundColor = Color3.fromRGB(14, 14, 16),
        AccentColor = Color3.fromRGB(228, 74, 84),
        OutlineColor = Color3.fromRGB(58, 58, 66),
    },
}

local function ensureFolder(path)
    if not isfolder then return end
    pcall(function()
        if not isfolder(path) then makefolder(path) end
    end)
end

local function colorToTable(c)
    if typeof(c) ~= "Color3" then return {1,1,1} end
    return { c.R, c.G, c.B }
end

local function tableToColor(t)
    if type(t) ~= "table" then return Color3.new(1,1,1) end
    return Color3.new(t[1] or 1, t[2] or 1, t[3] or 1)
end

function ThemeManager:SetLibrary(lib)
    self.Library = lib
end

function ThemeManager:SetFolder(name)
    self.Folder = tostring(name or "RCLR_Prem")
    ensureFolder(self.Folder)
    ensureFolder(self.Folder .. "/themes")
end

function ThemeManager:GetThemePath(name)
    return self.Folder .. "/themes/" .. tostring(name) .. ".json"
end

function ThemeManager:ApplyTheme(theme)
    local lib = self.Library
    if not lib or type(theme) ~= "table" then return false end
    pcall(function()
        if theme.FontColor then lib.FontColor = theme.FontColor end
        if theme.MainColor then lib.MainColor = theme.MainColor end
        if theme.BackgroundColor then lib.BackgroundColor = theme.BackgroundColor end
        if theme.AccentColor then
            lib.AccentColor = theme.AccentColor
            if lib.GetDarkerColor then
                lib.AccentColorDark = lib:GetDarkerColor(theme.AccentColor)
            end
        end
        if theme.OutlineColor then lib.OutlineColor = theme.OutlineColor end
        if lib.UpdateColorsUsingRegistry then lib:UpdateColorsUsingRegistry() end
        if lib.SyncStudTheme then lib:SyncStudTheme() end
    end)
    return true
end

function ThemeManager:GetCurrentTheme()
    local lib = self.Library
    if not lib then return {} end
    return {
        FontColor = lib.FontColor,
        MainColor = lib.MainColor,
        BackgroundColor = lib.BackgroundColor,
        AccentColor = lib.AccentColor,
        OutlineColor = lib.OutlineColor,
    }
end

function ThemeManager:SaveTheme(name)
    if type(writefile) ~= "function" then return false, "writefile missing" end
    name = tostring(name or ""):gsub("[^%w%-%_ ]", "")
    if name == "" then return false, "empty name" end
    ensureFolder(self.Folder .. "/themes")
    local theme = self:GetCurrentTheme()
    local data = {
        FontColor = colorToTable(theme.FontColor),
        MainColor = colorToTable(theme.MainColor),
        BackgroundColor = colorToTable(theme.BackgroundColor),
        AccentColor = colorToTable(theme.AccentColor),
        OutlineColor = colorToTable(theme.OutlineColor),
    }
    local ok, enc = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return false, enc end
    local ok2, err = pcall(writefile, self:GetThemePath(name), enc)
    return ok2, err
end

function ThemeManager:LoadTheme(name)
    if type(readfile) ~= "function" then return false, "readfile missing" end
    name = tostring(name or "")
    if self.BuiltIn[name] then
        self:ApplyTheme(self.BuiltIn[name])
        return true
    end
    local path = self:GetThemePath(name)
    local ok, raw = pcall(readfile, path)
    if not ok or type(raw) ~= "string" then return false, "not found" end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or type(data) ~= "table" then return false, data end
    local theme = {
        FontColor = tableToColor(data.FontColor),
        MainColor = tableToColor(data.MainColor),
        BackgroundColor = tableToColor(data.BackgroundColor),
        AccentColor = tableToColor(data.AccentColor),
        OutlineColor = tableToColor(data.OutlineColor),
    }
    self:ApplyTheme(theme)
    return true
end

function ThemeManager:DeleteTheme(name)
    if type(delfile) ~= "function" then return false end
    name = tostring(name or "")
    if self.BuiltIn[name] then return false, "builtin" end
    local ok, err = pcall(delfile, self:GetThemePath(name))
    return ok, err
end

function ThemeManager:GetCustomThemeNames()
    local list = {}
    if type(listfiles) ~= "function" then return list end
    local ok, files = pcall(listfiles, self.Folder .. "/themes")
    if not ok or type(files) ~= "table" then return list end
    for _, f in ipairs(files) do
        local n = tostring(f):match("([^/\\]+)%.json$")
        if n then table.insert(list, n) end
    end
    table.sort(list)
    return list
end

function ThemeManager:GetThemeList()
    local names = {}
    for k in pairs(self.BuiltIn) do table.insert(names, k) end
    table.sort(names)
    for _, n in ipairs(self:GetCustomThemeNames()) do
        if not self.BuiltIn[n] then table.insert(names, n) end
    end
    return names
end

function ThemeManager:SetDefaultTheme(name)
    if type(writefile) ~= "function" then return end
    ensureFolder(self.Folder)
    pcall(writefile, self.Folder .. "/autoload_theme.txt", tostring(name or ""))
end

function ThemeManager:GetDefaultTheme()
    if type(readfile) ~= "function" then return nil end
    local ok, raw = pcall(readfile, self.Folder .. "/autoload_theme.txt")
    if ok and type(raw) == "string" and raw ~= "" then
        return (raw:gsub("%s+$", ""))
    end
    return nil
end

function ThemeManager:TryAutoLoad()
    local name = self:GetDefaultTheme()
    if name and name ~= "" then
        local ok = self:LoadTheme(name)
        if ok and self.Library and self.Library.Notify then
            self.Library:Notify("Theme auto-loaded: " .. name, 3)
        end
        return ok
    end
    return false
end

function ThemeManager:ApplyToTab(tab)
    local lib = self.Library
    if not lib or not tab then return end
    local box = tab:AddLeftGroupbox("Theme Manager")

    local themeNames = self:GetThemeList()
    if #themeNames == 0 then themeNames = { "Default" } end

    box:AddDropdown("TM_ThemeList", {
        Text = "Theme List",
        Values = themeNames,
        Default = 1,
        Callback = function(v)
            -- selection only; load button applies
        end,
    })

    box:AddButton("Load Theme", function()
        local name = (lib.Options and lib.Options.TM_ThemeList and lib.Options.TM_ThemeList.Value)
            or (Options and Options.TM_ThemeList and Options.TM_ThemeList.Value)
        if name then
            local ok = self:LoadTheme(name)
            if lib.Notify then lib:Notify(ok and ("Loaded theme: " .. name) or "Failed to load theme", 3) end
        end
    end)

    box:AddInput("TM_ThemeName", {
        Text = "Theme Name",
        Default = "",
        Placeholder = "my theme",
    })

    box:AddButton("Create / Save Theme", function()
        local name = (lib.Options and lib.Options.TM_ThemeName and lib.Options.TM_ThemeName.Value)
            or (Options and Options.TM_ThemeName and Options.TM_ThemeName.Value)
        if not name or name == "" then
            if lib.Notify then lib:Notify("Enter a theme name", 3) end
            return
        end
        local ok, err = self:SaveTheme(name)
        if lib.Notify then
            lib:Notify(ok and ("Theme saved: " .. name) or ("Save failed: " .. tostring(err)), 3)
        end
        -- refresh list
        local opt = (lib.Options and lib.Options.TM_ThemeList) or (Options and Options.TM_ThemeList)
        if opt and opt.SetValues then
            opt:SetValues(self:GetThemeList())
        end
    end)

    box:AddButton("Delete Theme", function()
        local name = (lib.Options and lib.Options.TM_ThemeList and lib.Options.TM_ThemeList.Value)
            or (Options and Options.TM_ThemeList and Options.TM_ThemeList.Value)
        if not name then return end
        local ok = self:DeleteTheme(name)
        if lib.Notify then lib:Notify(ok and ("Deleted: " .. name) or "Cannot delete (builtin?)", 3) end
        local opt = (lib.Options and lib.Options.TM_ThemeList) or (Options and Options.TM_ThemeList)
        if opt and opt.SetValues then opt:SetValues(self:GetThemeList()) end
    end)

    box:AddButton("Set as Auto-Load Theme", function()
        local name = (lib.Options and lib.Options.TM_ThemeList and lib.Options.TM_ThemeList.Value)
            or (Options and Options.TM_ThemeList and Options.TM_ThemeList.Value)
        if name then
            self:SetDefaultTheme(name)
            if lib.Notify then lib:Notify("Auto-load theme: " .. name, 3) end
        end
    end)

    box:AddButton("Clear Auto-Load Theme", function()
        self:SetDefaultTheme("")
        if lib.Notify then lib:Notify("Auto-load theme cleared", 3) end
    end)

    -- custom colors
    local colors = tab:AddRightGroupbox("Theme Colors")
    local function bindColor(label, key, idx)
        colors:AddLabel(label):AddColorPicker(idx, {
            Default = lib[key] or Color3.new(1,1,1),
            Title = label,
            Callback = function(c)
                lib[key] = c
                if key == "AccentColor" and lib.GetDarkerColor then
                    lib.AccentColorDark = lib:GetDarkerColor(c)
                end
                if lib.UpdateColorsUsingRegistry then lib:UpdateColorsUsingRegistry() end
                if lib.SyncStudTheme then lib:SyncStudTheme() end
            end,
        })
    end
    bindColor("Accent", "AccentColor", "TM_CP_Accent")
    bindColor("Main", "MainColor", "TM_CP_Main")
    bindColor("Background", "BackgroundColor", "TM_CP_BG")
    bindColor("Outline", "OutlineColor", "TM_CP_Outline")
    bindColor("Font", "FontColor", "TM_CP_Font")
end

function ThemeManager:ApplyToGroupbox(box)
    -- fallback: treat as tab-like with only left
    if not box then return end
    local fake = {
        AddLeftGroupbox = function(_, n) return box end,
        AddRightGroupbox = function(_, n) return box end,
    }
    self:ApplyToTab(fake)
end

return ThemeManager
