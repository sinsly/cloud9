repeat task.wait() until game:IsLoaded()
if shared.cloud9 then shared.cloud9:Uninject() end

if identifyexecutor then
	if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local cloud9
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and cloud9 then
		cloud9:CreateNotification('Cloud9', 'Failed to load: '..err, 30, 'alert')
	end
	return res
end

local queue_on_teleport = queue_on_teleport or function() end
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
local writefile = writefile or function(file, content) end

local HttpGet = (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or function(opts)
	return {Body = game:HttpGet(opts.Url)}
end

local function ensureFolder(path)
	local parts = {}
	for part in path:gmatch("[^/]+") do
		table.insert(parts, part)
		local current = table.concat(parts, "/")
		if not isfolder(current) then makefolder(current) end
	end
end

-- === GUI profile ===
if not isfile('cloud9file/profiles/gui.txt') then
	writefile('cloud9file/profiles/gui.txt', 'new')
end
local gui = readfile('cloud9file/profiles/gui.txt')
ensureFolder('cloud9file/assets/'..gui)

-- === Generic file downloader ===
local function downloadFile(path)
	if not isfile(path) then
		local commit = 'main'
		if isfile('cloud9file/profiles/commit.txt') then
			commit = readfile('cloud9file/profiles/commit.txt')
		end
		local suc, res = pcall(function()
			return HttpGet({Url = 'https://raw.githubusercontent.com/sinsly/cloud9/'..commit..'/'..path:gsub('cloud9file/', '')}).Body
		end)
		if not suc or not res or res == '404: Not Found' then
			error("Failed to download file: "..tostring(res))
		end
		if path:find('%.lua$') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after cloud9file updates.\n'..res
		end
		writefile(path, res)
	end
	return readfile(path)
end

-- === Load GUI ===
cloud9 = loadstring(downloadFile('cloud9file/guis/'..gui..'.lua'), 'gui')()
shared.cloud9 = cloud9

-- === Finish loading function ===
local function finishLoading()
	cloud9.Init = nil
	cloud9:Load()
	task.spawn(function()
		repeat
			cloud9:Save()
			task.wait(10)
		until not cloud9.Loaded
	end)

	local teleported
	cloud9:Clean(game:GetService('Players').LocalPlayer.OnTeleport:Connect(function()
		if teleported then return end
		teleported = true

		-- Check version
		local localVersion, remoteVersion
		local HttpService = game:GetService("HttpService")
		if isfile("cloud9file/version.json") then
			local suc, data = pcall(function() return HttpService:JSONDecode(readfile("cloud9file/version.json")) end)
			if suc then localVersion = data.version end
		end
		local suc, res = pcall(function()
			return HttpGet({Url = "https://raw.githubusercontent.com/sinsly/cloud9/refs/heads/main/version.json"}).Body
		end)
		if suc and res then
			remoteVersion = HttpService:JSONDecode(res).version
		end

		local teleportScript
		if remoteVersion and localVersion ~= remoteVersion then
			-- Version mismatch: reload loader to redownload everything
			teleportScript = [[
shared.cloud9reload = true
loadstring(game:HttpGet('https://raw.githubusercontent.com/sinsly/cloud9/main/loader.lua', true), 'loader')()
]]
		else
			-- Version same: reload main.lua normally
			teleportScript = [[
shared.cloud9reload = true
loadstring(readfile('cloud9file/main.lua'), 'main')()
]]
		end

		if shared.Cloud9Developer then
			teleportScript = 'shared.Cloud9Developer = true\n'..teleportScript
		end
		if shared.Cloud9CustomProfile then
			teleportScript = 'shared.Cloud9CustomProfile = "'..shared.Cloud9CustomProfile..'"\n'..teleportScript
		end

		cloud9:Save()
		queue_on_teleport(teleportScript)
	end))

	if not shared.cloud9reload then
		if cloud9.Categories and cloud9.Categories.Main.Options['GUI bind indicator'].Enabled then
			cloud9:CreateNotification(
				'Finished Loading',
				cloud9.Cloud9Button and
					'Press the button in the top right to open GUI' or
					'Press '..table.concat(cloud9.Keybind, ' + '):upper()..' to open GUI',
				5
			)
		end
	end
end

-- === Load place/game scripts ===
if not shared.Cloud9Independent then
	local placeId = game.PlaceId
	local universeId = game.GameId

	local placeFile = 'cloud9file/games/'..placeId..'.lua'
	local universeFile = 'cloud9file/games/universe_'..universeId..'.lua'

	local function tryLoad(localPath, remotePath, chunkName)
		if isfile(localPath) then
			loadstring(readfile(localPath), chunkName)()
			return true
		end

		local suc, res = pcall(function()
			return HttpGet({Url = 'https://raw.githubusercontent.com/sinsly/cloud9/'..readfile('cloud9file/profiles/commit.txt')..'/'..remotePath}).Body
		end)

		if suc and res and res ~= '404: Not Found' then
			writefile(localPath, res)
			loadstring(res, chunkName)()
			return true
		end
		return false
	end

	if not tryLoad(placeFile, 'games/'..placeId..'.lua', 'place_'..placeId) then
		if not tryLoad(universeFile, 'games/universe_'..universeId..'.lua', 'universe_'..universeId) then
			loadstring(downloadFile('cloud9file/games/universal.lua'), 'universal')()
		end
	end

	finishLoading()
else
	cloud9.Init = finishLoading
	return cloud9
end
