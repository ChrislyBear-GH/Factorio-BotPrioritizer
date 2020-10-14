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

function helpers.print_result(player, count, use_tool)
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

-- Debugging command
function helpers.dbg_cmd(cmd) 
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

return helpers