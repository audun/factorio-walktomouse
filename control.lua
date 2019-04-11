require('util')
local d = require("defines")
local NEUTRAL = {direction = defines.riding.direction.straight, acceleration = defines.riding.acceleration.nothing}
local PATH_RESOLUTION = 2

--local MASK = {"object-layer", "water-tile"}
local MASK = {"player-layer", "train-layer"}
--local MASK = {}
local FLAGS = {cache = false, low_priority = false, allow_destroy_friendly_entities = false, allow_destroy_neutral_entities = false, allow_destroy_enemy_entities = false, prefer_straight_paths = false}

local preq = {}
local function path_to_position_entity(player, position)
   game.map_settings.path_finder.goal_pressure_ratio = 2
   game.map_settings.path_finder.max_steps_worked_per_tick = 5000
   game.print(game.map_settings.path_finder.goal_pressure_ratio)
   if player and player.valid and player.character then
      print(serpent.line({position, player.character.prototype.collision_box}))
      -- local box = player.character.prototype.collision_box
      -- box.left_top.x = box.left_top.x - 0.1
      -- box.left_top.y = box.left_top.y - 0.1
      -- box.right_bottom.x = box.right_bottom.x + 0.1
      -- box.right_bottom.y = box.right_bottom.y + 0.1
      -- print(serpent.line(box))
      local args = {
         entity = player.character,
         -- bounding_box = box,
         -- collision_mask = MASK,
         start = player.position,
         goal = position,
         -- force = player.force,
         radius = 1,
         -- can_open_gates = true,
         pathfind_flags = FLAGS,
         path_resolution_modifier = PATH_RESOLUTION,
      }
      print(serpent.block(args))
      -- local id = player.surface.request_path(args)
      local id = player.surface.request_path_for_entity(args)
      global.path_requests[id] = {id = id, player = player, position = position}
      game.print('started pathfinding')
   end
end

