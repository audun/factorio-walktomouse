local d = require("defines")

local function get_direction(from, to)
   local dir = nil
   local dx = from.x - to.x
   local dy = from.y - to.y
   --   print("X: " .. dx .. " Y: " ..  dy)
   if dx > 1 then
      -- west
      if dy > 1 then dir = defines.direction.northwest
      elseif dy < -1 then dir = defines.direction.southwest
      else dir = defines.direction.west
      end
   elseif dx < -1 then
      -- east
      if dy > 1 then dir = defines.direction.northeast
      elseif dy < -1 then dir = defines.direction.southeast
      else dir = defines.direction.east
      end
   else
      -- north/south
      if dy > 1 then dir = defines.direction.north
      elseif dy < -1 then dir = defines.direction.south
      end
   end
   return dir
end

local function on_tick(tick_event)
   for idx,e in pairs(global.targets) do
      local player = game.players[e.player_index]
      if player and player.valid and tick_event.tick == e.tick then
         dir = get_direction(player.position, e.position)
         if dir then
            player.walking_state = { walking = true, direction = dir }
         else
            table.remove(global.targets, idx)
         end
      end
   end
end

local function on_player_used_capsule(e)
   -- print(serpent.block(e))
   if e.item.valid and e.item.name == d.player_target_item then
      local player = game.players[e.player_index]
      if player and player.valid and player.cursor_stack.valid and player.cursor_stack.can_set_stack(d.player_target_item) then
         player.cursor_stack.set_stack(d.player_target_item)
      end
      global.targets[e.player_index] = e
   end
end

local function on_toggle_move_tool(e)
   -- print(serpent.block(e))
   local player = game.players[e.player_index]
   if player and player.valid then
      if player.cursor_stack.valid and player.cursor_stack.valid_for_read and player.cursor_stack.name == d.player_target_item then
         -- TODO: possible to return what the player had in the hand?
         player.clean_cursor()
      else
         if player.clean_cursor() then
            if player.cursor_stack.valid and player.cursor_stack.can_set_stack(d.player_target_item) then
               player.cursor_stack.set_stack(d.player_target_item)
            end
         end
      end
   end
end

script.on_event("toggle-move-tool", on_toggle_move_tool)

local function setup()
end

local function init()
   global.targets = {}
   global.started_holding = {}
end

script.on_event({defines.events.on_player_used_capsule}, on_player_used_capsule)
script.on_event({defines.events.on_tick}, on_tick)

script.on_init(init)
