-- Helper function
-- local function debug_print(str)
-- 	if global.poflo_debug
-- 	then
-- 		game.print(str)
-- 	end
-- end


-- Produces a selection tool and takes it away again.
local function on_hotkey_main(event)

	local player = game.players[event.player_index]

	-- once in their life, a message is displayed giving a hint	
	global.bprio_hint = global.bprio_hint or 0	
	if global.bprio_hint == 0
	then
		player.print({"bot-prio.hint"})
		global.bprio_hint = 0
	end

	-- put whatever is in the player's hand back in their inventory
	-- and put our selection tool in their hand
	local old_cursor_item = ""
	if player.cursor_stack.valid_for_read
	then
		old_cursor_item	= player.cursor_stack.name
	end
	
	player.clean_cursor()
	if player.cursor_stack ~= nil	then
		if old_cursor_item ~= "bot-prioritizer"	then
			local cursor_stack = player.cursor_stack
      cursor_stack.clear()
      cursor_stack.set_stack({name="bot-prioritizer", type="selection-tool", count = 1})
		end
	end


end

-- Start it from shortcut instead of hotkey
local function bot_prio_shortcut(event)
	-- debug_print("Bot Prio Shortcut")
	if event.prototype_name == "bot-prio-shortcut"
  then
		on_hotkey_main(event)
	end
end

-- Runs after player selected stuff
local function handle_selection(event)
  local function_name = "botprio event"

  if not event.item == 'bot-prioritizer' then return end

  -- Main logic
  local area = event.area
  local player = game.players[event.player_index]
  local force = player.force
  local surface = player.surface

  local entities = event.entities
  local tiles = event.tiles

  -- Remove tool from hand
  player.remove_item({name = 'bot-prioritizer'})
  -- force.chart(surface, area)

  for _, entity in ipairs(entities) do
    -- Handle ghosts
    if entity.type == "entity-ghost" or entity.type == "tile-ghost" then
      local new = surface.create_entity({
        name = entity.name,
        position = entity.position,
        direction = entity.direction,
        force = entity.force,
        player = player,
        inner_name = entity.ghost_name
      })
      new.copy_settings(entity)
      entity.order_deconstruction(force)
    else -- handle all other entities
      if entity ~= nil and entity.to_be_deconstructed() then
        entity.cancel_deconstruction(force)
        entity.order_deconstruction(force)
      end
    end
  end


end


-- Hotkey
script.on_event( "botprio-hotkey", on_hotkey_main )
-- Shortcut button
script.on_event( defines.events.on_lua_shortcut, bot_prio_shortcut )

-- Gather entity ghosts and give bots priority after selction is made
script.on_event(defines.events.on_player_selected_area, handle_selection)