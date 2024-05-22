local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('ds-npccontrol:server:GetCops', function(_, cb)
    local amount = 0
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.name == "police" and v.PlayerData.job.onduty then
            amount = amount+1
        end
    end
    cb(amount)
end)