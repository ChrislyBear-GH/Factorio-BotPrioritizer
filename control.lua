
-- Grab settings value
local function personal_setting_value(player, name)
    if player and player.mod_settings and player.mod_settings[name] then
      return player.mod_settings[name].value
    else
      return nil
    end
end

-- Debug rendering
local function debug_draw_bot_area(player, bounding_box)
    local render_id = rendering.draw_rectangle({
        color={1,0,0},
        width=2,
        filled=false,
        left_top=bounding_box[1],
        right_bottom=bounding_box[2],
        surface=player.surface,
        time_to_live=120,
    })
end

-- Add information about upgrades to our table
local function handle_ordered_upgrades(event)
    local nr = event.entity.unit_number

    if not global.upgrades then 
        global.upgrades = {} 
    elseif not global.upgrades[nr] then
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
    if not global.upgrades then global.upgrades = {} end

    for unit_nr, data in pairs(global.upgrades) do
        if not data.e.valid or not data.e or not data.e.to_be_upgraded then
            global.upgrades[unit_nr] = nil
        end
    end
end


local function print_result(player, count, use_tool)
    local msg = "" 
    if count > 0 then
        msg = msg .. "Re-Assigned " .. count .. " work orders"
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
    -- feedback for the player.
    if not disable_msg then 
        print_result(player, cnt, use_tool)
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

local function no_tool(player, disable_msg)
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

        if global.debug then debug_draw_bot_area(player, bbox) end

        local entities = player.surface.find_entities_filtered({
                area=bbox,
                force = player.force
            })

        -- No tiles will be handed over, because
        -- deconstructible-tile-proxy will already be
        -- in the entities table.
        local tiles = {}
        
        -- Do the work...
        reprioritize(entities, tiles, player.surface, player.index, use_tool, disable_msg)    
    end
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
        } 
    end

    local player = game.get_player(event.player_index)
    local use_tool = personal_setting_value(player, "botprio-use-selection")
    local disable_msg = personal_setting_value(player, "botprio-disable-msg")

    if use_tool then
        produce_tool(player)
    else
        no_tool(player, disable_msg)
    end

end

-- Runs after player selected stuff
local function handle_selection(event)
    if not event.item == 'bot-prioritizer' then return end

    local use_tool = true -- kind of obvious, here
    local player = game.get_player(event.player_index)
    local disable_msg = personal_setting_value(player, "botprio-disable-msg")
    reprioritize(event.entities, event.tiles, event.surface, event.player_index, use_tool, disable_msg)
end

-- Start it from shortcut instead of hotkey
local function bot_prio_shortcut(event)
    if event.prototype_name == "bot-prio-shortcut" then
        on_hotkey_main(event)
    end
end


-- Debugging command
local function dbg_cmd(cmd) 
    if cmd.name ~= "botprio_debug" then return end

    local plr = game.get_player(cmd.player_index)
    local param = cmd.parameter

    local switch = {
        ["on"] = function()
                global.debug = true
                return "Debug mode enabled."
                end,
        ["off"] = function()
                global.debug = false
                return "Debug mode disabled."
                end,
        ["status"] = function() return "Debug mode is " .. (global.debug and "enabled." or "disabled.") end
    }

    if not param or  not switch[param] == nil then 
        plr.print({"bot-prio.cmd-help"})
    else
        local s = type(switch[param]) == "function" and switch[param]() or t[v] or {"bot-prio.cmd-help"}
        plr.print(s)
    end
end


-- On_load to initialize the upgrade tracking table if it is missing
local function on_init()
    -- Table to keep track of upgrades. The built-in function is unreliable.
    if not global.upgrades then global.upgrades = {} end
    if not global.debug then global.debug = false end
    if not global.bprio_hint_tool then global.bprio_hint_tool = 0 end
end


-- Event hooks
script.on_init(on_init)

-- Hotkey
script.on_event( "botprio-hotkey", on_hotkey_main)
-- Shortcut button
script.on_event(defines.events.on_lua_shortcut, bot_prio_shortcut)

-- Handle upgrade orders because get_upgrade_target() is unreliable
script.on_event(defines.events.on_marked_for_upgrade, handle_ordered_upgrades)
script.on_event(defines.events.on_cancelled_upgrade, handle_cancelled_upgrades)

-- Gather entity ghosts and give bots priority after selction is made
script.on_event(defines.events.on_player_selected_area, handle_selection)
script.on_event(defines.events.on_player_alt_selected_area, handle_selection)

-- Add a debugging command
commands.add_command("botprio_debug", {"bot-prio.cmd-help"}, dbg_cmd)