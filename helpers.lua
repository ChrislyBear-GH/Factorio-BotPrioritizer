local helpers = {}

-- Grab settings value
function helpers.personal_setting_value(player, name)
    if player and player.mod_settings and player.mod_settings[name] then
      return player.mod_settings[name].value
    else
      return nil
    end
end

-- Cache player settings in global player state
function helpers.cache_player_settings(player)
    local pidx = player.index

    if not global.player_state[pidx] then 
        global.player_state[pidx] = {
            bp_hint = 0,
            bp_method = "Selection Tool",
            bp_disable_msg = false,
            bp_entity_history = {},
            bp_history_time = 5,
            bp_tick_freq = 20,
            bp_no_inv_checks = false
        } 
    end

    -- Just to catch a missing history table from previous versions
    if not global.player_state[pidx].bp_entity_history then 
        global.player_state[pidx].bp_entity_history = {}
    end

    global.player_state[pidx].bp_method = helpers.personal_setting_value(player, "botprio-method")
    global.player_state[pidx].bp_disable_msg = helpers.personal_setting_value(player, "botprio-disable-msg")
    global.player_state[pidx].bp_no_inv_checks = helpers.personal_setting_value(player, "botprio-no-inv-checks")
    -- Get the player's setting into a global variable for later use!
    if global.player_state[pidx].bp_method == "Auto-Mode" then 
        global.player_state[pidx].bp_history_time = helpers.personal_setting_value(player, "botprio-toggling-time")
        global.player_state[pidx].bp_tick_freq = helpers.personal_setting_value(player, "botprio-toggling-frequency")
    else
        player.set_shortcut_toggled("bot-prio-shortcut", false)
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
    local msg = {}
    if count > 0 then
        msg[#msg+1], msg[#msg+2] = "bot-prio.msg-reassigned", count
    else
        msg[#msg+1] = "bot-prio.msg-none-found"
    end

    if (global.player_state[player.index].bp_method == "Selection Tool") then
        msg[#msg+1] = {"bot-prio.msg-in-selection"}
    else
        msg[#msg+1] = {"bot-prio.msg-in-area"}
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
                return {"bot-prio.msg-debug-mode-on"}
                end,
        ["off"] = function()
                global.debug = false
                return {"bot-prio.msg-debug-mode-off"}
                end,
        ["status"] = function() return {"bot-prio.msg-debug-mode-help-1", global.debug and {"bot-prio.msg-debug-mode-help-2"} or {"bot-prio.msg-debug-mode-help-3"}} end
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