data:extend({
  {
    type = "bool-setting",
    name = "storage-finder-setting-show-colors",
    setting_type = "runtime-per-user",
    default_value = true,
    order = 'a[storage-finder]-a'
  },
  {
    type = "bool-setting",
    name = "storage-finder-setting-show-distance",
    setting_type = "runtime-per-user",
    default_value = true,
    order = 'a[storage-finder]-b'
  },
  {
    type = "bool-setting",
    name = "storage-finder-setting-show-coordinates",
    setting_type = "runtime-per-user",
    default_value = true,
    order = 'a[storage-finder]-c'
  },
  {
    type = "bool-setting",
    name = "storage-finder-setting-show-entity-names",
    setting_type = "runtime-per-user",
    default_value = false,
    order = 'a[storage-finder]-e'
  },
  {
    type = "int-setting",
    name = "storage-finder-max-results",
    setting_type = "runtime-per-user",
    default_value = 30,
    minimum_value = 1,
    maximum_value = 100000,
    order = 'a[storage-finder]-f'
  },
  {
    type = "string-setting",
    name = "storage-finder-selected-entity-names",
    setting_type = "runtime-per-user",
    allow_blank = true,
    default_value = "",
    order = 'a[storage-finder]-g'
  },
  {
    type = "bool-setting",
    name = "storage-finder-hide-filtered-storages",
    setting_type = "runtime-per-user",
    default_value = true,
    order = 'a[storage-finder]-h'
  }
})
