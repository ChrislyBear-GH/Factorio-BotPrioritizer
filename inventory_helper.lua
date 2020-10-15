local inv_hlp = {}

function inv_hlp.in_inventory(player, entity_name)
    local cnt = 0
    if pcall(function() cnt = player.get_main_inventory().get_item_count(entity_name) end) then
        return (cnt>0)
    else
        return true
    end
end

return inv_hlp