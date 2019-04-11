local d = require("defines")

local player_remote_capsule = table.deepcopy(data.raw["capsule"]["poison-capsule"])

player_remote_capsule.name = d.player_target_item
player_remote_capsule.order = '__a'
player_remote_capsule.icon = "__core__/graphics/empty.png"
player_remote_capsule.icon_size = 1
player_remote_capsule['capsule_action']['attack_parameters']['cooldown'] = 1
player_remote_capsule['capsule_action']['attack_parameters']['range'] = 125
player_remote_capsule['capsule_action']['attack_parameters']['ammo_type']['action'] = nil
player_remote_capsule.stack_size = 1
-- print(serpent.block(data.raw["capsule"]['poison-capsule']))
player_remote_capsule.flags =  { "only-in-cursor", "hidden" }
   
data:extend({player_remote_capsule})

data:extend({{
      type = "custom-input",
      name = "toggle-move-tool",
      key_sequence = "N",
      consuming = "none"
}})




