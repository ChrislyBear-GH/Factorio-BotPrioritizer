local inv_hlp = {}

function inv_hlp.in_inventory(player, entity_name)
    local cnt = 0
    if not global.player_state[player.index].bp_no_inv_checks
        and pcall(function() cnt = player.get_main_inventory().get_item_count(entity_name) end) then
        return (cnt>0)
    else
        return true
    end
end

return inv_hlp