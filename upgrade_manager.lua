local up_mgr

-- Add information about upgrades to our table
function up_mgr.handle_ordered_upgrades(event)
    local nr = event.entity.unit_number

    if not global.upgrades then 
        global.upgrades = {} 
    elseif not global.upgrades[nr] then
        global.upgrades[nr] = { e = event.entity, t = event.target.name }
    end
end

-- Remove upgrades from our table if they have been cancelled
function up_mgr.handle_cancelled_upgrades(event)
    local nr = event.entity.unit_number

    if global.upgrades and global.upgrades[nr] then
        global.upgrades[nr] = nil
    end
end

-- Clear stale entites from upgrade table
function up_mgr.remove_stale_upgrades()
    if not global.upgrades then global.upgrades = {} end

    for unit_nr, data in pairs(global.upgrades) do
        if not data.e.valid or not data.e or not data.e.to_be_upgraded then
            global.upgrades[unit_nr] = nil
        end
    end
end

return up_mgr