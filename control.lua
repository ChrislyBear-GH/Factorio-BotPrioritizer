local hlp = require("helpers")
local up_mgr = require("upgrade_manager")
local circ_mgr = require("circuit_manager")
local historian = require("history")

-- On_load to initialize the upgrade tracking table if it is missing
local function on_init()
    if not global.upgrades then global.upgrades = {} end
    if not global.debug then global.debug = false end
    if not global.player_state then global.player_state = {} end
end

-- Main logic to reassign bot work orders
local function reprioritize(event, player, entities, tiles)

    -- Keep updgrade table clean
    up_mgr.remove_stale_upgrades()
    
    -- Clean history for player
    historian.purge_history(event, player)

    local surface = player.surface
    local force = player.force
    local cnt = 0

    for _, entity in pairs(entities) do
        local refreshed_entity = nil -- One variable to collect them all

        if entity.valid and not historian.in_history(player, entity) then
            if entity.type == "entity-ghost" or entity.type == "tile-ghost" then -- handle ghosts
                -- Try to keep existing circuit connections
                local new = hlp.tbl_deep_copy(entity.clone({position = entity.position, force = entity.force}))
                circ_mgr.copy_circuit_connections(entity, new)

                if new then
                    refreshed_entity = new
                    entity.destroy()
                    cnt = cnt + 1
                end

            elseif entity ~= nil and entity.to_be_deconstructed() then -- handle entities to be deconstructed
                -- Tiles have their own 'deconstruction' entity
                if entity.name == 'deconstructible-tile-proxy' then
                    local tile = surface.get_tile(entity.position)
                    tile.cancel_deconstruction(force, player)
                    tile.order_deconstruction(force, player)
                    
                    local pos = tile.position
                    pos.x, pos.y = pos.x + .5, pos.y + .5
                    refreshed_entity = surface.find_entity('deconstructible-tile-proxy', pos)
                else -- regular entities
                    entity.cancel_deconstruction(force)
                    entity.order_deconstruction(force)
                    refreshed_entity = entity
                end
                cnt = cnt + 1
                
            elseif entity ~= nil and entity.to_be_upgraded() then -- handle upgrades
                -- local upgrade_proto = entity.get_upgrade_target() -- This doesn't work for some reason!
                local upgrade_proto = global.upgrades[entity.unit_number].t
                if upgrade_proto then
                    entity.cancel_upgrade(force)
                    entity.order_upgrade({force = entity.force, target = upgrade_proto, player = player})
                    refreshed_entity = entity
                    cnt = cnt + 1
                elseif global.debug then
                    player.print("ERROR: Couldn't find out upgrade target.")
                end
            end
            if refreshed_entity then historian.add_to_history(event, player, refreshed_entity) end
        end
    end

    -- Only used with the selection tool
    for _, tile in pairs(tiles) do
        if tile.valid and not historian.in_history(player, tile) then
            --! API request tile.to_be_deconstructed()
            local pos = tile.position
            pos.x, pos.y = pos.x + .5, pos.y + .5
            if surface.find_entity('deconstructible-tile-proxy', pos) then
                tile.cancel_deconstruction(force, player)
                tile.order_deconstruction(force, player)

                historian.add_to_history(event, player, tile)
                cnt = cnt + 1
            end
        end
    end

    -- Report outcome.
    if not global.player_state[player.index].bp_disable_msg and not (event.name == defines.events.on_tick) then 
        hlp.print_result(player, cnt)
    end
    
end

-- Produces a selection tool
local function produce_tool(player)
            -- once in a save game, a message is displayed giving a hint for the tool use        
        if global.player_state[player.index].bp_hint == 0 then
            player.print({"bot-prio.hint-tool"})
            global.player_state[player.index].bp_hint = 1
        end

        -- Put a selection tool in the player's hand
        if player.clean_cursor() then
            player.cursor_stack.set_stack({name = 'bot-prioritizer', type = 'selection-tool', count = 1})
        end
