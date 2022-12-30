local QRCore = exports['qr-core']:GetCoreObject()
local foundResources = {}
local neededResources = {"qr_menu"}
local detectNeededResources = function()

for k, v in ipairs(neededResources) do
        if GetResourceState(v) == "started" then
            foundResources[v] = true
        else
        end
    end
end

detectNeededResources()
RegisterServerEvent('qr_clothes:Save', function(Clothes, Name, price)
    local _source = source
    local _Name = Name
    local encode = json.encode(Clothes)
    local Player = QRCore.Functions.GetPlayer(_source)
        local citizenid = Player.PlayerData.citizenid
        local license = QRCore.Functions.GetIdentifier(_source, 'license')
        local currentMoney = Player.Functions.GetMoney('cash')
        if currentMoney >= price then
            Player.Functions.RemoveMoney("cash", price)
            TriggerEvent("qr_clothes:retrieveClothes", citizenid, license, function(call)
                if call then
                    MySQL.Async.execute("UPDATE playerclothe SET `clothes` = ? WHERE `citizenid`= ? AND `license`= ?", {encode, citizenid, license})
                else
                    MySQL.Async.insert('INSERT INTO playerclothe (citizenid, license, clothes) VALUES (?, ?, ?);', {citizenid, license, encode})

                end
            end)
            if _Name then
                TriggerEvent("qr_clothes:retrieveOutfits", citizenid, license, _Name, function(call)

                    if call then
                        MySQL.Async.execute("UPDATE playeroutfit SET `clothes` = ? WHERE `citizenid`= ? AND `license`= ? AND name = ?", {encode, citizenid, license, _Name})

                    else
                        MySQL.Async.insert('INSERT INTO playeroutfit (citizenid, license, clothes, name) VALUES (?, ?, ?, ?);', {citizenid, license, encode, _Name})
                    end
                end)
            end
        else
            TriggerClientEvent("qr_appearance:LoadSkinClient", _source)
        end
end)

RegisterServerEvent('qr_clothes:LoadClothes', function(value)
    local _value = value
    local _source = source
    local _clothes = nil
    local User = QRCore.Functions.GetPlayer(source)
    local citizenid = User.PlayerData.citizenid
    local license = QRCore.Functions.GetIdentifier(source, 'license')
        local _clothes =  MySQL.Sync.fetchAll('SELECT * FROM playerclothe WHERE citizenid = ? AND license = ?', {citizenid, license})

        if _clothes[1] then
            _clothes = json.decode(_clothes[1].clothes)
        else
            _clothes = {}
        end
        if _clothes ~= nil then
            if _value == 1 then
                TriggerClientEvent("qr_clothes:ApplyClothes", _source, _clothes)
            elseif _value == 2 then
                TriggerClientEvent("qr_clothes:OpenClothingMenu", _source, _clothes)
            end
        end
end)

RegisterServerEvent('qr_clothes:SetOutfits', function(name)
    local _source = source
    local _name = name
    local Player = QRCore.Functions.GetPlayer(_source)
        local citizenid = Player.PlayerData.citizenid
        local license = QRCore.Functions.GetIdentifier(_source, 'license')
        TriggerEvent('qr_clothes:retrieveOutfits', citizenid, license, _name, function(call)
            if call then
                MySQL.Async.execute("UPDATE playerclothe SET `clothes` = ? WHERE `citizenid`= ? AND `license`= ? ", {call, citizenid, license})
                TriggerClientEvent("qr_appearance:LoadSkinClient", _source)
            end
        end)
end)
RegisterServerEvent('qr_clothes:DeleteOutfit', function(name)
    local _source = source
    local _name = name
    local Player = QRCore.Functions.GetPlayer(_source)
        local citizenid = Player.PlayerData.citizenid
        local license = QRCore.Functions.GetIdentifier(_source, 'license')
        MySQL.Async.fetchAll('DELETE FROM playeroutfit WHERE citizenid = ? AND license = ? AND name =  ?', {citizenid, license, _name})
end)

RegisterServerEvent('qr_clothes:getOutfits', function()
    local _source = source
    local Player = QRCore.Functions.GetPlayer(_source)
    local citizenid = Player.PlayerData.citizenid
    local license = QRCore.Functions.GetIdentifier(_source, 'license')
    TriggerEvent('redemrp_db:getOutfits', citizenid, license, function(call)
        if call then
            TriggerClientEvent('qr_clothes:putInTable', _source, call)
        end
    end)
end)

AddEventHandler('redemrp_db:getOutfits', function(citizenid, license, callback)
    local Callback = callback
    local outfits = MySQL.Sync.fetchAll('SELECT * FROM playeroutfit WHERE citizenid = ? AND license = ?', {citizenid, license})
    if outfits[1] then
        Callback(outfits)
    else
        Callback(false)
    end
end)

AddEventHandler('qr_clothes:retrieveClothes', function(citizenid, license, callback)
    local Callback = callback
    local clothes = MySQL.Sync.fetchAll('SELECT * FROM playerclothe WHERE citizenid = ? AND license = ?', {citizenid, license})

    if clothes[1] then
        Callback(clothes[1])
    else
        Callback(false)
    end
end)

AddEventHandler('qr_clothes:retrieveOutfits', function(citizenid, license, name, callback)
    local Callback = callback
    local clothes = MySQL.Sync.fetchAll('SELECT * FROM playeroutfit WHERE citizenid = ? AND license = ? AND name = ?', {citizenid, license, name})

    if clothes[1] then
        Callback(clothes[1]["clothes"])
    else
        Callback(false)
    end
end)

RegisterServerEvent("qr_clothes:deleteClothes", function(license, Callback)
    local _source = source
    local id
    for k, v in ipairs(GetPlayerIdentifiers(_source)) do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            id = v
            break
        end
    end
    local Callback = callback
    MySQL.Async.fetchAll('DELETE FROM playerclothe WHERE `citizenid`= ? AND`license`= ?;', {id, license})
    MySQL.Async.fetchAll('DELETE FROM playeroutfit WHERE `citizenid`= ? AND`license`= ?;', {id, license})
end)
