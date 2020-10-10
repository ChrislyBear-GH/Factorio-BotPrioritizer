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
      name = "botprio-disable-msg",
      setting_type = "runtime-per-user",
      default_value = false,
      order = 'a[botprio]-b'
    }
  })