local QBCore = exports['qb-core']:GetCoreObject()

local secuestrando = false
local pedAtacada = {}
local handsup = false

local takeHostage = {
	InProgress = false,
	agressor = {
		animDict = "anim@gangops@hostage@",
		anim = "perp_idle",
		flag = 49,
	},
	hostage = {
		animDict = "anim@gangops@hostage@",
		anim = "victim_idle",
		attachX = -0.24,
		attachY = 0.11,
		attachZ = 0.0,
		flag = 49,
        ped = nil
	}
}

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

function GetClosestPed()
    local playerPed = GetPlayerPed(-1)
    local playerCoords = GetEntityCoords(playerPed)
    local closestPed = nil
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= playerPed and not IsPedAPlayer(ped) then
            local pedCoords = GetEntityCoords(ped)
            local distance = GetDistanceBetweenCoords(playerCoords, pedCoords, true)
            if distance <= 3 then
                closestPed = ped
                break
            end
        end
    end
    return closestPed
end

function textoFlotante(x,y,z, text)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextOutline(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()

end)

RegisterNetEvent('qb-npccontrol:client:seguir', function(data)
    TaskGoToEntity(data.ped, PlayerPedId(), -1, 5.0, 5.0 , 1073741824, 0)
    TaskFollowToOffsetOfEntity(data.ped, PlayerPedId(), 0.0, -5.0, 0.0, 3.0, -1, 0.0, true)
    SetPedKeepTask(data.ped, true)
    FreezeEntityPosition(data.ped, false)
end)

RegisterNetEvent('qb-npccontrol:client:liberar', function(data)
    FreezeEntityPosition(data.ped, false)
    ClearPedTasks(data.ped)
end)

