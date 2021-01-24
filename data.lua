-- Bot Prioritizer mod for Factorio
--
-- This mod provides a tool for giving the player's personal robots priority over
-- the regular base robots.
--
-- The tool is a selection tool - drag it over some ghosts and it clears the work
-- assignment of the base robots so that the personal robots can take over.
--
-- the bot-prioritizer selection tool is automatically created when the user
-- invokes the hot key, and is destroyed when they finish selecting the area to
-- be prioritized. The tool is not craftable, and requires no research.

data:extend(
{
	{
		type = "selection-tool",
		name = "bot-prioritizer",
		show_in_library = false,
		icon = "__BotPrioritizer__/graphics/bot-prioritizer.png",
		flags = {"hidden", "only-in-cursor"},
		always_include_tiles = true,
		subgroup = "tool",
		order = "c[automated-construction]-b[tree-deconstructor]",
		stack_size = 1,
		icon_size = 64,
		icon_mipmaps = 4,
		selection_color = { r = 0.7, g = 0, b = 1 },
		alt_selection_color = { r = 0, g = 0, b = 1 },
		selection_mode = {"deconstruct", "same-force", 'upgrade', 'cancel-upgrade'},
		alt_selection_mode = {"deconstruct", "same-force", 'upgrade', 'cancel-upgrade'},
		selection_cursor_box_type = "entity",
		alt_selection_cursor_box_type = "not-allowed",
	}

	,
	{
		type = "shortcut",
		name = "bot-prio-shortcut",
		order = "b[blueprints]-h[bot-prio]",
		action = "lua",
		associated_control_input = "botprio-hotkey",
		toggleable = true,
		icon =
		{
		  filename = "__BotPrioritizer__/graphics/bot-prioritizer.png",
		  priority = "extra-high-no-scale",
		  size = 64,
		  icon_mipmaps = 4,
		  scale = 1,
		  flags = {"icon"}
		}
	}
	,
	{
		type = "custom-input",
		name = "botprio-hotkey",
		key_sequence = "CONTROL + G",
		consuming = "none"
	}
})