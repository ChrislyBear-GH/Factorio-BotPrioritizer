local hst = {}

function hst.in_history(player, entity)
    if not (global.player_state[player.index].bp_method == "Auto-Mode") then return end

    if entity.object_name == "LuaEntity" then
        return (global.player_state[player.index].bp_entity_history[entity.unit_number] ~= nil)
    elseif entity.object_name == "LuaTile" then
        return (global.player_state[player.index].bp_entity_history[entity.position] ~= nil)
    else
        return false
    end
end

function hst.purge_history(player, event)
    local purge_time = global.player_state[player.index].bp_history_time
    for id, tick in pairs(global.player_state[player.index].bp_entity_history) do
        if tick < (event.tick - purge_time * 60) then
            global.player_state[player.index].bp_entity_history[id] = nil
        end
    end
end

function hst.add_to_history(player, entity, event)
    if not (global.player_state[player.index].bp_method == "Auto-Mode") then return end

    if entity.object_name == "LuaEntity" then
        global.player_state[player.index].bp_entity_history[entity.unit_number] = event.tick
    elseif entity.object_name == "LuaTile" then
        global.player_state[player.index].bp_entity_history[entity.position] = event.tick
    end
end

return hst