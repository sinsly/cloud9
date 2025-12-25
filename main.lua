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
		cloud9:CreateNotification('Cloud9', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end

local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end

local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet(
				'https://raw.githubusercontent.com/sinsly/cloud9/'..
				readfile('cloud9file/profiles/commit.txt')..'/'..
				select(1, path:gsub('cloud9file/', '')),
				true
			)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after cloud9file updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()
	cloud9.Init = nil
	cloud9:Load()
	task.spawn(function()
		repeat
			cloud9:Save()
			task.wait(10)
		until not cloud9.Loaded
	end)

	local teleportedServers
	cloud9:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.Cloud9Independent) then
			teleportedServers = true
			local teleportScript = [[
shared.cloud9reload = true
if shared.Cloud9Developer then
	loadstring(readfile('cloud9file/loader.lua'), 'loader')()
else
	loadstring(game:HttpGet('https://raw.githubusercontent.com/sinsly/cloud9/'..readfile('cloud9file/profiles/commit.txt')..'/loader.lua', true), 'loader')()
end
]]
			if shared.Cloud9Developer then
				teleportScript = 'shared.Cloud9Developer = true\n'..teleportScript
			end
			if shared.Cloud9CustomProfile then
				teleportScript = 'shared.Cloud9CustomProfile = "'..shared.Cloud9CustomProfile..'"\n'..teleportScript
			end
			cloud9:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.cloud9reload then
		if not cloud9.Categories then return end
		if cloud9.Categories.Main.Options['GUI bind indicator'].Enabled then
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

if not isfile('cloud9file/profiles/gui.txt') then
	writefile('cloud9file/profiles/gui.txt', 'new')
end

local gui = readfile('cloud9file/profiles/gui.txt')

if not isfolder('cloud9file/assets/'..gui) then
	makefolder('cloud9file/assets/'..gui)
end

cloud9 = loadstring(downloadFile('cloud9file/guis/'..gui..'.lua'), 'gui')()
shared.cloud9 = cloud9

if not shared.Cloud9Independent then
	local placeId = game.PlaceId
	local universeId = game.GameId

	local placeFile = 'cloud9file/games/'..placeId..'.lua'
	local universeFile = 'cloud9file/games/universe_'..universeId..'.lua'

	local function tryLoad(localPath, remotePath, chunkName)
		if isfile(localPath) then
			loadstring(readfile(localPath), chunkName)(...)
			return true
		end

		local suc, res = pcall(function()
			return game:HttpGet(
				'https://raw.githubusercontent.com/sinsly/cloud9/'..
				readfile('cloud9file/profiles/commit.txt')..'/'..
				remotePath,
				true
			)
		end)

		if suc and res ~= '404: Not Found' then
			writefile(localPath, res)
			loadstring(res, chunkName)(...)
			return true
		end

		return false
	end

	if tryLoad(
		placeFile,
		'games/'..placeId..'.lua',
		'place_'..placeId
	) then
	elseif tryLoad(
		universeFile,
		'games/universe_'..universeId..'.lua',
		'universe_'..universeId
	) then
	else
		loadstring(
			downloadFile('cloud9file/games/universal.lua'),
			'universal'
		)()
	end

	finishLoading()
else
	cloud9.Init = finishLoading
	return cloud9
end
