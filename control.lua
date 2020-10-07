-- Table to keep track of upgrades. The built-in function is unreliable.
global.upgrades = global.upgrades or {}



-- Produces a selection tool and takes it away again.
local function on_hotkey_main(event)
  local player = game.players[event.player_index]
  
	-- once in a save game, a message is displayed giving a hint	
	global.bprio_hint = global.bprio_hint or 0	
	if global.bprio_hint == 0
	then
		player.print({"bot-prio.hint"})
		global.bprio_hint = 1
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
	if event.prototype_name == "bot-prio-shortcut" then
		on_hotkey_main(event)
	end
end

-- Add information about upgrades to our table
local function handle_ordered_upgrades(event)
  local ent = event.entity
  local nr = event.entity.unit_number
  local trg = event.target.name

  if global.upgrades then
    global.upgrades = global.upgrades
  else
    global.upgrades = {}
  end
  if not global.upgrades[nr] then
    global.upgrades[nr] = { e = ent, t = trg }
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
  if global.upgrades then
    global.upgrades = global.upgrades
  else
    global.upgrades = {}
  end

  for unit_nr, data in pairs(global.upgrades) do
    if not data.e.valid or not data.e or not data.e.to_be_upgraded then
      global.upgrades[unit_nr] = nil
    end
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

  -- Keep updgrade table clean
  remove_stale_upgrades()

  for _, entity in ipairs(entities) do
    if entity.type == "entity-ghost" or entity.type == "tile-ghost" then -- handle ghosts
      local new = entity.clone({position = entity.position, force = entity.force})
      -- entity.die(entity.force)
      entity.order_deconstruction(force)
    elseif entity ~= nil and entity.to_be_deconstructed() then -- handle entities to be deconstructed
      entity.cancel_deconstruction(force)
      entity.order_deconstruction(force)
    elseif entity ~= nil and entity.to_be_upgraded() then -- handle upgrades
      local up_trg = global.upgrades[entity.unit_number].t
      if up_trg ~= nil then
        entity.cancel_upgrade(force)
        entity.order_upgrade({force = entity.force, target = up_trg, player = player})
      else
        player.print("ERROR: Couldn't find out upgrade target.")
      end
    end
  end
end


-- Hotkey
script.on_event( "botprio-hotkey", on_hotkey_main)
-- Shortcut button
script.on_event( defines.events.on_lua_shortcut, bot_prio_shortcut)

-- Gather entity ghosts and give bots priority after selction is made
script.on_event(defines.events.on_player_selected_area, handle_selection)

-- Handle upgrade orders because get_upgrade_target() is unreliable
script.on_event(defines.events.on_marked_for_upgrade, handle_ordered_upgrades)
script.on_event(defines.events.on_cancelled_upgrade, handle_cancelled_upgrades)