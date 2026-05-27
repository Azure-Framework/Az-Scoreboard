local RESOURCE = GetCurrentResourceName()

local isVisible = false

local function buildNuiConfig()
    local tabs = {}
    for _, tab in ipairs(Config.Tabs or {}) do
        tabs[#tabs + 1] = {
            id = tostring(tab.id or ''),
            label = tostring(tab.label or tab.id or 'Tab'),
            badgeLabel = tostring(tab.badgeLabel or tab.label or tab.id or 'Tab'),
            showAll = tab.showAll == true,
            showInFooter = tab.showInFooter ~= false and tab.showAll ~= true,
            jobs = tab.jobs or {},
            color = tab.color or 'rgba(42,164,216,.95)',
            glow = tab.glow or 'rgba(42,164,216,.12)'
        }
    end

    return {
        ui = Config.UI or {},
        tabs = tabs
    }
end

local function setScoreboard(on)
    if on == isVisible then return end
    isVisible = on

    SetNuiFocus(on, on)
    SetNuiFocusKeepInput(false)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, on)

    if on then
        SendNUIMessage({ action = 'show', config = buildNuiConfig() })
    else
        SendNUIMessage({ action = 'hide' })
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, Config.OpenKey or 213) then
            setScoreboard(not isVisible)
        end
    end
end)

RegisterCommand(Config.Command or 'scoreboard', function()
    setScoreboard(not isVisible)
end, false)

RegisterNUICallback('close', function(_, cb)
    setScoreboard(false)
    cb({})
end)

local pending = {}

RegisterNUICallback('fetchPlayers', function(_, cb)
    local reqId = tostring(math.random(1, 1000000000))
    pending[reqId] = cb
    TriggerServerEvent('az_scoreboard:requestPlayers', reqId)
end)

RegisterNetEvent('az_scoreboard:returnPlayers')
AddEventHandler('az_scoreboard:returnPlayers', function(reqId, players)
    local cb = pending[reqId]
    if cb then
        cb(players)
        pending[reqId] = nil
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= RESOURCE then return end
    if isVisible then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)
