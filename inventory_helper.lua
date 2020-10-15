local inv_hlp = {}

function inv_hlp.in_inventory(player, entity_name)
    return (player.get_main_inventory().get_item_count(entity_name)>0)
end

return inv_hlp