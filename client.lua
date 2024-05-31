local QBCore = exports['qb-core']:GetCoreObject()

local secuestrando = false

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(10)
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

local function RotationToDirection(rotation)
	local ajustarRotacion =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direccion =
	{
		x = -math.sin(ajustarRotacion.z) * math.abs(math.cos(ajustarRotacion.x)),
		y = math.cos(ajustarRotacion.z) * math.abs(math.cos(ajustarRotacion.x)),
		z = math.sin(ajustarRotacion.x)
	}
	return direccion
end

local function RayCastGamePlayCamera(distancia)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direccion = RotationToDirection(cameraRotation)
	local destino =
	{
		x = cameraCoord.x + direccion.x * distancia,
		y = cameraCoord.y + direccion.y * distancia,
		z = cameraCoord.z + direccion.z * distancia
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destino.x, destino.y, destino.z, -1, PlayerPedId(), 0))
	return b, c, e
end


function Laser()
    local color = {r = 2, g = 241, b = 181, a = 200}
    local hit, coords = RayCastGamePlayCamera(20.0)

    if hit then
        local position = GetEntityCoords(PlayerPedId())
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false)
    end

    return hit, coords
end

function Colocar(coords, ped)
    ClearPedTasks(ped)
    TaskPlayAnim(ped, "missminuteman_1ig_2", "handsup_base", 8.0, 8.0, -1, 50, 0, false, false, false)
    FreezeEntityPosition(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskGoStraightToCoord(ped, coords, 15.0, -1, 0.0, 0.0)
    Wait(3000)
 end

RegisterNetEvent('ds-npccontrol:client:Colocar', function(data)
    rayoLaser = not rayoLaser

    if rayoLaser then
        CreateThread(function()
            while rayoLaser do
                local hit, coords = Laser()

                if IsControlJustReleased(0, 38) then
                    rayoLaser = false
                    if hit then
                       Colocar(coords, data.ped)
                    else
                        QBCore.Functions.Notify("No se puede colocar ahí", "error")
                    end
                elseif IsControlJustReleased(0, 47) then
                    rayoLaser = false
                end
                Wait(0)
            end
        end)
    end
end)

RegisterNetEvent('ds-npccontrol:client:seguir', function(data)
    TaskGoToEntity(data.ped, PlayerPedId(), -1, 2.0, 2.0 , 1073741824, 0)
    TaskFollowToOffsetOfEntity(data.ped, PlayerPedId(), 0.0, -2.0, 0.0, 2.0, -1, 0.0, true)
    SetPedKeepTask(data.ped, true)
    FreezeEntityPosition(data.ped, false)
end)

RegisterNetEvent('ds-npccontrol:client:liberar', function(data)
    FreezeEntityPosition(data.ped, false)
    ClearPedTasks(data.ped)
    SetPedFleeAttributes(data.ped, 0, 0)
    TaskReactAndFleePed(data.ped, PlayerPedId())
end)

RegisterNetEvent('ds-npccontrol:client:arrodillar', function(data)
    ClearPedTasks(data.ped)
    RequestAnimDict('random@arrests')
    while (not HasAnimDictLoaded("random@arrests")) do
        Wait(10)
    end
    TaskPlayAnim(data.ped,"random@arrests","kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
    SetBlockingOfNonTemporaryEvents(data.ped, true)
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
            local pos = GetEntityCoords(PlayerPedId())
            SetEntityCoords(closestPed, pos.x + 1.0, pos.y + 1.0, pos.z + 0.5, 1, 0, 0, 1)
            loadAnimDict("missminuteman_1ig_2")
            TaskPlayAnim(closestPed, "missminuteman_1ig_2", "handsup_base", 8.0, 8.0, -1, 50, 0, false, false, false)
            TaskGoToEntity(closestPed, PlayerPedId(), -1, 5.0, 5.0 , 1073741824, 0)
            TaskFollowToOffsetOfEntity(closestPed, PlayerPedId(), 0.0, -2.0, 0.0, 2.0, -1, 0.0, true)
            SetPedKeepTask(closestPed, true)
        end
    end
end)

RegisterNetEvent("ds-npccontrol:Client:TogleSecuestroNPC", function()
    QBCore.Functions.TriggerCallback('ds-npccontrol:server:GetCops', function(cops)
        CurrentCops = cops
        if Config.Debug then
            Config.MinimumPolice = 0
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

RegisterNetEvent('ds-npccontrol:menu:Rehen', function(targetPed)
    local MenuRehen = {
        {
            header = "npccontrol",
            isMenuHeader = true
        },
        {
            header = "Seguir",
            txt =  "Hacer que te siga",
            icon = "",
            params = {
                event = "ds-npccontrol:client:seguir",
                args = {
                    ped = targetPed
                }
            }
        },
        {
            header = "Mover",
            txt =  "Colocar en un punto",
            icon = "",
            params = {
                event = "ds-npccontrol:client:Colocar",
                args = {
                    ped = targetPed
                }
            }
        },
        {
            header = "Arrodillar",
            txt =  "Poner en posición de guardia",
            icon = "",
            params = {
                event = "ds-npccontrol:client:arrodillar",
                args = {
                    ped = targetPed
                }
            }
        },
        {
            header = "Meter al coche",
            txt =  "Meter en el coche",
            icon = "",
            params = {
                event = "qb-npccontrol:client:metervehiculo",
                args = {
                    ped = targetPed
                }
            }
        },
        {
            header = "Liberar",
            txt =  "Hacer que se huya",
            icon = "",
            params = {
                event = "ds-npccontrol:client:liberar",
                args = {
                    ped = targetPed
                }
            }
        },
    }
    exports['qb-menu']:openMenu(MenuRehen)
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 10000
        if secuestrando then
            sleep = 500
            local ped = PlayerPedId()
            local aiming, targetPed = GetEntityPlayerIsFreeAimingAt(PlayerId(-1))
            if aiming then
                sleep = 10
                local distance = GetDistanceBetweenCoords(GetEntityCoords(ped, true), GetEntityCoords(targetPed, true), false)
                if distance <  10 then
                    loadAnimDict("missminuteman_1ig_2")
                    if DoesEntityExist(targetPed) and not IsPedAPlayer(targetPed) and not IsPedInAnyVehicle(targetPed, false) 
                        and IsPedArmed(PlayerPedId(), 7) and IsEntityAPed(targetPed) and not IsEntityDead(targetPed) then
                        FreezeEntityPosition(targetPed, true)
                        TaskPlayAnim(targetPed, "missminuteman_1ig_2", "handsup_base", 8.0, 8.0, -1, 3, 0, false, false, false)
                        exports['qb-target']:AddTargetEntity(targetPed, {
                            options = {
                                {
                                    type = "client",
                                    event = "ds-npccontrol:menu:Rehen",
                                    icon = "fa-solid fa-scythe",
                                    label = "Ordenar rehen",
                                    action = function(entity)
                                        TriggerEvent('ds-npccontrol:menu:Rehen', entity)
                                    end,
                                },
                            },
                            distance = 2.5
                        })
                    end
                end
            end
            if (not IsEntityPlayingAnim(targetPed, "missminuteman_1ig_2", "handsup_base", 3) and not IsEntityPlayingAnim(targetPed, "missminuteman_1ig_2", "handsup_base", 3)) then
                TaskPlayAnim(targetPed, "missminuteman_1ig_2", "handsup_base", 8.0, 8.0, -1, 3, 0, false, false, false)
            end
        end
        Wait(sleep)
    end
end)