RegisterNetEvent('qb-npccontrol:client:arrodillar', function(data)
    ClearPedTasks(data.ped)
    RequestAnimDict('random@arrests')
    while (not HasAnimDictLoaded("random@arrests")) do
        Wait(10)
    end
    TaskPlayAnim(data.ped,"random@arrests","kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
    FreezeEntityPosition(data.ped, true)
end)

RegisterNetEvent('qb-npccontrol:client:metervehiculo', function(data)
    local plyped = PlayerPedId()
    local ped = data.ped
    local player_coord = GetEntityCoords(plyped)
    local coord = GetEntityCoords(ped)
    local distance = #(player_coord - coord)
    if distance > 4 then
        QBCore.Functions.Notify("La persona está muy lejos", "error", 1500)
        return
    end
    local vehicle, distanceveh = QBCore.Functions.GetClosestVehicle()
    if distanceveh > 4 then
        QBCore.Functions.Notify("Está muy lejos del vehículo", "error", 1500)
        return
    end
    for i = GetVehicleMaxNumberOfPassengers(vehicle), 0, -1 do
        if IsVehicleSeatFree(vehicle, i) then
            ClearPedTasks(ped)
            DetachEntity(ped, true, false)
            Wait(100)
            SetPedIntoVehicle(ped, vehicle, i)
            return
        end
    end
end)

RegisterNetEvent('qb-npccontrol:client:sacarvehiculo', function()
    if secuestrando then
        closestPed, closestDistance = GetClosestPed()
        if IsPedInAnyVehicle(closestPed, true) then
            SetEntityCoords(closestPed, GetEntityCoords(PlayerPedId()), 1, 0, 0, 1)
            loadAnimDict("missminuteman_1ig_2")
            TaskPlayAnim(closestPed, "missminuteman_1ig_2", "handsup_base", 8.0, 8.0, -1, 50, 0, false, false, false)
            TaskGoToEntity(closestPed, PlayerPedId(), -1, 5.0, 5.0 , 1073741824, 0)
            TaskFollowToOffsetOfEntity(closestPed, PlayerPedId(), 0.0, -5.0, 0.0, 3.0, -1, 0.0, true)
            SetPedKeepTask(closestPed, true)
        end
    end
end)

RegisterNetEvent("qb-npccontrol:client:th", function(data)
    takeHostage.InProgress = true
    ClearPedTasks(PlayerPedId())
    loadAnimDict("anim@gangops@hostage@")
    TaskPlayAnim(PlayerPedId(), "anim@gangops@hostage@", "perp_idle", 8.0, -8.0, -1, 168, 0, false, false, false)
    local targetPed = data.ped
	loadAnimDict("anim@gangops@hostage@")
    TaskPlayAnim(targetPed, "anim@gangops@hostage@", "victim_idle", 8.0, -8.0, -1, 168, 0, false, false, false)
	SetTextEntry_2("STRING")
	AddTextComponentString("Pulsa [G] para liberar")
	EndTextCommandPrint(1000, 1)
    takeHostage.hostage.ped = targetPed
	AttachEntityToEntity(targetPed, PlayerPedId(), 0, takeHostage.hostage.attachX, takeHostage.hostage.attachY, takeHostage.hostage.attachZ, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
end)

RegisterNetEvent("ds-npccontrol:Client:TogleSecuestroNPC", function()
    QBCore.Functions.TriggerCallback('ds-npccontrol:server:GetCops', function(cops)
        CurrentCops = cops
        if Config.Debug then
            Config.MinimumPolice  = 0
        end
        if CurrentCops >= Config.MinimumPolice then
            secuestrando = not secuestrando
            if secuestrando then
                QBCore.Functions.Notify("Secuestro de NPC activo", "success")
            else
                QBCore.Functions.Notify("Secuestro de NPC desactivado", "info")
            end
        else
            secuestrando = false
            QBCore.Functions.Notify("No ha suficientes policías de servicio", "error")
        end
    end)
end)

RegisterNetEvent('ds-npccontrol:client:menuNPC', function(targetPed)
    pedAtacada[targetPed] = true
    local  npccontrol = {
        {
            header = "npccontrol",
            isMenuHeader = true
        },
    }
    npccontrol[#npccontrol+1] = {
        header = "Seguir",
        txt =  "Hacer que te siga",
        icon = "",
        params = {
            event = "qb-npccontrol:client:seguir",
            args = {
                ped = targetPed
            }
        }
    }
    npccontrol[#npccontrol+1] = {
        header = "Liberar",
        txt =  "Hacer que se huya",
        icon = "",
        params = {
            event = "qb-npccontrol:client:liberar",
            args = {
                ped = targetPed
            }
        }
    }
    npccontrol[#npccontrol+1] = {
        header = "Arrodilar",
        txt =  "Hacer que se arrodille",
        icon = "",
        params = {
            event = "qb-npccontrol:client:arrodillar",
            args = {
                ped = targetPed
            }
        }
    }
    npccontrol[#npccontrol+1] = {
        header = "Meter al coche",
        txt =  "Meter en el coche",
        icon = "",
        params = {
            event = "qb-npccontrol:client:metervehiculo",
            args = {
                ped = targetPed
            }
        }
    }
    npccontrol[#npccontrol+1] = {
        header = "Coger del cuello",
        txt =  "Amenazar de muerte",
        icon = "",
        params = {
            event = "qb-npccontrol:client:th",
            args = {
                ped = targetPed
            }
        }
    }
    npccontrol[#npccontrol+1] = {
        header = "⬅ Cerrar Menu",
        txt = "",
        params = {
            event = "qb-menu:client:cerrarMenu"
        }
    }
    exports['qb-menu']:openMenu(npccontrol)
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 10000
        if secuestrando then
            sleep = 600
            local ped = PlayerPedId()
            local aiming, targetPed = GetEntityPlayerIsFreeAimingAt(PlayerId(-1))
            if aiming then
                sleep = 10
                if DoesEntityExist(targetPed) and not IsPedAPlayer(targetPed) and not IsPedInAnyVehicle(targetPed, false) 
                        and IsPedArmed(PlayerPedId(), 7) and IsEntityAPed(targetPed) and not IsEntityDead(targetPed) then
                    local distance = GetDistanceBetweenCoords(GetEntityCoords(ped, true), GetEntityCoords(targetPed, true), false)
                    if distance < 10 then
                        TaskGoToEntity(targetPed, PlayerPedId(), -1, 5.0, 5.0 , 1073741824, 0)
                        loadAnimDict("missminuteman_1ig_2")
                        TaskPlayAnim(targetPed, "missminuteman_1ig_2", "handsup_base", 8.0, 8.0, -1, 50, 0, false, false, false)
                        TaskFollowToOffsetOfEntity(targetPed, PlayerPedId(), 0.0, -5.0, 0.0, 3.0, -1, 0.0, true)
                        FreezeEntityPosition(targetPed, true)
                        exports['qb-core']:DrawText("[E] - Controlar NPC", 'right')
                        if IsControlJustPressed(0, 38) then
                            TaskSetBlockingOfNonTemporaryEvents(targetPed, true)
                            TriggerEvent("ds-npccontrol:client:menuNPC", targetPed)
                            Wait(3000)
                        end
                        FreezeEntityPosition(targetPed, false)
                    end
                end
            else
                exports['qb-core']:HideText()
            end
        end
        Wait(sleep)
    end
end)


Citizen.CreateThread(function()
	while true do
		local sleep = 1000
        if takeHostage.InProgress then
			sleep = 5
			if not IsEntityPlayingAnim(PlayerPedId(), takeHostage.agressor.animDict, takeHostage.agressor.anim, 3) then
				TaskPlayAnim(PlayerPedId(), takeHostage.agressor.animDict, takeHostage.agressor.anim, 8.0, -8.0, 100000, takeHostage.agressor.flag, 0, false, false, false)
			end
			if not IsEntityPlayingAnim(takeHostage.hostage.ped, takeHostage.hostage.animDict, takeHostage.hostage.anim, 3) then
				TaskPlayAnim(PlayerPedId(), takeHostage.hostage.animDict, takeHostage.hostage.anim, 8.0, -8.0, 100000, takeHostage.hostage.flag, 0, false, false, false)
			end
		end
		Wait(sleep)
	end
end)

CreateThread(function()
	while true do 
		local sleep = 1000
        if takeHostage.InProgress then
			sleep = 10
			if IsDisabledControlJustPressed(0,47) then --liberar	
				takeHostage.InProgress = false
				loadAnimDict("reaction@shove")
				TaskPlayAnim(PlayerPedId(), "reaction@shove", "shove_var_a", 8.0, -8.0, -1, 168, 0, false, false, false)
                DetachEntity(takeHostage.hostage.ped, true, false)
                loadAnimDict("reaction@shove")
                TaskPlayAnim(takeHostage.hostage.ped, "reaction@shove", "shoved_back", 8.0, -8.0, -1, 0, 0, false, false, false)
                Wait(250)
                ClearPedTasks(PlayerPedId())
			end
        end
		Wait(sleep)
	end
end)