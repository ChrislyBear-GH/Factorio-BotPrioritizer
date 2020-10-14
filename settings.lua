data:extend({
    {
      type = "bool-setting",
      name = "botprio-use-selection",
      setting_type = "runtime-per-user",
      default_value = true,
      order = 'a[botprio]-a'
    },
    {
      type = "bool-setting",
      name = "botprio-toggling",
      setting_type = "runtime-per-user",
      default_value = false,
      order = 'a[botprio]-b'
    },
    {
      type = "int-setting",
      name = "botprio-toggling-time",
      setting_type = "runtime-per-user",
      default_value = 5,
      allowed_values = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 30},
      order = 'a[botprio]-c'
    },
    {
      type = "bool-setting",
      name = "botprio-disable-msg",
      setting_type = "runtime-per-user",
      default_value = false,
      order = 'a[botprio]-d'
    }
  })