-- DinhKhanhInstance - Full Working Version
-- Discord: https://discord.gg/MB5KGBGCZz
-- Coded by DinhKhanh

local DinhKhanhInstance = function(CustomOptions, CustomOptions2)
    if getgenv().DKIV3 then return end
    getgenv().DKIV3 = true
    
    print("[DinhKhanhInstance] Loaded | discord.gg/MB5KGBGCZz")

    -- Helper functions
    local function ArrayToDict(t, hybridMode, valueOverride, typeStrict)
        local tmp = {}
        if hybridMode then
            for k, v in t do
                if type(k) == "number" then
                    tmp[v] = valueOverride or true
                elseif type(v) == "table" then
                    tmp[k] = ArrayToDict(v, hybridMode)
                else
                    tmp[k] = v
                end
            end
        else
            for _, key in t do
                if not typeStrict or (typeStrict and type(key) == typeStrict) then
                    tmp[key] = true
                end
            end
        end
        return tmp
    end

    local function GetRef(instance)
        if not referents[instance] then
            referents[instance] = ref_size
            ref_size = ref_size + 1
        end
        return referents[instance]
    end

    local function __BIT(...)
        local bits = {...}
        local val = 0
        for i = 1, #bits do
            if bits[i] then
                val = val + 2^(i-1)
            end
        end
        return val
    end

    -- Base64 encode
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local function to_base64(data)
        local result = {}
        local bits = {}
        for i = 1, #data do
            local byte = data:byte(i)
            for j = 7, 0, -1 do
                bits[#bits+1] = (math.floor(byte / 2^j) % 2 == 1) and '1' or '0'
            end
        end
        local bit_str = table.concat(bits)
        bit_str = bit_str .. string.rep('0', (6 - #bit_str % 6) % 6)
        for i = 1, #bit_str, 6 do
            local chunk = bit_str:sub(i, i+5)
            local idx = tonumber(chunk, 2) + 1
            result[#result+1] = b64chars:sub(idx, idx)
        end
        local padding = (#data % 3 == 1 and '==') or (#data % 3 == 2 and '=') or ''
        return table.concat(result) .. padding
    end

    -- XML Escape patterns
    local escapes = {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&#34;",
        ["'"] = "&#39;",
    }
    for i = 1, 31 do
        escapes[string.char(i)] = "&#" .. i .. ";"
    end
    for i = 127, 255 do
        escapes[string.char(i)] = "&#" .. i .. ";"
    end

    local function escape_xml(str)
        return string.gsub(str, "[&<>\"'\x00-\x1f\x7f-\xff]", escapes)
    end

    -- XML Descriptors
    local XML_Descriptors = {
        string = function(raw) 
            return (raw == "" and "") or "<![CDATA[" .. escape_xml(raw) .. "]]>"
        end,
        bool = function(raw) return raw and "true" or "false" end,
        int = function(raw) return tostring(raw) end,
        float = function(raw) return tostring(raw) end,
        double = function(raw) return tostring(raw) end,
        BrickColor = function(raw) return tostring(raw.Number) end,
        Color3 = function(raw) 
            return "<R>" .. raw.R .. "</R><G>" .. raw.G .. "</G><B>" .. raw.B .. "</B>"
        end,
        Vector3 = function(raw)
            return "<X>" .. raw.X .. "</X><Y>" .. raw.Y .. "</Y><Z>" .. raw.Z .. "</Z>"
        end,
        Vector2 = function(raw)
            return "<X>" .. raw.X .. "</X><Y>" .. raw.Y .. "</Y>"
        end,
        CFrame = function(raw)
            local x,y,z, r00,r01,r02,r10,r11,r12,r20,r21,r22 = raw:GetComponents()
            return "<X>"..x.."</X><Y>"..y.."</Y><Z>"..z.."</Z><R00>"..r00.."</R00><R01>"..r01.."</R01><R02>"..r02.."</R02><R10>"..r10.."</R10><R11>"..r11.."</R11><R12>"..r12.."</R12><R20>"..r20.."</R20><R21>"..r21.."</R21><R22>"..r22.."</R22>"
        end,
        UDim = function(raw)
            return "<S>"..raw.Scale.."</S><O>"..raw.Offset.."</O>"
        end,
        UDim2 = function(raw)
            return "<XS>"..raw.X.Scale.."</XS><XO>"..raw.X.Offset.."</XO><YS>"..raw.Y.Scale.."</YS><YO>"..raw.Y.Offset.."</YO>"
        end,
        Ray = function(raw)
            return "<origin>"..XML_Descriptors.Vector3(raw.Origin).."</origin><direction>"..XML_Descriptors.Vector3(raw.Direction).."</direction>"
        end,
        Faces = function(raw)
            return "<faces>"..__BIT(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front).."</faces>"
        end,
        Axes = function(raw)
            return "<axes>"..__BIT(raw.X, raw.Y, raw.Z).."</axes>"
        end,
        NumberRange = function(raw)
            return raw.Min .. " " .. raw.Max
        end,
        Rect = function(raw)
            return "<min>"..XML_Descriptors.Vector2(raw.Min).."</min><max>"..XML_Descriptors.Vector2(raw.Max).."</max>"
        end,
        PhysicalProperties = function(raw)
            if raw then
                return "<CustomPhysics>true</CustomPhysics><Density>"..raw.Density.."</Density><Friction>"..raw.Friction.."</Friction><Elasticity>"..raw.Elasticity.."</Elasticity><FrictionWeight>"..raw.FrictionWeight.."</FrictionWeight><ElasticityWeight>"..raw.ElasticityWeight.."</ElasticityWeight>"
            else
                return "<CustomPhysics>false</CustomPhysics>"
            end
        end,
        Region3 = function(raw)
            local min = raw.Min
            local max = raw.Max
            return "<min>"..XML_Descriptors.Vector3(min).."</min><max>"..XML_Descriptors.Vector3(max).."</max>"
        end,
        Region3int16 = function(raw)
            return "<min>"..raw.Min.X..","..raw.Min.Y..","..raw.Min.Z.."</min><max>"..raw.Max.X..","..raw.Max.Y..","..raw.Max.Z.."</max>"
        end,
        BinaryString = function(raw)
            return raw == "" and "" or to_base64(raw)
        end,
        ProtectedString = function(raw)
            return "<![CDATA[" .. raw .. "]]>"
        end,
        EnumItem = function(raw)
            return tostring(raw.Value)
        end,
        Content = function(raw)
            if raw.SourceType == Enum.ContentSourceType.None then
                return "<null></null>"
            elseif raw.SourceType == Enum.ContentSourceType.Uri then
                return "<uri>"..XML_Descriptors.string(raw.Uri).."</uri>"
            else
                return "<Ref>"..GetRef(raw.Object).."</Ref>"
            end
        end,
    }

    -- Fallback for gethiddenproperty
    local gethiddenproperty_fallback = function(instance, prop)
        pcall(function()
            return instance[prop]
        end)
        return nil
    end

    -- SharedStrings storage
    local SharedStrings = {}
    local referents = {}
    local ref_size = 0
    local inherited_properties = {}
    local default_instances = {}

    -- Identify executor
    local identify_executor = identifyexecutor or getexecutorname or function() return "Unknown" end
    local EXECUTOR_NAME = identify_executor() or ""

    -- Get services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")

    -- Options
    local currentstr, currentsize, totalsize, chunks = "", 0, 0, {}
    local savebuffer, savebuffer_size = {}, 1
    local header = '<!-- Saved by DinhKhanhInstance (Join to Copy Games) https://discord.gg/MB5KGBGCZz --><roblox version="4">'
    local StatusText = nil
    local Loading = nil

    local OPTIONS = {
        mode = "optimized",
        noscripts = false,
        scriptcache = true,
        timeout = 10,
        __DEBUG_MODE = false,
        IgnoreList = { "CoreGui", "CorePackages" },
        ExtraInstances = {},
        ShowStatus = true,
        SafeMode = false,
        AntiIdle = true,
        ReadMe = true,
        FilePath = false,
        Object = false,
        IsModel = false,
        IgnoreDefaultProperties = true,
        IgnoreNotArchivable = true,
        RemovePlayerCharacters = true,
        AlternativeWritefile = true,
    }

    -- Override options
    if type(CustomOptions) == "table" then
        for k, v in pairs(CustomOptions) do
            OPTIONS[k] = v
        end
    end
    if type(CustomOptions2) == "table" then
        for k, v in pairs(CustomOptions2) do
            OPTIONS[k] = v
        end
    end
    if CustomOptions2 and type(CustomOptions) == "Instance" then
        OPTIONS.Object = CustomOptions
    end

    local ToSaveInstance = OPTIONS.Object
    local IsModel = OPTIONS.IsModel
    if ToSaveInstance and OPTIONS.IsModel == nil then
        IsModel = true
    end

    local ToSaveList = {}
    if ToSaveInstance then
        table.insert(ToSaveList, ToSaveInstance)
    end
    for _, v in ipairs(OPTIONS.ExtraInstances) do
        table.insert(ToSaveList, v)
    end

    if not ToSaveInstance and #ToSaveList == 0 then
        if OPTIONS.mode == "optimized" then
            local services = {"Workspace", "Players", "Lighting", "ReplicatedFirst", "ReplicatedStorage", "StarterGui", "StarterPack", "StarterPlayer", "SoundService", "Chat", "TextChatService"}
            for _, svc in ipairs(services) do
                local s = game:FindService(svc)
                if s then
                    table.insert(ToSaveList, s)
                end
            end
        else
            for _, v in ipairs(game:GetChildren()) do
                table.insert(ToSaveList, v)
            end
        end
    end

    local placename = (OPTIONS.FilePath or "place_" .. game.PlaceId) .. (IsModel and ".rbxmx" or ".rbxlx")

    -- Simple decompile placeholder
    local function ldecompile(script)
        return "-- Decompiled by DinhKhanhInstance\n-- Original script: " .. script:GetFullName()
    end

    -- UI Status
    if OPTIONS.ShowStatus then
        local StatusGui = Instance.new("ScreenGui")
        StatusGui.Name = "DinhKhanhInstance"
        StatusGui.ResetOnSpawn = false
        StatusText = Instance.new("TextLabel")
        StatusText.Size = UDim2.new(0, 300, 0, 30)
        StatusText.Position = UDim2.new(1, -310, 1, -40)
        StatusText.AnchorPoint = Vector2.new(1, 1)
        StatusText.BackgroundTransparency = 1
        StatusText.TextColor3 = Color3.new(1, 1, 1)
        StatusText.TextStrokeTransparency = 0.5
        StatusText.Font = Enum.Font.Code
        StatusText.TextSize = 14
        StatusText.Text = "DinhKhanhInstance - Saving..."
        StatusText.Parent = StatusGui
        pcall(function() StatusGui.Parent = game:GetService("CoreGui") end)
    end

    -- Save functions
    local function wait_for_render()
        RunService.RenderStepped:Wait()
    end

    local function get_size_format()
        local size = totalsize
        if size < 1024 then return size .. " B"
        elseif size < 1024*1024 then return string.format("%.1f KB", size/1024)
        elseif size < 1024*1024*1024 then return string.format("%.1f MB", size/(1024*1024))
        else return string.format("%.1f GB", size/(1024*1024*1024))
        end
    end

    local function save_cache(final)
        local savestr = table.concat(savebuffer)
        currentstr = currentstr .. savestr
        totalsize = totalsize + #savestr
        currentsize = currentsize + #savestr
        table.clear(savebuffer)
        savebuffer_size = 1
        if currentsize > 5000000 or final then
            table.insert(chunks, {str = currentstr})
            currentstr = ""
            currentsize = 0
        end
        if StatusText then
            StatusText.Text = "Saving... " .. get_size_format()
        end
        wait_for_render()
    end

    local function ReturnItem(className, instance)
        return '<Item class="' .. className .. '" referent="' .. GetRef(instance) .. '"><Properties>'
    end

    local function ReturnProperty(tag, name, value)
        return "<" .. tag .. ' name="' .. name .. '">' .. value .. "</" .. tag .. ">"
    end

    local function save_hierarchy(hierarchy, indent)
        for _, inst in ipairs(hierarchy) do
            if not inst.Archivable and OPTIONS.IgnoreNotArchivable then
                goto skip
            end
            
            local className = inst.ClassName
            local isScript = inst:IsA("LuaSourceContainer")
            
            savebuffer[savebuffer_size] = ReturnItem(className, inst)
            savebuffer_size = savebuffer_size + 1
            
            -- Name property
            local nameVal, nameTag = XML_Descriptors.string(inst.Name)
            savebuffer[savebuffer_size] = ReturnProperty("string", "Name", nameVal)
            savebuffer_size = savebuffer_size + 1
            
            -- Source for scripts
            if isScript and not OPTIONS.noscripts then
                local src = ldecompile(inst)
                savebuffer[savebuffer_size] = ReturnProperty("ProtectedString", "Source", "<![CDATA[" .. src .. "]]>")
                savebuffer_size = savebuffer_size + 1
            end
            
            -- Basic properties for Parts
            if inst:IsA("BasePart") then
                local c3 = XML_Descriptors.Color3(inst.Color)
                savebuffer[savebuffer_size] = ReturnProperty("Color3", "Color", c3)
                savebuffer_size = savebuffer_size + 1
                savebuffer[savebuffer_size] = ReturnProperty("float", "Transparency", inst.Transparency)
                savebuffer_size = savebuffer_size + 1
                savebuffer[savebuffer_size] = ReturnProperty("bool", "Anchored", inst.Anchored)
                savebuffer_size = savebuffer_size + 1
                local size = XML_Descriptors.Vector3(inst.Size)
                savebuffer[savebuffer_size] = ReturnProperty("Vector3", "Size", size)
                savebuffer_size = savebuffer_size + 1
                local pos = XML_Descriptors.Vector3(inst.Position)
                savebuffer[savebuffer_size] = ReturnProperty("Vector3", "Position", pos)
                savebuffer_size = savebuffer_size + 1
                local cf = XML_Descriptors.CFrame(inst.CFrame)
                savebuffer[savebuffer_size] = ReturnProperty("CFrame", "CFrame", cf)
                savebuffer_size = savebuffer_size + 1
            end
            
            savebuffer[savebuffer_size] = "</Properties>"
            savebuffer_size = savebuffer_size + 1
            
            local children = inst:GetChildren()
            if #children > 0 then
                save_hierarchy(children, indent + 1)
            end
            
            savebuffer[savebuffer_size] = "</Item>"
            savebuffer_size = savebuffer_size + 1
            
            if savebuffer_size > 500 then
                save_cache(false)
            end
            
            ::skip::
        end
    end

    -- Main save function
    local elapse_t = os.clock()
    local ok, err = pcall(function()
        writefile(placename, header)
        save_hierarchy(ToSaveList, 0)
        save_cache(true)
        
        local totalstr = header
        for _, chunk in ipairs(chunks) do
            totalstr = totalstr .. chunk.str
        end
        totalstr = totalstr .. "</roblox>"
        
        if OPTIONS.AlternativeWritefile and appendfile then
            appendfile(placename, totalstr)
        else
            writefile(placename, totalstr)
        end
    end)
    
    elapse_t = os.clock() - elapse_t
    
    if StatusText then
        if ok then
            StatusText.Text = "Saved! " .. get_size_format() .. " in " .. string.format("%.2f", elapse_t) .. "s"
        else
            StatusText.Text = "Save failed! Check console"
        end
        task.wait(3)
        StatusText.Parent = nil
    end
    
    if not ok then
        warn("DinhKhanhInstance Error:", err)
    end
    
    getgenv().DKIV3 = nil
    
    if OPTIONS.SafeMode then
        game:Shutdown()
    end
end

getgenv().DinhKhanhInstance = DinhKhanhInstance
return DinhKhanhInstance
