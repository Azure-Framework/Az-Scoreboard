local RESOURCE = GetCurrentResourceName()
local FRAMEWORK_RESOURCE = Config.FrameworkResource or 'Az-Framework'
local fw = exports[FRAMEWORK_RESOURCE]

local function eprint(...)
  print(('^1[%s]^7'):format(RESOURCE), ...)
end

local function dprint(...)
  if Config.Debug or GetConvarInt('az_scoreboard:debug', 0) == 1 then
    print(('^3[%s]^7'):format(RESOURCE), ...)
  end
end

local function getJobLabel(job)
  local rawKey = tostring(job or ''):lower()
  if rawKey == '' then
    return 'Civilian'
  end

  for _, tab in ipairs(Config.Tabs or {}) do
    if tab.showAll ~= true then
      for _, allowedJob in ipairs(tab.jobs or {}) do
        if rawKey == tostring(allowedJob):lower() then
          return tostring(tab.label or rawKey:gsub('^%l', string.upper))
        end
      end
    end
  end

  return rawKey:gsub('^%l', string.upper)
end

local function gatherPlayer(src, done)
  local entry = {
    source = tonumber(src) or src,
    fullname = GetPlayerName(src) or ('Player ' .. tostring(src)),
    jobInfo = nil,
    job = nil,
    rawJob = nil,
    rankName = '',
    cash = 0,
    bank = 0,
    ping = GetPlayerPing(src) or 0,
    discordId = '',
    charId = nil,
    isAdmin = false,
  }

  local ok, did = pcall(function() return fw:getDiscordID(src) end)
  entry.discordId = (ok and did) or ''

  local okc, cid = pcall(function() return fw:GetPlayerCharacter(src) end)
  entry.charId = (okc and cid) or nil

  local okj, job = pcall(function() return fw:getPlayerJob(src) end)
  local rawJob = (okj and job) or nil
  local normalizedJob = tostring(rawJob or 'civilian'):lower()
  if normalizedJob == '' then normalizedJob = 'civilian' end
  entry.job = normalizedJob
  entry.rawJob = normalizedJob
  entry.jobInfo = {
    name = normalizedJob,
    rawName = normalizedJob,
    label = getJobLabel(normalizedJob),
  }

  local oka, isA = pcall(function() return fw:isAdmin(src) end)
  entry.isAdmin = (oka and isA) or false

  local oks, syncName = pcall(function()
    return fw:GetPlayerCharacterNameSync(src)
  end)
  if oks and syncName and tostring(syncName) ~= '' then
    entry.fullname = tostring(syncName)
  end

  local waiting = 2
  local finished = false

  local function stepDone()
    waiting = waiting - 1
    if waiting <= 0 and not finished then
      finished = true
      done(entry)
    end
  end

  pcall(function()
    fw:GetPlayerCharacterName(src, function(err, name)
      if not err and name and tostring(name) ~= '' then
        entry.fullname = tostring(name)
      end
      stepDone()
    end)
  end)

  pcall(function()
    fw:GetPlayerMoney(src, function(err, wallet)
      wallet = wallet or {}
      entry.cash = tonumber(wallet.cash) or 0
      entry.bank = tonumber(wallet.bank) or 0
      stepDone()
    end)
  end)

  SetTimeout(1500, function()
    if not finished then
      dprint('gatherPlayer timeout for src', src)
      finished = true
      done(entry)
    end
  end)
end

RegisterNetEvent('az_scoreboard:requestPlayers', function(reqId)
  local src = source
  local players = GetPlayers() or {}
  local list = {}

  if #players == 0 then
    TriggerClientEvent('az_scoreboard:returnPlayers', src, reqId, list)
    return
  end

  local remaining = #players
  local sent = false

  local function maybeSend()
    if sent then return end
    if remaining <= 0 then
      sent = true
      table.sort(list, function(a, b)
        return (tonumber(a.source) or 0) < (tonumber(b.source) or 0)
      end)
      TriggerClientEvent('az_scoreboard:returnPlayers', src, reqId, list)
    end
  end

  for _, pid in ipairs(players) do
    local id = tonumber(pid)
    if id then
      gatherPlayer(id, function(entry)
        list[#list + 1] = entry
        remaining = remaining - 1
        maybeSend()
      end)
    else
      remaining = remaining - 1
      maybeSend()
    end
  end

  SetTimeout(2000, function()
    if sent then return end
    sent = true
    table.sort(list, function(a, b)
      return (tonumber(a.source) or 0) < (tonumber(b.source) or 0)
    end)
    TriggerClientEvent('az_scoreboard:returnPlayers', src, reqId, list)
  end)
end)

local DutyTracker = {}
local dataFile = 'duty_times.json'

local function loadData()
  local f = LoadResourceFile(RESOURCE, dataFile)
  if f then DutyTracker = json.decode(f) or {} end
end

local function saveData()
  SaveResourceFile(RESOURCE, dataFile, json.encode(DutyTracker, { indent = true }), -1)
end

local function getWebhookFromConfig()
  local url = tostring(Config.WebhookURL or '')
  if url == '' or url:find('your/webhook/url', 1, true) then return nil end
  return url
end

local function sendDiscord(msg)
  local webhook = getWebhookFromConfig()
  if not webhook then return end
  PerformHttpRequest(webhook, function() end, 'POST', json.encode({ content = msg }), {
    ['Content-Type'] = 'application/json'
  })
end

local function dutyKeyFor(src)
  local ok, did = pcall(function() return fw:getDiscordID(src) end)
  if ok and did and did ~= '' then return 'discord:' .. tostring(did) end

  local lic = GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'license') or nil
  if lic and lic ~= '' then return lic end

  return GetPlayerIdentifier(src, 0) or ('src:' .. tostring(src))
end

loadData()

RegisterCommand('duty', function(source)
  local src = source
  if not src or src == 0 then return end

  local key = dutyKeyFor(src)
  local now = os.time()

  DutyTracker[key] = DutyTracker[key] or { totalSeconds = 0, onDuty = false, startTs = nil }

  if not DutyTracker[key].onDuty then
    DutyTracker[key].onDuty = true
    DutyTracker[key].startTs = now

    sendDiscord(('[ON DUTY] %s'):format(key))
    TriggerClientEvent('chat:addMessage', src, { args = { '^2[Duty] ON duty.' } })
  else
    local session = now - (DutyTracker[key].startTs or now)
    DutyTracker[key].totalSeconds = (DutyTracker[key].totalSeconds or 0) + session
    DutyTracker[key].onDuty = false
    DutyTracker[key].startTs = nil

    saveData()

    local hrs = math.floor((DutyTracker[key].totalSeconds or 0) / 3600)
    local mins = math.floor(((DutyTracker[key].totalSeconds or 0) % 3600) / 60)

    sendDiscord(('[OFF DUTY] %s — Session %d min, Total %d h %d m')
      :format(key, math.floor(session / 60), hrs, mins))

    TriggerClientEvent('chat:addMessage', src, {
      args = { ('^1[Duty] OFF duty. Total: %dh %dm'):format(hrs, mins) }
    })
  end
end, false)

CreateThread(function()
  Wait(500)
  if not fw then
    eprint(FRAMEWORK_RESOURCE .. ' export not found. Ensure ' .. FRAMEWORK_RESOURCE .. ' is started before ' .. RESOURCE)
  else
    dprint(FRAMEWORK_RESOURCE .. ' detected for scoreboard')
  end
end)
