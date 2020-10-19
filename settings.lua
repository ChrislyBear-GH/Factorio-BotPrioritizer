data:extend({
    {
      type = "string-setting",
      name = "botprio-method",
      setting_type = "runtime-per-user",
      default_value = "Selection Tool",
      allowed_values = {"Selection Tool", "Direct Selection", "Auto-Mode"},
      order = 'a[botprio]-a'
    },
    {
      type = "int-setting",
      name = "botprio-toggling-frequency",
      setting_type = "runtime-per-user",
      default_value = 20,
      allowed_values = {6,10,12,15,20,30,60,90,120},
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
    },
    {
      type = "bool-setting",
      name = "botprio-no-inv-checks",
      setting_type = "runtime-per-user",
      default_value = false,
      order = 'a[botprio]-e'
    }
  })