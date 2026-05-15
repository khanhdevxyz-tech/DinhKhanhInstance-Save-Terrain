--[[
    DinhKhanhInstance - Premium Game Copier
    Version 3.0 | Coded by DinhKhanh
    Join Discord: https://discord.gg/MB5KGBGCZz
    Telegram: @DinhKhanh
]]

local DinhKhanhInstance = function(CustomOptions, CustomOptions2)
    if getgenv().DKIV3 then
        return
    end
    getgenv().DKIV3 = true

    -- Branding
    print("[DinhKhanhInstance] Premium Game Copier Loaded")
    print("[DinhKhanhInstance] Discord: https://discord.gg/MB5KGBGCZz")

    local currentstr, currentsize, totalsize, chunks = "", 0, 0, table.create(1)
    local savebuffer, savebuffer_size = {}, 1
    local header = '<!-- Saved by DinhKhanhInstance (Join to Copy Games) https://discord.gg/MB5KGBGCZz --><roblox version="4">'

    local StatusText

    local OPTIONS = {
        mode = "optimized",
        noscripts = false,
        scriptcache = true,
        timeout = 10,
        __DEBUG_MODE = false,
        Callback = false,
        DecompileJobless = false,
        SaveBytecode = false,
        IgnoreProperties = {},
        IgnoreList = { "CoreGui", "CorePackages" },
        ExtraInstances = {},
        NilInstances = false,
        SaveCacheInterval = 0x1600 * 10,
        ShowStatus = true,
        SafeMode = false,
        ShutdownWhenDone = false,
        AntiIdle = true,
        Anonymous = false,
        ReadMe = true,
        FilePath = false,
        Object = false,
        IsModel = false,
        IgnoreDefaultProperties = true,
        IgnoreNotArchivable = true,
        IgnorePropertiesOfNotScriptsOnScriptsMode = false,
        IgnoreSpecialProperties = false,
        IsolateLocalPlayer = false,
        IsolateLocalPlayerCharacter = false,
        IsolatePlayers = false,
        IsolateStarterPlayer = false,
        RemovePlayerCharacters = true,
        SaveNotCreatable = false,
        NotCreatableFixes = {
            "",
            "AnimationTrack",
            "Player",
            "PlayerGui",
            "PlayerScripts",
            "PlayerMouse",
            "ScreenshotHud",
            "StudioData",
            "TextSource",
            "TouchTransmitter",
        },
        IgnoreSharedStrings = false,
        SharedStringOverwrite = false,
        TreatUnionsAsParts = false,
        AlternativeWritefile = true,
        OptionsAliases = {
            DecompileTimeout = "timeout",
            FileName = "FilePath",
            IgnoreArchivable = "IgnoreNotArchivable",
            IgnoreDefaultProps = "IgnoreDefaultProperties",
            SaveNonCreatable = "SaveNotCreatable",
            SavePlayers = "IsolatePlayers",
        },
    }

    local OPTIONS_lowercase, CustomOptions_valid = {}, {}
    for option_name in OPTIONS do
        local option_name_lowercase = string.lower(option_name)
        if OPTIONS_lowercase[option_name_lowercase] then
            warn("DUPLICATE OPTION", option_name)
        else
            OPTIONS_lowercase[option_name_lowercase] = option_name
        end
    end
    for option_alias, option_name in OPTIONS.OptionsAliases do
        local option_name_lowercase = string.lower(option_alias)
        if OPTIONS_lowercase[option_name_lowercase] then
            warn("DUPLICATE ALIAS", option_alias)
        else
            OPTIONS_lowercase[option_name_lowercase] = option_name
        end
    end

    -- Load Settings
    do
        local function construct_NilinstanceFix(Name, ClassName, Separate)
            return function(instance, instancePropertyOverrides)
                local Exists
                if not Separate then
                    Exists = OPTIONS.NilInstancesFixes[Name]
                end
                local Fix
                local DoesntExist = not Exists
                if DoesntExist then
                    Fix = Instance.new(ClassName)
                    if not Separate then
                        OPTIONS.NilInstancesFixes[Name] = Fix
                    end
                    instancePropertyOverrides[Fix] = { __SaveSpecific = true, __Children = { instance }, Properties = { Name = Name } }
                else
                    Fix = Exists
                    table.insert(instancePropertyOverrides[Fix].__Children, instance)
                end
                if DoesntExist then
                    return Fix
                end
            end
        end

        OPTIONS.NilInstancesFixes = {}
        OPTIONS.NilInstancesFixes.Animator = construct_NilinstanceFix("Animator has to be placed under Humanoid or AnimationController", "AnimationController")
        OPTIONS.NilInstancesFixes.AdPortal = construct_NilinstanceFix("AdPortal must be parented to a Part", "Part")
        OPTIONS.NilInstancesFixes.Attachment = construct_NilinstanceFix("Attachments must be parented to a BasePart or another Attachment", "Part")
        OPTIONS.NilInstancesFixes.BaseWrap = construct_NilinstanceFix("BaseWrap must be parented to a MeshPart", "MeshPart")
        OPTIONS.NilInstancesFixes.PackageLink = construct_NilinstanceFix("Package already has a PackageLink", "Folder", true)

        if CustomOptions2 and type(CustomOptions2) == "table" then
            local tmp = CustomOptions
            local Type = typeof(tmp)
            CustomOptions = CustomOptions2
            if Type == "Instance" then
                CustomOptions.Object = tmp
            elseif Type == "table" and typeof(tmp[1]) == "Instance" then
                CustomOptions.ExtraInstances = tmp
                OPTIONS.IsModel = true
            end
        end

        local Type = typeof(CustomOptions)
        if Type == "table" then
            if typeof(CustomOptions[1]) == "Instance" then
                OPTIONS.mode = "invalidmode"
                OPTIONS.ExtraInstances = CustomOptions
                OPTIONS.IsModel = true
                CustomOptions = {}
            else
                for key, value in CustomOptions do
                    local option = OPTIONS_lowercase[string.lower(key)]
                    if option then
                        OPTIONS[option] = value
                        CustomOptions_valid[option] = true
                    end
                end
                local Decompile = CustomOptions.Decompile
                if Decompile ~= nil then
                    OPTIONS.noscripts = not Decompile
                end
                local SavePlayerCharacters = CustomOptions.SavePlayerCharacters
                if SavePlayerCharacters ~= nil then
                    OPTIONS.RemovePlayerCharacters = not SavePlayerCharacters
                end
                local RemovePlayers = CustomOptions.RemovePlayers
                if RemovePlayers ~= nil then
                    OPTIONS.IsolatePlayers = not RemovePlayers
                end
            end
        elseif Type == "Instance" then
            OPTIONS.mode = "invalidmode"
            OPTIONS.Object = CustomOptions
            CustomOptions = {}
        else
            CustomOptions = {}
        end
    end

    if OPTIONS.IgnoreDefaultPlayerScripts then
        local DecompileIgnore = OPTIONS.DecompileIgnore
        local Path = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
        local Exclude = { ModuleScript = { "PlayerModule" }, LocalScript = { "RbxCharacterSounds" } }
        if Path then
            for _, className in Exclude do
                for _, name in className do
                    local Found = Path:FindFirstChild(name)
                    if Found then
                        table.insert(DecompileIgnore, Found)
                    end
                end
            end
        end
    end

    local InstancesOverrides = {}
    local DecompileIgnore, IgnoreList, IgnoreProperties, NotCreatableFixes = 
        ArrayToDict(OPTIONS.DecompileIgnore, true),
        ArrayToDict(OPTIONS.IgnoreList, true),
        ArrayToDict(OPTIONS.IgnoreProperties),
        ArrayToDict(OPTIONS.NotCreatableFixes, true, "Folder")

    local __DEBUG_MODE = OPTIONS.__DEBUG_MODE
    if __DEBUG_MODE and type(__DEBUG_MODE) ~= "function" then
        __DEBUG_MODE = warn
    end

    local FilePath = OPTIONS.FilePath
    local SaveCacheInterval = OPTIONS.SaveCacheInterval
    local ToSaveInstance = OPTIONS.Object
    local IsModel = OPTIONS.IsModel

    if ToSaveInstance and CustomOptions.IsModel == nil then
        IsModel = true
    end

    local IgnoreDefaultProperties = OPTIONS.IgnoreDefaultProperties
    local IgnoreNotArchivable = not OPTIONS.IgnoreNotArchivable
    local IgnorePropertiesOfNotScriptsOnScriptsMode = OPTIONS.IgnorePropertiesOfNotScriptsOnScriptsMode

    local old_gethiddenproperty
    local gethiddenproperty = gethiddenproperty
    if OPTIONS and gethiddenproperty then
        old_gethiddenproperty = gethiddenproperty
        gethiddenproperty = nil
    end

    local SaveNotCreatable = OPTIONS.SaveNotCreatable
    local TreatUnionsAsParts = OPTIONS.TreatUnionsAsParts

    local DecompileJobless = OPTIONS.DecompileJobless
    if DecompileJobless then
        OPTIONS.scriptcache = true
    end
    local ScriptCache = OPTIONS.scriptcache and getscriptbytecode

    local Timeout = OPTIONS.timeout

    local IgnoreSharedStrings = OPTIONS.IgnoreSharedStrings
    local SharedStringOverwrite = OPTIONS.SharedStringOverwrite

    local ldeccache = getgenv().scriptcache
    local DecompileIgnoring, ToSaveList, ldecompile, placename, elapse_t, SaveNotCreatableWillBeEnabled, RecoveredScripts

    if OPTIONS.ReadMe then
        RecoveredScripts = {}
    end

    if ScriptCache and not ldeccache then
        ldeccache = {}
        getgenv().scriptcache = ldeccache
    end

    if ToSaveInstance == game then
        OPTIONS.mode = "full"
        ToSaveInstance = nil
        IsModel = nil
    end

    local function isLuaSourceContainer(instance)
        return instance:IsA("LuaSourceContainer")
    end

    do
        local mode = string.lower(OPTIONS.mode)
        local tmp = table.clone(OPTIONS.ExtraInstances)

        local PlaceName = game.PlaceId
        pcall(function()
            PlaceName = PlaceName .. " " .. game:GetService("MarketplaceService"):GetProductInfo(PlaceName).Name
        end)

        local function sanitizeFileName(str)
            return string.sub(string.gsub(string.gsub(string.gsub(str, "[^%w _]", ""), " +", " "), " +$", ""), 1, 240)
        end

        if ToSaveInstance then
            if mode == "optimized" then
                mode = "full"
            end
            for _, key in { "IsolateLocalPlayer", "IsolateLocalPlayerCharacter", "IsolatePlayers", "IsolateStarterPlayer", "NilInstances" } do
                if CustomOptions_valid[key] == nil then
                    OPTIONS[key] = false
                end
            end
        end

        if IsModel then
            placename = (FilePath or sanitizeFileName("model " .. PlaceName .. " " .. (ToSaveInstance or tmp[1] or game):GetFullName())) .. ".rbxmx"
        else
            placename = (FilePath or sanitizeFileName("place " .. PlaceName)) .. ".rbxlx"
        end

        if getgenv()[placename] then
            return
        end
        getgenv()[placename] = true
        getgenv().DKIV3 = nil

        if mode ~= "scripts" then
            IgnorePropertiesOfNotScriptsOnScriptsMode = nil
        end

        local TempRoot = ToSaveInstance or game

        if mode == "full" then
            if not ToSaveInstance then
                local Children = TempRoot:GetChildren()
                if 0 < #Children then
                    local tmp_dict = ArrayToDict(tmp)
                    for _, child in Children do
                        if not tmp_dict[child] then
                            table.insert(tmp, child)
                        end
                    end
                end
            end
        elseif mode == "optimized" then
            local tmp_dict = ArrayToDict(tmp)
            for _, serviceName in { "Workspace", "Players", "Lighting", "MaterialService", "ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer", "Teams", "SoundService", "Chat", "TextChatService", "LocalizationService", "JointsService" } do
                local _service = game:FindService(serviceName)
                if _service and not tmp_dict[_service] then
                    table.insert(tmp, _service)
                end
            end
        elseif mode == "scripts" then
            local unique = {}
            for _, instance in TempRoot:GetDescendants() do
                if isLuaSourceContainer(instance) then
                    local Parent = instance.Parent
                    while Parent and Parent ~= TempRoot do
                        instance = instance.Parent
                        Parent = instance.Parent
                    end
                    if Parent then
                        unique[instance] = true
                    end
                end
            end
            for instance in unique do
                table.insert(tmp, instance)
            end
        end

        ToSaveList = tmp
        if ToSaveInstance then
            table.insert(ToSaveList, 1, ToSaveInstance)
        end
    end

    local IsolateLocalPlayer = OPTIONS.IsolateLocalPlayer
    local IsolateLocalPlayerCharacter = OPTIONS.IsolateLocalPlayerCharacter
    local IsolatePlayers = OPTIONS.IsolatePlayers
    local IsolateStarterPlayer = OPTIONS.IsolateStarterPlayer
    local NilInstances = OPTIONS.NilInstances

    if NilInstances and enablenilinstances then
        enablenilinstances()
    end

    local function get_size_format()
        local Size
        for i, unit in { "B", "KB", "MB", "GB", "TB" } do
            if totalsize < 0x400 ^ i then
                Size = math.floor(totalsize / (0x400 ^ (i - 1)) * 10) / 10 .. " " .. unit
                break
            end
        end
        return Size
    end

    local RunService = game:GetService("RunService")
    local function wait_for_render()
        RunService.RenderStepped:Wait()
    end

    local Loading
    local function run_with_loading(text, keepStatus, waitForRender, taskFunction, ...)
        local previousStatus
        if StatusText then
            if keepStatus then
                previousStatus = StatusText.Text
            end
            Loading = task.spawn(function()
                local spinner_count = 0
                local chars = { "|", "/", "—", "\\" }
                local chars_size = #chars
                local function getLoadingText()
                    spinner_count = spinner_count + 1
                    if chars_size < spinner_count then
                        spinner_count = 1
                    end
                    return chars[spinner_count]
                end
                text = text .. " "
                while true do
                    StatusText.Text = text .. getLoadingText()
                    task.wait(0.25)
                end
            end)
            if waitForRender then
                wait_for_render()
            end
        end
        local result = { taskFunction(...) }
        if Loading then
            task.cancel(Loading)
            Loading = nil
            if previousStatus then
                StatusText.Text = previousStatus
            end
        end
        return unpack(result)
    end

    local function construct_TimeoutHandler(timeout, f, timeout_ret)
        return timeout < 0 and function(script)
            return pcall(f, script)
        end or function(script)
            local thread = coroutine.running()
            local timeoutThread, isCancelled
            timeoutThread = task.delay(timeout, function()
                isCancelled = true
                coroutine.resume(thread, nil, timeout_ret)
            end)
            task.spawn(function()
                local ok, result = pcall(f, script)
                if isCancelled then
                    return
                end
                task.cancel(timeoutThread)
                while coroutine.status(thread) ~= "suspended" do
                    task.wait()
                end
                coroutine.resume(thread, ok, result)
            end)
            return coroutine.yield()
        end
    end

    local getbytecode
    if getscriptbytecode then
        getbytecode = construct_TimeoutHandler(3, getscriptbytecode)
    end

    local SaveBytecode
    if OPTIONS.SaveBytecode and getscriptbytecode then
        SaveBytecode = function(script)
            local s, bytecode = getbytecode(script)
            if s and bytecode and bytecode ~= "" then
                return "-- Bytecode (Base64):\n-- " .. base64encode(bytecode) .. "\n\n"
            end
        end
    end

    do
        local Decompiler = decompile
        if OPTIONS.noscripts then
            ldecompile = function()
                return "-- Decompiling is disabled"
            end
        elseif Decompiler then
            local decomp = construct_TimeoutHandler(Timeout, Decompiler, "Decompiler timed out")
            ldecompile = function(script)
                local hashed_bytecode
                if ScriptCache then
                    local s, bytecode = getbytecode(script)
                    local cached
                    if s then
                        if not bytecode or bytecode == "" then
                            return "-- The Script is Empty"
                        end
                        hashed_bytecode = sha384(bytecode)
                        cached = ldeccache[hashed_bytecode]
                    end
                    if cached then
                        if __DEBUG_MODE then
                            __DEBUG_MODE("Found in Cache", script:GetFullName())
                        end
                        return cached
                    end
                else
                    if DecompileJobless then
                        return "-- Not found in already decompiled ScriptCache"
                    end
                    task.wait()
                end
                local ok, result = run_with_loading("Decompiling " .. script.Name, true, nil, decomp, script)
                if not result then
                    ok, result = false, "Empty Output"
                end
                local output
                if ok then
                    result = string.gsub(result, "\0", "\\0")
                    output = result
                else
                    output = "--[[ Failed to decompile. Reason:\n" .. (result or "") .. "\n]]"
                end
                if ScriptCache and hashed_bytecode then
                    ldeccache[hashed_bytecode] = output
                    if __DEBUG_MODE then
                        __DEBUG_MODE("Cached", script:GetFullName())
                    end
                end
                return output
            end
        else
            ldecompile = function()
                return "-- Your Executor does NOT have a Decompiler"
            end
        end
    end

    local function GetLocalPlayer()
        return game:GetService("Players").LocalPlayer or game:GetService("Players"):GetPropertyChangedSignal("LocalPlayer"):Wait() or game:GetService("Players").LocalPlayer
    end

    local function filterLinkedSource(str)
        local o, r = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), str)
        if o and r.errors then
            return
        end
        return true
    end

    local function replaceClassName(instance, InstanceName, ClassName)
        local InstanceOverride
        if InstanceName ~= ClassName then
            InstanceOverride = InstancesOverrides[instance]
            if not InstanceOverride then
                InstanceOverride = { Properties = { Name = "[" .. ClassName .. "] " .. InstanceName } }
                InstancesOverrides[instance] = InstanceOverride
            end
        end
        return InstanceOverride
    end

    local function filterPropVal(result, propertyName, category)
        return result == nil or result == "can't get value" or type(result) == "string" and (category == "Enum" or string_find(result, "Unable to get property " .. propertyName))
    end

    local __BREAK = "__BREAK" .. game:GetService("HttpService"):GenerateGUID(false)

    local function ReadProperty(instance, property, propertyName, special, category, optional)
        local raw = __BREAK
        local InstanceOverride = InstancesOverrides[instance]
        if InstanceOverride then
            local PropertiesOverride = InstanceOverride.Properties
            if PropertiesOverride then
                local PropertyOverride = PropertiesOverride[propertyName]
                if PropertyOverride ~= nil then
                    return PropertyOverride
                end
            end
        end
        local CanRead = property.CanRead
        if CanRead == false then
            return __BREAK
        end
        if special then
            if gethiddenproperty then
                local ok, result = pcall(gethiddenproperty, instance, propertyName)
                if ok then
                    raw = result
                end
                if filterPropVal(raw, propertyName, category) then
                    if result ~= nil or not optional then
                        if __DEBUG_MODE then
                            __DEBUG_MODE("Filtered", propertyName)
                        end
                        property.CanRead = false
                    end
                    return __BREAK
                end
            end
        else
            if CanRead then
                raw = instance[propertyName]
            else
                local ok, result = pcall(function() return instance[propertyName] end)
                if ok then
                    raw = result
                elseif gethiddenproperty then
                    ok, result = pcall(gethiddenproperty, instance, propertyName)
                    if ok then
                        raw = result
                        property.Special = true
                    end
                end
                property.CanRead = ok
                if not ok or filterPropVal(raw, propertyName, category) then
                    return __BREAK
                end
            end
        end
        return raw
    end

    local function ReturnItem(className, instance)
        return '<Item class="' .. className .. '" referent="' .. GetRef(instance) .. '"><Properties>'
    end

    local function ReturnProperty(tag, propertyName, value)
        return "<" .. tag .. ' name="' .. propertyName .. '">' .. value .. "</" .. tag .. ">"
    end

    local function ReturnValueAndTag(raw, valueType, descriptor)
        local value, tag = (descriptor or XML_Descriptors[valueType])(raw)
        return value, tag or valueType
    end

    local function InheritsFix(fixes, className, instance)
        local Fix = fixes[className]
        if Fix then
            return Fix
        elseif Fix == nil then
            for class_name, fix in fixes do
                if instance:IsA(class_name) then
                    return fix
                end
            end
        end
    end

    local function GetInheritedProps(className)
        local prop_list = {}
        local layer = ClassList[className]
        while layer do
            local layer_props = layer.Properties
            table.move(layer_props, 1, #layer_props, #prop_list + 1, prop_list)
            layer = ClassList[layer.Superclass]
        end
        inherited_properties[className] = prop_list
        return prop_list
    end

    local CHUNK_LIMIT = 200 * 1024 * 1024
    local function save_cache(final)
        local savestr = table.concat(savebuffer)
        currentstr = currentstr .. savestr
        local savestr_len = #savestr
        totalsize = totalsize + savestr_len
        currentsize = currentsize + savestr_len
        table.clear(savebuffer)
        savebuffer_size = 1
        if CHUNK_LIMIT < currentsize or final then
            table.insert(chunks, { size = currentsize, str = currentstr })
            currentstr, currentsize = "", 0
        end
        if StatusText then
            StatusText.Text = "Saving.. Size: " .. get_size_format()
        end
        wait_for_render()
    end

    local function save_specific(className, properties)
        local Ref = Instance.new(className)
        local Item = ReturnItem(Ref.ClassName, Ref)
        for propertyName, val in properties do
            local whitelisted, value, tag
            if "Source" == propertyName then
                tag = "ProtectedString"
                value = XML_Descriptors.__PROTECTEDSTRING(val)
                whitelisted = true
            elseif "Name" == propertyName then
                whitelisted = true
                value, tag = ReturnValueAndTag(val, "string")
            end
            if whitelisted then
                Item = Item .. ReturnProperty(tag, propertyName, value)
            end
        end
        Item = Item .. "</Properties>"
        return Item
    end

    local function save_hierarchy(hierarchy)
        for _, instance in hierarchy do
            if IgnoreNotArchivable and not instance.Archivable then
                continue
            end
            local SkipEntirely = IgnoreList[instance]
            if SkipEntirely then
                continue
            end
            local ClassName = instance.ClassName
            local InstanceName = instance.Name
            do
                local OnIgnoredList = IgnoreList[ClassName]
                if OnIgnoredList and (OnIgnoredList == true or OnIgnoredList[InstanceName]) then
                    continue
                end
            end
            if not DecompileIgnoring then
                DecompileIgnoring = DecompileIgnore[instance]
                if DecompileIgnoring == nil then
                    local DecompileIgnored = DecompileIgnore[ClassName]
                    if DecompileIgnored then
                        DecompileIgnoring = DecompileIgnored == true or DecompileIgnored[InstanceName]
                    end
                end
                if DecompileIgnoring then
                    DecompileIgnoring = instance
                elseif DecompileIgnoring == false then
                    DecompileIgnoring = 1
                end
            end
            local InstanceOverride, ClassNameOverride, ClassTagOverride
            do
                local Fix = NotCreatableFixes[ClassName]
                if Fix then
                    if SaveNotCreatable then
                        ClassName, InstanceOverride = Fix, replaceClassName(instance, InstanceName, ClassName)
                    else
                        continue
                    end
                else
                    if TreatUnionsAsParts and instance:IsA("PartOperation") then
                        ClassName, InstanceOverride = "Part", replaceClassName(instance, InstanceName, ClassName)
                        ClassNameOverride = "BasePart"
                    elseif not ClassList[ClassName] then
                        if __DEBUG_MODE then
                            __DEBUG_MODE("Class not Found", ClassName)
                        end
                        ClassTagOverride = ClassName
                        ClassName = "Folder"
                    end
                end
            end
            if not InstanceOverride then
                InstanceOverride = InstancesOverrides[instance]
            end
            if InstanceOverride and InstanceOverride.__SaveSpecific then
                savebuffer[savebuffer_size] = save_specific(ClassName, InstanceOverride.Properties)
                savebuffer_size = savebuffer_size + 1
            else
                savebuffer[savebuffer_size] = ReturnItem(ClassTagOverride or ClassName, instance)
                savebuffer_size = savebuffer_size + 1
                if not (IgnorePropertiesOfNotScriptsOnScriptsMode and not isLuaSourceContainer(instance)) then
                    local default_instance, new_def_inst
                    if IgnoreDefaultProperties then
                        default_instance = default_instances[ClassName]
                        if not default_instance then
                            local ClassTags = ClassList[ClassName].Tags
                            if not (ClassTags and ClassTags.NotCreatable) then
                                new_def_inst = Instance.new(ClassName)
                                default_instance = {}
                                default_instances[ClassName] = default_instance
                            elseif __DEBUG_MODE then
                                __DEBUG_MODE("Unable to create default Instance", ClassName)
                            end
                        end
                    end
                    local proplist
                    do
                        local class = ClassNameOverride or ClassName
                        proplist = inherited_properties[class]
                        if not proplist then
                            proplist = GetInheritedProps(class)
                            inherited_properties[class] = proplist
                        end
                    end
                    for _, Property in proplist do
                        local PropertyName = Property.Name
                        if IgnoreProperties[PropertyName] then
                            continue
                        end
                        local ValueType = Property.ValueType
                        if IgnoreSharedStrings and ValueType == "SharedString" then
                            continue
                        end
                        local Special = Property.Special
                        local Category, Optional = Property.Category, Property.Optional
                        local raw = ReadProperty(instance, Property, PropertyName, Special, Category, Optional)
                        if raw == __BREAK then
                            local ok, result = pcall(gethiddenproperty_fallback, instance, PropertyName)
                            if result == nil and not Optional then
                                ok = nil
                            end
                            if ok then
                                raw = result
                            else
                                local Fallback = Property.Fallback
                                if Fallback then
                                    ok, result = pcall(Fallback, instance)
                                    if ok then
                                        raw = result
                                    else
                                        if __DEBUG_MODE then
                                            __DEBUG_MODE("Fix Failed", PropertyName)
                                        end
                                        continue
                                    end
                                else
                                    continue
                                end
                            end
                        end
                        if SharedStringOverwrite and ValueType == "BinaryString" then
                            ValueType = "SharedString"
                        end
                        if default_instance and not Property.Special and not (PropertyName == "Source" and isLuaSourceContainer(instance)) then
                            if new_def_inst then
                                default_instance[PropertyName] = new_def_inst[PropertyName]
                            end
                            if default_instance[PropertyName] == raw then
                                continue
                            end
                        end
                        local tag, value
                        if Category == "Class" then
                            tag = "Ref"
                            if raw then
                                if SaveNotCreatableWillBeEnabled then
                                    local Fix = NotCreatableFixes[raw.ClassName]
                                    if Fix and (PropertyName == "PlayerToHideFrom" or ValueType ~= "Instance" and ValueType ~= Fix) then
                                        continue
                                    end
                                end
                                value = GetRef(raw)
                            else
                                value = "null"
                            end
                        elseif Category == "Enum" then
                            value, tag = XML_Descriptors.__ENUM(raw)
                        else
                            local Descriptor = XML_Descriptors[ValueType]
                            if Descriptor then
                                value, tag = ReturnValueAndTag(raw, ValueType, Descriptor)
                            elseif "ProtectedString" == ValueType then
                                tag = ValueType
                                if PropertyName == "Source" then
                                    if DecompileIgnoring then
                                        if DecompileIgnoring == 1 then
                                            DecompileIgnoring = nil
                                        end
                                        value = "-- Ignored"
                                    else
                                        local should_decompile = true
                                        local LinkedSource
                                        local LinkedSource_Url = instance.LinkedSource
                                        local hasLinkedSource = LinkedSource_Url ~= ""
                                        local LinkedSource_type
                                        if hasLinkedSource then
                                            local Path = instance:GetFullName()
                                            if RecoveredScripts then
                                                table.insert(RecoveredScripts, Path)
                                            end
                                            LinkedSource = string.match(LinkedSource_Url, "%w+$")
                                            if LinkedSource then
                                                if ScriptCache then
                                                    local cached = ldeccache[LinkedSource]
                                                    if cached then
                                                        value = cached
                                                        should_decompile = nil
                                                    end
                                                end
                                                if should_decompile then
                                                    if DecompileJobless then
                                                        value = "-- Not found in LinkedSource ScriptCache"
                                                        should_decompile = nil
                                                    end
                                                    LinkedSource_type = string.find(LinkedSource, "%a") and "hash" or "id"
                                                    local asset = LinkedSource_type .. "=" .. LinkedSource
                                                    local ok, source = pcall(function()
                                                        return game:HttpGet("https://assetdelivery.roproxy.com/v1/asset/?" .. asset)
                                                    end)
                                                    if ok and filterLinkedSource(source) then
                                                        if ScriptCache then
                                                            ldeccache[LinkedSource] = source
                                                        end
                                                        value = source
                                                        should_decompile = nil
                                                    end
                                                end
                                            else
                                                warn("FAILED TO EXTRACT ORIGINAL SCRIPT SOURCE (OPEN A GITHUB ISSUE): ", instance:GetFullName(), LinkedSource_Url)
                                            end
                                        end
                                        if should_decompile then
                                            local isLocalScript = instance:IsA("LocalScript")
                                            if isLocalScript and instance.RunContext == Enum.RunContext.Server or not isLocalScript and instance:IsA("Script") and instance.RunContext ~= Enum.RunContext.Client then
                                                value = "-- [FilteringEnabled] Server Scripts are IMPOSSIBLE to save"
                                            else
                                                value = ldecompile(instance)
                                                if SaveBytecode then
                                                    local output = SaveBytecode(instance)
                                                    if output then
                                                        value = output .. value
                                                    end
                                                end
                                            end
                                        end
                                        value = "-- Saved by DinhKhanhInstance (Join to Copy Games) https://discord.gg/MB5KGBGCZz\n\n" .. (hasLinkedSource and "-- Original Source: https://assetdelivery.roblox.com/v1/asset/?" .. (LinkedSource_type or "id") .. "=" .. (LinkedSource or LinkedSource_Url) .. "\n\n" or "") .. value
                                    end
                                end
                                value = XML_Descriptors.__PROTECTEDSTRING(value)
                            else
                                if Optional then
                                    Descriptor = XML_Descriptors[Optional]
                                    if Descriptor then
                                        if raw == nil then
                                            continue
                                        else
                                            value, tag = ReturnValueAndTag(raw, ValueType, Descriptor)
                                        end
                                    end
                                end
                            end
                        end
                        if tag then
                            savebuffer[savebuffer_size] = ReturnProperty(tag, PropertyName, value)
                            savebuffer_size = savebuffer_size + 1
                        else
                            warn("UNSUPPORTED TYPE (OPEN A GITHUB ISSUE): ", ValueType, ClassName, PropertyName)
                        end
                    end
                end
                savebuffer[savebuffer_size] = "</Properties>"
                savebuffer_size = savebuffer_size + 1
                if SaveCacheInterval < savebuffer_size then
                    save_cache()
                end
            end
            if SkipEntirely ~= false then
                local Children = InstanceOverride and InstanceOverride.__Children or instance:GetChildren()
                if #Children ~= 0 then
                    save_hierarchy(Children)
                end
            end
            if DecompileIgnoring and DecompileIgnoring == instance then
                DecompileIgnoring = nil
            end
            savebuffer[savebuffer_size] = "</Item>"
            savebuffer_size = savebuffer_size + 1
        end
    end

    local function save_extra(name, hierarchy, customClassName, source)
        savebuffer[savebuffer_size] = save_specific((customClassName or "Folder"), { Name = name, Source = source })
        savebuffer_size = savebuffer_size + 1
        if hierarchy then
            save_hierarchy(hierarchy)
        end
        savebuffer[savebuffer_size] = "</Item>"
        savebuffer_size = savebuffer_size + 1
    end

    local function save_game()
        do
            if IsModel then
                header = header .. '<Meta name="ExplicitAutoJoints">true</Meta>'
            end
            writefile(placename, header)
        end
        SaveNotCreatableWillBeEnabled = SaveNotCreatable or (IsolateLocalPlayer or IsolateLocalPlayerCharacter) and IsolateLocalPlayer or IsolatePlayers or NilInstances and getnilinstances
        save_hierarchy(ToSaveList)
        if IsolateLocalPlayer or IsolateLocalPlayerCharacter then
            local LocalPlayer = game:GetService("Players").LocalPlayer
            if LocalPlayer then
                if IsolateLocalPlayer then
                    SaveNotCreatable = true
                    save_extra("LocalPlayer", LocalPlayer:GetChildren())
                end
                if IsolateLocalPlayerCharacter then
                    local LocalPlayerCharacter = LocalPlayer.Character
                    if LocalPlayerCharacter then
                        save_extra("LocalPlayer Character", LocalPlayerCharacter:GetChildren())
                    end
                end
            end
        end
        if IsolateStarterPlayer then
            SaveNotCreatable = true
            save_extra("StarterPlayer", game:GetService("StarterPlayer"):GetChildren())
        end
        if IsolatePlayers then
            SaveNotCreatable = true
            save_extra("Players", game:GetService("Players"):GetChildren())
        end
        if NilInstances and getnilinstances then
            local nil_instances, nil_instances_size = {}, 1
            local NilInstancesFixes = OPTIONS.NilInstancesFixes
            for _, instance in getnilinstances() do
                if instance == game then
                    instance = nil
                else
                    local ClassName = instance.ClassName
                    local Fix = InheritsFix(NilInstancesFixes, ClassName, instance)
                    if Fix then
                        instance = Fix(instance, InstancesOverrides)
                    end
                    local Class = ClassList[ClassName]
                    if Class then
                        local ClassTags = Class.Tags
                        if ClassTags and ClassTags.Service then
                            instance = nil
                        end
                    end
                end
                if instance then
                    nil_instances[nil_instances_size] = instance
                    nil_instances_size = nil_instances_size + 1
                end
            end
            SaveNotCreatable = true
            save_extra("Nil Instances", nil_instances)
        end
        if OPTIONS.ReadMe then
            save_extra("README", nil, "Script", "--[[\n" .. (#RecoveredScripts ~= 0 and "\t\tIMPORTANT: Original Source of these Scripts was Recovered: " .. game:GetService("HttpService"):JSONEncode(RecoveredScripts) .. "\n" or "") .. [[
        Thank you for using DinhKhanhInstance (Join to Copy Games) https://discord.gg/MB5KGBGCZz.
        If you didn't save in Binary (rbxl) - it's recommended to save the game right away to take advantage of the binary format & to preserve values of certain properties if you used IgnoreDefaultProperties setting (as they might change in the future).
        You can do that by going to FILE -> Save to File As -> Make sure File Name ends with .rbxl -> Save
        ServerStorage, ServerScriptService and Server Scripts are IMPOSSIBLE to save because of FilteringEnabled.
        If your player cannot spawn into the game, please move the scripts in StarterPlayer somewhere else. Then run `game:GetService("Players").CharacterAutoLoads = true`.
        And use "Play Here" to start game instead of "Play" to spawn your Character where your Camera currently is.
        If the chat system does not work, please use the explorer and delete everything inside the TextChatService/Chat service(s). 
        Or run `game:GetService("Chat"):ClearAllChildren() game:GetService("TextChatService"):ClearAllChildren()`
        If Union and MeshPart collisions don't work, run the script below in the Studio Command Bar:
        local C = game:GetService("CoreGui")
        local D = Enum.CollisionFidelity.Default
        for _, v in game:GetDescendants() do
            if v:IsA("TriangleMeshPart") and not v:IsDescendantOf(C) then
                v.CollisionFidelity = D
            end
        end
        print("Done")
        If you can't move the Camera, run this script in the Studio Command Bar:
        workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
        Or Destroy the Camera.
        This file was generated with the following settings:
        ]] .. game:GetService("HttpService"):JSONEncode(OPTIONS) .. "\n\n\t\tElapsed time: " .. os.clock() - elapse_t .. " PlaceId: " .. game.PlaceId .. " PlaceVersion: " .. game.PlaceVersion .. " Client Version: " .. version() .. " Executor: " .. (identifyexecutor and table.concat({ identifyexecutor() }, " ") or "Unknown") .. "\n]]")
        end
        do
            local tmp = { "<SharedStrings>" }
            for identifier, value in SharedStrings do
                table.insert(tmp, '<SharedString md5="' .. identifier .. '">' .. value .. "</SharedString>")
            end
            if 1 < #tmp then
                savebuffer[savebuffer_size] = table.concat(tmp)
                savebuffer_size = savebuffer_size + 1
                savebuffer[savebuffer_size] = "</SharedStrings>"
                savebuffer_size = savebuffer_size + 1
            end
        end
        savebuffer[savebuffer_size] = "</roblox><!-- Saved by DinhKhanhInstance (Join to Copy Games) https://discord.gg/MB5KGBGCZz -->"
        savebuffer_size = savebuffer_size + 1
        save_cache(true)
        do
            if OPTIONS.Anonymous then
                local LocalPlayer = game:GetService("Players").LocalPlayer
                if LocalPlayer then
                    local function gsubCaseInsensitive(input, search, replacement)
                        local inputLower = string.lower(input)
                        search = string.lower(search)
                        local lastFinish = 0
                        local subStrings = {}
                        local search_len = #search
                        local input_len = #input
                        while search_len <= input_len - lastFinish do
                            local init = lastFinish + 1
                            local start, finish = string.find(inputLower, search, init, true)
                            if start == nil then
                                break
                            end
                            table.insert(subStrings, string.sub(input, init, start - 1))
                            lastFinish = finish
                        end
                        if lastFinish == 0 then
                            return input
                        end
                        table.insert(subStrings, string.sub(input, lastFinish + 1))
                        return table.concat(subStrings, replacement)
                    end
                    local Anonymous = type(OPTIONS.Anonymous) == "table" and OPTIONS.Anonymous or { UserId = "1", Name = "Roblox" }
                    for _, chunk in chunks do
                        chunk.str = gsubCaseInsensitive(string.gsub(chunk.str, LocalPlayer.UserId, Anonymous.UserId), LocalPlayer.Name, Anonymous.Name)
                    end
                end
            end
            local Callback = OPTIONS.Callback
            if Callback then
                local totalstr = header
                for _, chunk in chunks do
                    totalstr = totalstr .. chunk.str
                end
                Callback(totalstr, chunks, totalsize)
            elseif OPTIONS.AlternativeWritefile and appendfile then
                local SEGMENT_SIZE = 4145728
                local totallen, currentlen = math.ceil(totalsize / SEGMENT_SIZE), 1
                for _, chunk in chunks do
                    local length = math.ceil(chunk.size / SEGMENT_SIZE)
                    for i = 1, length do
                        local savestr = string.sub(chunk.str, (i - 1) * SEGMENT_SIZE + 1, i * SEGMENT_SIZE)
                        run_with_loading("Writing to File " .. math.round(currentlen / totallen * 100) .. "% (Depends on Exec)", nil, true, appendfile, placename, savestr)
                        currentlen = currentlen + 1
                        if i ~= length then
                            task.wait()
                        end
                    end
                end
            else
                local totalstr = header
                for _, chunk in chunks do
                    totalstr = totalstr .. chunk.str
                end
                run_with_loading("Writing " .. get_size_format() .. " to File (Depends on Exec)", nil, true, writefile, placename, totalstr)
            end
        end
        table.clear(SharedStrings)
    end

    local Connections
    do
        local Players = game:GetService("Players")
        if IgnoreList.Model ~= true then
            Connections = {}
            local function ignoreCharacter(player)
                table.insert(Connections, player.CharacterAdded:Connect(function(character)
                    IgnoreList[character] = true
                end))
                local Character = player.Character
                if Character then
                    IgnoreList[Character] = true
                end
            end
            if OPTIONS.RemovePlayerCharacters then
                table.insert(Connections, Players.PlayerAdded:Connect(function(player)
                    ignoreCharacter(player)
                end))
                for _, player in Players:GetPlayers() do
                    ignoreCharacter(player)
                end
            else
                IgnoreNotArchivable = false
                if IsolateLocalPlayerCharacter then
                    task.spawn(function()
                        ignoreCharacter(GetLocalPlayer())
                    end)
                end
            end
        end
        if IsolateLocalPlayer and IgnoreList.Player ~= true then
            task.spawn(function()
                IgnoreList[GetLocalPlayer()] = true
            end)
        end
    end

    if IsolateStarterPlayer then
        IgnoreList.StarterPlayer = false
    end

    if IsolatePlayers then
        IgnoreList.Players = false
    end

    if OPTIONS.ShowStatus then
        do
            local Exists = getgenv()._statustext
            if Exists then
                Exists:Destroy()
            end
        end
        local StatusGui = Instance.new("ScreenGui")
        getgenv()._statustext = StatusGui
        StatusGui.DisplayOrder = 2e9
        pcall(function()
            StatusGui.OnTopOfCoreBlur = true
        end)
        StatusText = Instance.new("TextLabel")
        StatusText.Text = "Saving..."
        StatusText.BackgroundTransparency = 1
        StatusText.Font = Enum.Font.Code
        StatusText.AnchorPoint = Vector2.new(1)
        StatusText.Position = UDim2.new(1)
        StatusText.Size = UDim2.new(0.3, 0, 0, 20)
        StatusText.TextColor3 = Color3.new(1, 1, 1)
        StatusText.TextScaled = true
        StatusText.TextStrokeTransparency = 0.7
        StatusText.TextXAlignment = Enum.TextXAlignment.Right
        StatusText.TextYAlignment = Enum.TextYAlignment.Top
        StatusText.Parent = StatusGui
        local function randomString()
            local length = math.random(10, 20)
            local randomarray = table.create(length)
            for i = 1, length do
                randomarray[i] = string.char(math.random(32, 126))
            end
            return table.concat(randomarray)
        end
        if gethui then
            StatusGui.Name = randomString()
            StatusGui.Parent = gethui()
        else
            if protectgui then
                StatusGui.Name = randomString()
                protectgui(StatusGui)
                StatusGui.Parent = game:GetService("CoreGui")
            else
                local RobloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
                if RobloxGui then
                    StatusGui.Parent = RobloxGui
                else
                    StatusGui.Name = randomString()
                    StatusGui.Parent = game:GetService("CoreGui")
                end
            end
        end
    end

    do
        local SafeMode = OPTIONS.SafeMode
        if SafeMode then
            task.spawn(function()
                for i, v in ipairs(game:GetDescendants()) do
                    if v:IsA("Script") or v:IsA("LocalScript") then
                        v.Enabled = false
                    end
                end
                local LocalPlayer = GetLocalPlayer()
                local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
                if PlayerScripts then
                    local function construct_InstanceOverride(instance)
                        local children = instance:GetChildren()
                        InstancesOverrides[instance] = { __Children = children }
                        for _, child in children do
                            construct_InstanceOverride(child)
                        end
                    end
                    construct_InstanceOverride(PlayerScripts)
                    InstancesOverrides[LocalPlayer] = { __Children = LocalPlayer:GetChildren(), Properties = { Name = "[" .. LocalPlayer.ClassName .. "] " .. LocalPlayer.Name } }
                end
                LocalPlayer:Kick("\n[SAFEMODE] Saving in Progress..\nPlease do NOT leave")
                wait_for_render()
                task.delay(10, game:GetService("GuiService").ClearError, game:GetService("GuiService"))
            end)
            game:GetService("RunService"):Set3dRenderingEnabled(false)
        end
        local anti_idle
        if OPTIONS.AntiIdle then
            task.spawn(function()
                local getcon = getconnections
                local Idled = GetLocalPlayer().Idled
                if getcon then
                    for _, c in getcon(Idled) do
                        if not pcall(function()
                                c:Disable()
                            end) then
                            pcall(function()
                                c:Disconnect()
                            end)
                        end
                    end
                end
                anti_idle = Idled:Connect(function()
                    game:GetService("VirtualInputManager"):SendMouseWheelEvent(game:GetService("UserInputService"):GetMouseLocation().X, game:GetService("UserInputService"):GetMouseLocation().Y, true, game)
                end)
            end)
        end
        elapse_t = os.clock()
        local ok, err = xpcall(save_game, function(err)
            return debug.traceback(err)
        end)
        if SafeMode then
            game:GetService("GuiService"):ClearError()
            game:GetService("RunService"):Set3dRenderingEnabled(true)
        end
        if old_gethiddenproperty then
            gethiddenproperty = old_gethiddenproperty
        end
        if anti_idle then
            anti_idle:Disconnect()
        end
        if Connections then
            for _, connection in Connections do
                connection:Disconnect()
            end
        end
        getgenv()[placename] = nil
        if StatusText then
            task.spawn(function()
                elapse_t = os.clock() - elapse_t
                local Log10 = math.log10(elapse_t)
                local ExtraTime = 10
                if ok then
                    StatusText.Text = string.format("Saved! Time %.3f seconds; Size %s", elapse_t, get_size_format())
                    StatusText.TextColor3 = Color3.new(0, 1)
                    task.wait(Log10 * 2 + ExtraTime)
                else
                    if Loading then
                        task.cancel(Loading)
                        Loading = nil
                    end
                    StatusText.Text = "Failed! Check F9 console for more info"
                    StatusText.TextColor3 = Color3.new(1)
                    warn("Error found while saving:")
                    warn(err)
                    task.wait(Log10 + ExtraTime)
                end
                StatusText:Destroy()
            end)
        end
        if OPTIONS.ShutdownWhenDone and ok then
            game:Shutdown()
        end
    end
end

-- Export
getgenv().DinhKhanhInstance = DinhKhanhInstance

return DinhKhanhInstance
