local d = require("defines")
local NEUTRAL = {direction = defines.riding.direction.straight, acceleration = defines.riding.acceleration.nothing}

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

local function get_riding_state(player, v, o, t)
   local radians = o * 2*math.pi
   local angle = radians + math.pi / 2
   local perp_angle = radians

   local v1 = { x = t.x-v.x, y = t.y-v.y }
   local dir = v1.x * math.sin(angle) - v1.y * math.cos(angle)
   local acc = v1.x * math.sin(perp_angle) - v1.y * math.cos(perp_angle)

   -- local t3 = { x = v.x + 10 * math.cos(perp_angle), y = v.y + 10 * math.sin(perp_angle) }
   -- local t2 = { x = v.x + 10 * math.cos(angle), y = v.y + 10 * math.sin(angle) }
   -- rendering.draw_line({
   --       color = {r = 1, g = 0, b = 0, a = 0.5},
   --       width = 1,
   --       from = v,
   --       to = t2,
   --       surface = player.surface,
   --       time_to_live = 2,
   -- })

   -- rendering.draw_line({
   --       color = {r = 1, g = 0, b = 0, a = 0.5},
   --       width = 1,
   --       from = v,
   --       to = t2,
   --       surface = player.surface,
   --       time_to_live = 2,
   -- })

   -- rendering.draw_line({
   --       color = {r = 0, g = 0, b = 1, a = 0.5},
   --       width = 1,
   --       from = v,
   --       to = t3,
   --       surface = player.surface,
   --       time_to_live = 2,
   -- })

   local res = {}
   if dir < -0.2 then
      res.dir = defines.riding.direction.left
   elseif dir > 0.2 then
      res.dir = defines.riding.direction.right
   else
      res.dir = defines.riding.direction.straight
   end

   if v1.x*v1.x + v1.y*v1.y < 4 then -- brake when mouse over vehicle
      res.acc = defines.riding.acceleration.braking
   elseif acc < -0.2 then
      res.acc = defines.riding.acceleration.reversing
   elseif acc > 0.2 then
      res.acc = defines.riding.acceleration.accelerating
   else
      res.acc = defines.riding.acceleration.braking
   end

   return {direction = res.dir, acceleration = res.acc}
end

local function on_tick(tick_event)
   for idx,e in pairs(global.targets) do
      local player = game.players[e.player_index]
      if player and player.valid then
         if player.driving then
            if tick_event.tick ~= e.tick then
               player.riding_state = NEUTRAL
               table.remove(global.targets, idx)
            else
               local vehicle = player.vehicle
               local state = get_riding_state(player, vehicle.position, vehicle.orientation, e.position)
               local p_state = player.riding_state
               if p_state.direction ~= state.direction or p_state.acceleration ~= state.acceleration then
                  player.riding_state = state
               end
            end
         else
            local dir = get_direction(player.position, e.position)
            if dir and tick_event.tick == e.tick then
               player.walking_state = { walking = true, direction = dir }
            else
               table.remove(global.targets, idx)
            end
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

local function init()
   global.targets = {}
   global.started_holding = {}
end

script.on_event({defines.events.on_player_used_capsule}, on_player_used_capsule)
script.on_event({defines.events.on_tick}, on_tick)

script.on_init(init)
