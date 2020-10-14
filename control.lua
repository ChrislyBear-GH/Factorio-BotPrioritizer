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
local function reprioritize(entities, tiles, player, event)

    -- Keep updgrade table clean
    up_mgr.remove_stale_upgrades()
    -- Clean history for player
    historian.purge_history(player, event)

    local surface = player.surface
    local force = player.force
    local cnt = 0

    for _, entity in pairs(entities) do
        local refreshed_entity = nil
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
            if refreshed_entity then historian.add_to_history(player, refreshed_entity, event) end
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

                historian.add_to_history(player, tile, event)
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

local function no_tool(player, event)
    local p_use_tool = false -- kind of obvious, here
    -- Make sure god mode isn't used and there's an actual character on the ground
    if player.character and player.character.valid then
        local char = player.character

        if not char.logistic_cell and global.debug then 
            player.print("Personal roboport not equipped.")
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

        if tick_event then
            -- entities = historian.filter_for_new_entities()
        end

        -- TODO: Implement logic to stop reassigning already reassigned entities!

        --global.player_state[player.index].bp_entites_previously_in_range = tbl_deep_copy(entities)

        -- No tiles will be handed over, because
        -- deconstructible-tile-proxy will already be
        -- in the entities table.
        local tiles = {}
        
        -- Do the work...
        reprioritize(entities, tiles, player, event)    
    end
end

local function toggle_button(player, toggled)
    player.set_shortcut_toggled("bot-prio-shortcut", toggled)
    global.player_state[player.index].bp_toggled = toggled
end

-- Main function that starts it all
local function on_hotkey_main(event)
    if not (event.item == 'bot-prioritizer') and not (event.input_name == "botprio-hotkey") then return end

    -- Check if globals exist, if not create them (reuse init function)
    on_init()
    if not global.player_state[event.player_index] then 
        global.player_state[event.player_index] = {
            bp_hint = 0,
            bp_use_tool = true,
            bp_use_toggle = false,
            bp_disable_msg = false,
            bp_toggled = false,
            bp_entity_history = {},
            bp_history_time = 5
        } 
    end
    -- Just to catch a missing history table from previous versions
    if not global.player_state[event.player_index].bp_entity_history then 
        global.player_state[event.player_index].bp_entity_history = {}
    end

    local player = game.get_player(event.player_index)
    local pidx = event.player_index

    global.player_state[pidx].bp_use_tool = hlp.personal_setting_value(player, "botprio-use-selection")
    global.player_state[pidx].bp_disable_msg = hlp.personal_setting_value(player, "botprio-disable-msg")
    global.player_state[pidx].bp_use_toggle = hlp.personal_setting_value(player, "botprio-toggling")
    -- Get the player's setting into a global variable for later use!
    if global.player_state[pidx].bp_use_toggle then 
        global.player_state[pidx].bp_history_time = hlp.personal_setting_value(player, "botprio-toggling-time")
    end

    if global.player_state[pidx].bp_use_tool then
        toggle_button(player, false)
        produce_tool(player)
    elseif not global.player_state[pidx].bp_use_toggle then
        toggle_button(player, false)
        no_tool(player, event) -- Not on_tick
    else --! use_tool = false, use_toggle = true
        if event.name == defines.events.on_tick then
            no_tool(player, event) -- No messaging and on_tick around!
        else
            local tggld = player.is_shortcut_toggled("bot-prio-shortcut")
            toggle_button(player, not tggld)
        end

    end

end

-- Runs after player selected stuff
local function handle_selection(event)
if not (event.item == 'bot-prioritizer') then return end
    local player = game.get_player(event.player_index)
    reprioritize(event.entities, event.tiles, player, event)
end

-- Start it from shortcut instead of hotkey
local function bot_prio_shortcut(event)
    if event.prototype_name == "bot-prio-shortcut" then
        event.item = 'bot-prioritizer'
        on_hotkey_main(event)
    end
end

-- Track player movement
local function handle_ticks(event)
    -- runs only every 1/6th of a second, could lead to problems
    -- if player moves very fast. But performance is more important.
    if game.tick % 20 ~= 0 then return end 
    event.item = 'bot-prioritizer'
    if not global.player_state then return end
    
    for _, player in pairs(game.players) do
        if not global.player_state[player.index] then return end
        if not global.player_state[player.index].bp_toggled then return end
        event.player_index = player.index
        on_hotkey_main(event)
    end
end




-- Event hooks
script.on_init(on_init)

-- "Auto-Mode" must run each nth tick
script.on_event(defines.events.on_tick,handle_ticks)

-- Hotkey
script.on_event( "botprio-hotkey", on_hotkey_main)
-- Shortcut button
script.on_event(defines.events.on_lua_shortcut, bot_prio_shortcut)

-- Handle upgrade orders because get_upgrade_target() is unreliable
script.on_event(defines.events.on_marked_for_upgrade, up_mgr.handle_ordered_upgrades)
script.on_event(defines.events.on_cancelled_upgrade, up_mgr.handle_cancelled_upgrades)

-- Gather entity ghosts and give bots priority after selction is made
script.on_event(defines.events.on_player_selected_area, handle_selection)
script.on_event(defines.events.on_player_alt_selected_area, handle_selection)


-- Add a debugging command
commands.add_command("botprio_debug", {"bot-prio.cmd-help"}, hlp.dbg_cmd)