end

local function no_tool(event, player)
    -- Make sure god mode isn't used and there's an actual character on the ground
    if player.character and player.character.valid then
        local char = player.character

        if not char.logistic_cell then 
            if global.debug then player.print("Personal roboport not equipped.") end
            return
        end
        local c_rad = char.logistic_cell.construction_radius or 0
        local pos = player.position
        local bbox = {{pos.x - c_rad, pos.y - c_rad},{pos.x + c_rad, pos.y + c_rad}}

        if global.debug then hlp.debug_draw_bot_area(player, bbox) end

        local entities = player.surface.find_entities_filtered({
            area=bbox,
            force = player.force
        })

        -- No tiles will be handed over, because
        -- deconstructible-tile-proxy will already be
        -- in the entities table.
        local tiles = {}
        
        -- Do the work...
        reprioritize(event, player, entities, tiles)    
    end
end

-- Runs after player selected stuff
local function handle_selection(event)
if not (event.item == 'bot-prioritizer') then return end
    local player = game.get_player(event.player_index)
    reprioritize(event, player, event.entities, event.tiles)
end

-- Start it from shortcut instead of hotkey
local function handle_shortcut_and_hotkey(event)
    if not (event.prototype_name == "bot-prio-shortcut"
            or event.input_name == "botprio-hotkey") then return end

    -- Check if globals exist, if not create them (reuse init function)
    on_init()

    -- Get player and update their settings
    local pidx = event.player_index
    local player = game.get_player(pidx)

    hlp.cache_player_settings(player)

    -- Depending on operation mode do different things
    if global.player_state[pidx].bp_method == "Selection Tool" then
        produce_tool(player)
    elseif global.player_state[pidx].bp_method == "Direct Selection" then
        no_tool(event, player)
    else 
        player.set_shortcut_toggled("bot-prio-shortcut", 
                                    not player.is_shortcut_toggled("bot-prio-shortcut"))
    end
end

-- Track player movement
local function handle_ticks(event)
    -- runs only every 1/6th of a second, could lead to problems
    -- if player moves very fast. But performance is more important.
    if not global.player_state then return end
    for _, player in pairs(game.players) do

        if global.player_state[player.index] then -- Cached settings available
            if game.tick % (global.player_state[player.index].bp_tick_freq or 20) == 0 then  -- Keep frequency for player
                if (global.player_state[player.index].bp_method == "Auto-Mode") and player.is_shortcut_toggled("bot-prio-shortcut") then -- Active
                    no_tool(event, player)
                end
            end
        end

    end
end

local function settings_changed(event)
    if event.setting:sub(1, 8) ~= "botprio-" then return end
    
    local player = game.get_player(event.player_index)
    hlp.cache_player_settings(player)

end




-- Event hooks
script.on_init(on_init)

-- "Auto-Mode" must run each nth tick
script.on_event(defines.events.on_tick, handle_ticks)

-- Hotkey
script.on_event( "botprio-hotkey", handle_shortcut_and_hotkey)
-- Shortcut button
script.on_event(defines.events.on_lua_shortcut, handle_shortcut_and_hotkey)

-- Handle upgrade orders because get_upgrade_target() is unreliable
script.on_event(defines.events.on_marked_for_upgrade, up_mgr.handle_ordered_upgrades)
script.on_event(defines.events.on_cancelled_upgrade, up_mgr.handle_cancelled_upgrades)

-- Gather entity ghosts and give bots priority after selction is made
script.on_event(defines.events.on_player_selected_area, handle_selection)
script.on_event(defines.events.on_player_alt_selected_area, handle_selection)


-- Add a debugging command
commands.add_command("bp-debug", {"bot-prio.cmd-help"}, hlp.dbg_cmd)

-- Keep settings in global variables
script.on_event(defines.events.on_runtime_mod_setting_changed, settings_changed)