local function path_to_position(player, position)
   game.map_settings.path_finder.goal_pressure_ratio = 1
   game.map_settings.path_finder.max_steps_worked_per_tick = 5000
   game.print(game.map_settings.path_finder.goal_pressure_ratio)
   if player and player.valid and player.character then
      print(serpent.line({position, player.character.prototype.collision_box}))
      local box = player.character.prototype.collision_box
      -- box.left_top.x = box.left_top.x - 0.1
      -- box.left_top.y = box.left_top.y - 0.1
      -- box.right_bottom.x = box.right_bottom.x + 0.1
      -- box.right_bottom.y = box.right_bottom.y + 0.1
      -- print(serpent.line(box))
      local ignore = player.surface.find_entities_filtered{force='neutral'}
      table.insert(ignore, player.character)
      print("to ignore: " .. #ignore)
      local args = {
         bounding_box = box,
         collision_mask = MASK,
         start = player.position,
         goal = position,
         -- ignore = { player.character },
         ignore = ignore,
         force = player.force,
         radius = 1,
         can_open_gates = true,
         pathfind_flags = FLAGS,
         path_resolution_modifier = PATH_RESOLUTION,
      }
      -- print(serpent.block(args))
      -- local id = player.surface.request_path(args)
      local id = player.surface.request_path(args)
      global.path_requests[id] = {id = id, player = player, position = position}
      game.print('started pathfinding')
   end
end

local function get_direction_for_pathfinding(from, to)
   local dir = nil
   local dx = from.x - to.x
   local dy = from.y - to.y
--   print("X: " .. dx .. " Y: " ..  dy)
   if dx > 0.1 then
      -- west
      if dy > 0.1 then dir = defines.direction.northwest
      elseif dy < -0.1 then dir = defines.direction.southwest
      else dir = defines.direction.west
      end
   elseif dx < -0.1 then
      -- east
      if dy > 0.1 then dir = defines.direction.northeast
      elseif dy < -0.1 then dir = defines.direction.southeast
      else dir = defines.direction.east
      end
   else
      -- north/south
      if dy > 0.1 then dir = defines.direction.north
      elseif dy < -0.1 then dir = defines.direction.south
      end
   end
   return dir
end

local function on_path_request_finished(e)
   print(serpent.line({path = e.path, id = e.id, try_again_later = e.try_again_later}))
   local request = global.path_requests[e.id]
   if not request then
      print("No request?")
      return nil
   end
   local player = request.player
   if not e.path then
      game.print('No path') -- TODO: Flying tag
   else
      global.active_paths = global.active_paths or {}
      local surface = player.surface
      local start = nil
      local last = nil
      local current_dir = 0
      local filtered = {}
      local unfiltered = {}
      for idx, waypoint in pairs(e.path) do
         -- rendering.draw_circle({
         --       color = {r = 0, g = 0, b = 1, a = 0.5},
         --       radius = 0.2,
         --       --               width = 1,
         --       filled = true,
         --       target = waypoint.position,
         --       surface = surface,
         --       time_to_live = 900,
         --       draw_on_ground = false
         -- })
         -- print(serpent.line(waypoint.position))
         table.insert(unfiltered, waypoint.position)

         if start == nil then
            start = waypoint.position -- idx 1
         else
            if current_dir == nil then -- idx 2
               current_dir = get_direction_for_pathfinding(start, waypoint.position)
            else
                -- idx 3 -> n
               local new_dir = get_direction_for_pathfinding(last, waypoint.position)
               -- print(serpent.line{current_dir = current_dir, new_dir = new_dir})
               if new_dir ~= current_dir then
                  rendering.draw_circle({
                        color = {r = 0, g = 0, b = 1, a = 0.5},
                        radius = 0.8,
                        --               width = 1,
                        filled = true,
                        target = waypoint.position,
                        surface = surface,
                        time_to_live = 300,
                        draw_on_ground = true
                  })
                  table.insert(filtered, waypoint.position)
                  current_dir = new_dir
                  start = waypoint.position
               end
               -- rendering.draw_line({
               --       color = {r = 1, g = 0, b = 0, a = 0.5},
               --       width = 1,
               --       from = start,
               --       to = waypoint.position,
               --       surface = surface,
               --       time_to_live = 300,
               -- })
            end
         end
         last = waypoint.position
      end
      table.insert(filtered, last) -- TODO: just add last in path
      print(serpent.line(unfiltered))
      global.active_paths[player.index] = { player=player, filtered=util.table.deepcopy(filtered), waypoint = 1, unfiltered = util.table.deepcopy(unfiltered) }
      print(serpent.line(global.active_paths[player.index]))
   end
end

script.on_event({defines.events.on_script_path_request_finished}, on_path_request_finished)

local function get_direction(from, to)
   local dir = nil
   local dx = from.x - to.x
   local dy = from.y - to.y
   -- print("X: " .. dx .. " Y: " ..  dy)
   if dx > 1 then
      -- west
      if dy > 2.5 then dir = defines.direction.northwest
      elseif dy < -2.5 then dir = defines.direction.southwest
      else dir = defines.direction.west
      end
   elseif dx < -1 then
      -- east
      if dy > 2.5 then dir = defines.direction.northeast
      elseif dy < -2.5 then dir = defines.direction.southeast
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
   -- for idx, player in pairs(game.players) do
   --    rendering.draw_circle({
   --       color = {r = 0, g = 1, b = 0, a = 0.5},
   --       radius = 0.1,
   --       --               width = 1,
   --       filled = true,
   --       target = player.position,
   --       surface = player.surface,
   --       time_to_live = 2,
   --       draw_on_ground = false
   --    })
   -- end

   global.active_paths = global.active_paths or {}
   for idx,e in pairs(global.targets) do
      local player = game.players[e.player_index]
      if global.active_paths[e.player_index] and tick_event.tick ~= e.tick then
         print("dropping active_path")
         global.active_paths[e.player_index] = nil
      end

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
            if tick_event.tick == e.tick then
               local dir = get_direction(player.position, e.position)
               if dir then
-- TODO: stop moving for now
--                  player.walking_state = { walking = true, direction = dir }
               else
                  table.remove(global.targets, idx)
               end
            elseif global.started_holding[e.player_index] ~= nil then
               local h = global.started_holding[e.player_index]
               -- TODO: Consider changed game.speed setting?
               if e.tick - h.tick < 10 then
                  -- move to where player clicked first, not where he let go
                  path_to_position(player, h.position, 0)
                  -- path_to_position_entity(player, h.position, 0)
               end
               global.started_holding[e.player_index] = nil
               table.remove(global.targets, idx)
            end
         end
      end
   end
   for idx,p in pairs(global.active_paths) do
      if not p.unfiltered then
         print("no path?")
         table.remove(global.active_paths, idx)
      else
         local path = p.unfiltered
         -- print(serpent.line{p.waypoint, path})
         -- if p.waypoint == 1 and #p.unfiltered >= 2 then
         --    p.waypoint = p.waypoint + 2
         --    p.player.teleport(p.unfiltered[2])
         -- else
         if true then
            print("not following")
            table.remove(global.active_paths, idx)
         elseif p.waypoint >= #path then
            print('at end?')
            table.remove(global.active_paths, idx)
         else
            local target = path[p.waypoint]
            local pos = p.player.position
            local dir = get_direction_for_pathfinding(pos, target)
            if dir then
               p.player.walking_state = { walking = true, direction = dir }
            else
               -- print('waypoint')
               p.waypoint = p.waypoint + 1
               if p.waypoint > #path then
                  print('at end?')
                  table.remove(global.active_paths, idx)
               else
                  local target = path[p.waypoint+1]
                  local pos = p.player.position
                  local dir = get_direction_for_pathfinding(pos, target)
                  if dir then
                     p.player.walking_state = { walking = true, direction = dir }
                  end
               end
            end
         end
      end
   end
end

local function on_player_used_capsule(e)
   print("on_player_used_capsule")
   print(serpent.block(e))
   if e.item.valid and e.item.name == d.player_target_item then
      if global.active_paths[e.player_index] then
         print("dropping active_path")
         global.active_paths[e.player_index] = nil
      end
      local player = game.players[e.player_index]
      if player and player.valid and player.cursor_stack.valid and player.cursor_stack.can_set_stack(d.player_target_item) then
         player.cursor_stack.set_stack(d.player_target_item)
      end
      if not global.started_holding[e.player_index] then
         global.started_holding[e.player_index] = e
      end
      global.targets[e.player_index] = e
   end
end

local function on_toggle_move_tool(e)
   print(serpent.block(e))
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
   global.targets = global.targets or {}
   global.started_holding = global.started_holding or {}
   global.path_requests = global.path_requests or {}
   global.active_paths = global.active_paths or {}
end

script.on_event({defines.events.on_player_used_capsule}, on_player_used_capsule)
script.on_event({defines.events.on_tick}, on_tick)

script.on_init(init)
script.on_configuration_changed(init)
