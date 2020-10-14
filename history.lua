local hst = {}

function hst.in_history(player, entity)
    if not (global.player_state[player.index].bp_method == "Auto-Mode") then return end
    return (global.player_state[player.index].bp_entity_history[entity.unit_number] ~= nil)
end

function hst.purge_history(player, event)
    local purge_time = global.player_state[player.index].bp_history_time
    for u_nr, tick in pairs(global.player_state[player.index].bp_entity_history) do
        if tick < (event.tick - purge_time * 60) then
            global.player_state[player.index].bp_entity_history[u_nr] = nil
        end
    end
end

function hst.add_to_history(player, entity, event)
    if not (global.player_state[player.index].bp_method == "Auto-Mode") then return end
    global.player_state[player.index].bp_entity_history[entity.unit_number] = event.tick
end

return hst