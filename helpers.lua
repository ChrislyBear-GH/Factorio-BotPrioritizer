local helpers = {}

-- Grab settings value
function helpers.personal_setting_value(player, name)
    if player and player.mod_settings and player.mod_settings[name] then
      return player.mod_settings[name].value
    else
      return nil
    end
end


-- Debug rendering
function helpers.debug_draw_bot_area(player, bounding_box)
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

-- Print results
function helpers.print_result(player, count)
    local msg = "" 
    if count > 0 then
        msg = msg .. "Re-Assigned " .. count .. " work orders"
    else
        msg = msg .. "No work orders found"
    end

    if (global.player_state[player.index].bp_method == "Selection Tool") then
        msg = msg .. " in selection."
    else
        msg = msg .. " in personal roboport area."
    end
    player.print(msg)
end

-- Debugging command
function helpers.dbg_cmd(cmd) 
if cmd.name ~= "bp-debug" then return end

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

    if not param or not switch[param] then 
        plr.print({"bot-prio.cmd-help"})
    else
        local s = type(switch[param]) == "function" and switch[param]() or t[v] or {"bot-prio.cmd-help"}
        plr.print(s)
    end
end

-- flib function for deep copying.
-- One function isn't worth a dependency
function helpers.tbl_deep_copy(tbl)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
            -- don't copy factorio rich objects
        elseif object.__self then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end

        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end

        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(tbl)
end

return helpers