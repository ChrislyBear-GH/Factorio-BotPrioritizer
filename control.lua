-- Table to keep track of upgrades. The built-in function is unreliable.
if global.upgrades then global.upgrades = global.upgrades
else global.upgrades = {} end

-- Grab settings value
function personal_setting_value(player, name)
    if player and player.mod_settings and player.mod_settings[name] then
      return player.mod_settings[name].value
    else
      return nil
    end
end

-- Add information about upgrades to our table
local function handle_ordered_upgrades(event)
    local nr = event.entity.unit_number

    if global.upgrades then global.upgrades = global.upgrades
    else global.upgrades = {} end

    if not global.upgrades[nr] then
        global.upgrades[nr] = { e = event.entity, t = event.target.name }
    end

end

-- Remove upgrades from our table if they have been cancelled
local function handle_cancelled_upgrades(event)
    local nr = event.entity.unit_number

    if global.upgrades and global.upgrades[nr] then
        global.upgrades[nr] = nil
    end
end

-- Clear stale entites from upgrade table
local function remove_stale_upgrades()
    if global.upgrades then global.upgrades = global.upgrades
    else global.upgrades = {} end

    for unit_nr, data in pairs(global.upgrades) do
        if not data.e.valid or not data.e or not data.e.to_be_upgraded then
            global.upgrades[unit_nr] = nil
        end
    end
end

-- Main logic to reassign bot work orders
-- Returns: Number of reassigned work orders
local function reprioritize(entities, tiles, surface, player_index, use_tool, disable_msg)

    -- Keep updgrade table clean
    remove_stale_upgrades()

    local player = game.get_player(player_index)
    local force = player.force
    local cnt = 0

    for _, entity in pairs(entities) do
        if entity.valid then
            if entity.type == "entity-ghost" or entity.type == "tile-ghost" then -- handle ghosts
                if entity.clone({position = entity.position, force = entity.force}) then
                    entity.destroy()
                    cnt = cnt + 1
                end
            elseif entity ~= nil and entity.to_be_deconstructed() then -- handle entities to be deconstructed
                -- Tiles have their own 'deconstruction' entity
                if entity.name == 'deconstructible-tile-proxy' then
                    local tile = surface.get_tile(entity.position)
                    tile.cancel_deconstruction(force, player)
                    tile.order_deconstruction(force, player)
                else -- regular entities
                    entity.cancel_deconstruction(force)
                    entity.order_deconstruction(force)
                end
                cnt = cnt + 1
            elseif entity ~= nil and entity.to_be_upgraded() then -- handle upgrades
                -- local upgrade_proto = entity.get_upgrade_target() -- This doesn't work for some reason!
                local upgrade_proto = global.upgrades[entity.unit_number].t
                if upgrade_proto then
                    entity.cancel_upgrade(force)
                    entity.order_upgrade({force = entity.force, target = upgrade_proto, player = player})
                    cnt = cnt + 1
                else
                    player.print("ERROR: Couldn't find out upgrade target.")
                end
            end
        end
    end

    -- Only used with the selection tool
    for _, tile in pairs(tiles) do
        if tile.valid then
            --! API request tile.to_be_deconstructed()
            local pos = tile.position
            pos.x, pos.y = pos.x + .5, pos.y + .5
            if surface.find_entity('deconstructible-tile-proxy', pos) then
                tile.cancel_deconstruction(force, player)
                tile.order_deconstruction(force, player)
                cnt = cnt + 1
            end
        end
    end

    if not disable_msg then 
        -- Report outcome.
        -- feedback for the player.
        local msg = "" 
        if cnt > 0 then
            msg = msg .. "Re-Assigned " .. cnt .. " work orders"
        else
            msg = msg .. "No work orders found"
        end

        if use_tool then
            msg = msg .. " in selection."
        else
            msg = msg .. " in personal roboport area."
        end
        player.print(msg)
    end
    
end


-- Produces a selection tool and takes it away again
-- or reprioritzes right away, depending on setting
local function on_hotkey_main(event)
    if not event.item == 'bot-prioritizer' then return end

    local player = game.get_player(event.player_index)
    local use_tool = personal_setting_value(player, "botprio-use-selection")
    local disable_msg = personal_setting_value(player, "botprio-disable-msg")

    if use_tool then
        -- once in a save game, a message is displayed giving a hint for the tool use
        global.bprio_hint_tool = global.bprio_hint_tool or 0
        if global.bprio_hint_tool == 0 then
            player.print({"bot-prio.hint-tool"})
            global.bprio_hint_tool = 1
        end

        -- Put a selection tool in the player's hand
        if player.clean_cursor() then
            player.cursor_stack.set_stack({name = 'bot-prioritizer', type = 'selection-tool', count = 1})
        end

    else

        if player.character and player.character.valid then
            local char = player.character
    
            if not char.logistic_cell then 
                player.print("Personal Roboport not equipped.")
                return
            end
            local c_rad = char.logistic_cell.construction_radius or 0
            local pos = player.position

            local entities = player.surface.find_entities_filtered({
                    area={{pos.x - c_rad, pos.y - c_rad},{pos.x + c_rad, pos.y + c_rad}},
                    force = player.force
                })

            -- No tiles will be handed over, because
            -- deconstructible-tile-proxy will already be
            -- in the entities table.
            local tiles = {}
            
            -- Do the work...
            reprioritize(entities, tiles, player.surface, event.player_index, use_tool, disable_msg)    
        end
    end






end

-- Runs after player selected stuff
local function handle_selection(event)
    if not event.item == 'bot-prioritizer' then return end
    local player = game.get_player(event.player_index)
    local use_tool = personal_setting_value(player, "botprio-use-selection")
    local disable_msg = personal_setting_value(player, "botprio-disable-msg")
    reprioritize(event.entities, event.tiles, event.surface, event.player_index, use_tool, disable_msg)
end

-- Start it from shortcut instead of hotkey
local function bot_prio_shortcut(event)
    if event.prototype_name == "bot-prio-shortcut" then
        on_hotkey_main(event)
    end
end


-- Hotkey
script.on_event( "botprio-hotkey", on_hotkey_main)
-- Shortcut button
script.on_event( defines.events.on_lua_shortcut, bot_prio_shortcut)

-- Handle upgrade orders because get_upgrade_target() is unreliable
script.on_event(defines.events.on_marked_for_upgrade, handle_ordered_upgrades)
script.on_event(defines.events.on_cancelled_upgrade, handle_cancelled_upgrades)

-- Gather entity ghosts and give bots priority after selction is made
script.on_event(defines.events.on_player_selected_area, handle_selection)
script.on_event(defines.events.on_player_alt_selected_area, handle_selection)