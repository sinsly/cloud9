-- Cloud9 Loader
repeat task.wait() until game:IsLoaded()

-- File helpers
local isfile = isfile or function(file)
    local suc, res = pcall(function() return readfile(file) end)
    return suc and res ~= nil and res ~= ''
end

local isfolder = isfolder or function(folder)
    local suc, res = pcall(function() return listfiles(folder) end)
    return suc
end

local makefolder = makefolder or function(folder)
    pcall(function() return makefolder(folder) end)
end

local delfile = delfile or function(file)
    pcall(function() writefile(file, '') end)
end

-- Download function
local function downloadFile(path, func)
    if not isfile(path) then
        local commit = 'main'
        if isfile('cloud9file/profiles/commit.txt') then
            commit = readfile('cloud9file/profiles/commit.txt')
        end
        local suc, res = pcall(function()
            return game:HttpGet('https://raw.githubusercontent.com/sinsly/cloud9/'..commit..'/'..path:gsub('cloud9file/', ''), true)
        end)
        if not suc or not res or res == '404: Not Found' then
            error("Failed to download file: "..tostring(res))
        end
        if path:find('%.lua$') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after cloud9file updates.\n'..res
        end
        writefile(path, res)
    end
    return (func or readfile)(path)
end

-- Wipe cached folder logic
local function wipeFolder(path)
    if not isfolder(path) then return end
    for _, file in pairs(listfiles(path)) do
        if file:find('loader') then continue end
        if isfile(file) then
            local content = readfile(file)
            if content:find('--This watermark is used to delete the file if its cached, remove it to make the file persist after cloud9file updates.') then
                delfile(file)
            end
        end
    end
end

-- Ensure folder structure
for _, folder in pairs({'cloud9file', 'cloud9file/games', 'cloud9file/profiles', 'cloud9file/assets', 'cloud9file/libraries', 'cloud9file/guis'}) do
    if not isfolder(folder) then
        makefolder(folder)
    end
end

-- Commit check and wipe
if not shared.VapeDeveloper then
    local commit = 'main'
    local currentCommit = (isfile('cloud9file/profiles/commit.txt') and readfile('cloud9file/profiles/commit.txt')) or ''
    if currentCommit ~= commit then
        wipeFolder('cloud9file')
        wipeFolder('cloud9file/games')
        wipeFolder('cloud9file/guis')
        wipeFolder('cloud9file/libraries')
    end
    writefile('cloud9file/profiles/commit.txt', commit)
end

-- Load main.lua safely
local mainCode = downloadFile('cloud9file/main.lua')
if not mainCode or mainCode == '' then
    error("Failed to download main.lua")
end

local fn, err = loadstring(mainCode, 'main')
if not fn then
    error("Failed to load main.lua: "..tostring(err))
end

return fn()
