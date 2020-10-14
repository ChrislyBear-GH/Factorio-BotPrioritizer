local hlp = require("helpers.lua")
local up_mgr = require("upgrade_manager.lua")


-- Main logic to reassign bot work orders
-- Returns: Number of reassigned work orders
local function reprioritize(entities, tiles, surface, player_index, use_tool, disable_msg)

    -- Keep updgrade table clean
    up_mgr.remove_stale_upgrades()

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
                elseif global.debug then
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

    -- Report outcome.
    if not disable_msg then 
        hlp.print_result(player, cnt, use_tool)
    end
    
end

-- Produces a selection tool and takes it away again
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

local function no_tool(player, disable_msg, plr_moving)
    local use_tool = false -- kind of obvious, here
    -- Make sure god mode isn't used and there's an actual character on the ground
    if player.character and player.character.valid then
        local char = player.character

        if not char.logistic_cell then 
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
        

            -- TODO: Implement logic to stop reassigning already reassigned entities!

        --global.player_state[player.index].bp_entites_previously_in_range = tbl_deep_copy(entities)

        -- No tiles will be handed over, because
        -- deconstructible-tile-proxy will already be
        -- in the entities table.
        local tiles = {}
        
        -- Do the work...
        reprioritize(entities, tiles, player.surface, player.index, use_tool, disable_msg)    
    end
end

local function toggle_button(player, toggled)
    player.set_shortcut_toggled("bot-prio-shortcut", toggled)
    global.player_state[player.index].bp_toggled = toggled
end

-- Main function that starts it all
local function on_hotkey_main(event)
    if not event.item == 'bot-prioritizer' then return end

    -- Check if Globals exist, if not create them
    if not global.upgrades then global.upgrades = {} end
    if not global.debug then global.debug = false end
    if not global.player_state then global.player_state = {} end
    if not global.player_state[event.player_index] then 
        global.player_state[event.player_index] = {
            bp_hint = 0,
            bp_toggled = false,
            bp_entites_previously_in_range = {}
        } 
    end

    local player = game.get_player(event.player_index)
    local use_tool = hlp.personal_setting_value(player, "botprio-use-selection")
    local disable_msg = hlp.personal_setting_value(player, "botprio-disable-msg")

    if use_tool then
        toggle_button(player, false)
        produce_tool(player)
    elseif not use_toggle then
        toggle_button(player, false)
        no_tool(player, disable_msg, false) -- Not moving
    else --! use_tool = false, use_toggle = true
        if event.name == defines.events.on_player_changed_position then
            no_tool(player, true, true) -- No messaging and moving around!
        else
            local tggld = player.is_shortcut_toggled("bot-prio-shortcut")
            toggle_button(player, not tggld)
        end

    end

end

-- Runs after player selected stuff
local function handle_selection(event)
    if not event.item == 'bot-prioritizer' then return end

    local use_tool = true -- kind of obvious, here
    local player = game.get_player(event.player_index)
    local disable_msg = hlp.personal_setting_value(player, "botprio-disable-msg")
    reprioritize(event.entities, event.tiles, event.surface, event.player_index, use_tool, disable_msg)
end

-- Start it from shortcut instead of hotkey
local function bot_prio_shortcut(event)
    if event.prototype_name == "bot-prio-shortcut" then
        on_hotkey_main(event)
    end
end

-- Track player movement
local function handle_player_move(event)
    -- runs only every 1/10th of a second, could lead to problems
    -- if player moves very fast. But performance is more important.
    --if game.tick % 6 ~= 0 then return end 
    if not global.player_state then return end
    if not global.player_state[event.player_index] then return end
    if not global.player_state[event.player_index].bp_toggled then return end
    event.item = 'bot-prioritizer'
    on_hotkey_main(event)
end

-- On_load to initialize the upgrade tracking table if it is missing
local function on_init()
    -- Table to keep track of upgrades. The built-in function is unreliable.
    if not global.upgrades then global.upgrades = {} end
    if not global.debug then global.debug = false end
    if not global.bp_hint then global.bp_hint = 0 end
end


-- Event hooks
script.on_init(on_init)

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

-- Track movement for "Auto-Mode"
script.on_event(defines.events.on_player_changed_position,handle_player_move)

-- Add a debugging command
commands.add_command("botprio_debug", {"bot-prio.cmd-help"}, hlp.dbg_cmd)