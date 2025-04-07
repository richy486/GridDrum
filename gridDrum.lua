--     ┌─┬─┬─┬─┬─┐            
--     ├─┼─┼─┼─┼─┤    GridDrum
--     ├─┼─┼─┼─┼─┤            
--     ├─┼─┼─┼─┼─┤    richy486
--     ├─┼─┼─┼─┼─┤            
--     ├─┼─┼─┼─┼─┤            
--     └─┴─┴─┴─┴─┘            
--                            

local g
local viewport = { width = 128, height = 64, frame = 0 }
local focus = { x = 1, y = 1, brightness = 15 }
local gridSize = { width = 16, height = 16 }

local buttons = {}
local beatColumn = 0

local out_midi

local play = true

-- Main

function init()
  for x = 1, gridSize.width do
    grid[x] = {}
    for y = 1, gridSize.height do
        grid[x][y] = false
    end
  end
  
  connect()
  midiSetup()
  
  -- Render Style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  -- Render
  update()
  
  clock.run(forever)
  
  print("starting tempo", clock.get_tempo())
end

function forever()
  while true do
    clock.sync(1/4) -- Steps per beat.
    if play then
      beatColumn = beatColumn + 1
      if beatColumn > gridSize.width then
        beatColumn = 1
      end
    end
    update()
  end
end

-- Midi

function midiSetup()
  out_midi = midi.connect(1) 
  print("Midi setup")
  print(out_midi)
end

-- Grid

function connect()
  g = grid.connect()
  g.key = on_grid_key
  g.add = on_grid_add
  g.remove = on_grid_remove
end

function is_connected()
  return g.device ~= nil
end

function on_grid_key(x,y,state)
  if state == 1 then
    value = grid[x][y]
    grid[x][y] = value == false
    focus.x = x
    focus.y = y
    update()
  end
end

function on_grid_add(g)
  print('on_add')
end

function on_grid_remove(g)
  print('on_remove')
end

function update()
  g:all(0)

  for x = 1, gridSize.width do
    for y = 1, gridSize.height do
      if (beatColumn == x) then
        
        if (play == true) and (grid[x][y] == true) then
          -- Selected position is on the line, play the note.
          key = 100
          velocity = 127
          channel = y
          out_midi:note_on(key, velocity, channel)
          out_midi:note_off(key, velocity, channel)
        end
        -- Draw the line.
        g:led(x, y, focus.brightness)
      end
      
      -- Draw selected positions if they are not on the line.
      if (beatColumn ~= x and grid[x][y] == true) then
        g:led(x, y, focus.brightness)
      end
      
    end
  end
  
  g:refresh()
  redraw()
end

-- Interactions on Norns

function key(id,state)
  if id == 2 and state == 1 then
    play = not play
    print("play: ", play)
  elseif id == 3 and state == 1 then
    -- nothing
  end
end

function enc(id,delta)
  if id == 2 then
    params:delta("clock_tempo",delta)
  elseif id == 3 then
    -- nothing
  end
end

-- Render on Norns

function draw_frame()
  screen.level(15)
  screen.rect(1, 1, viewport.width-1, viewport.height-1)
  screen.stroke()
end

function draw_pixel(x,y)
  if beatColumn == x or grid[x][y] == true then
    screen.stroke()
    screen.level(15)
  else 
    screen.stroke()
    screen.level(1)
  end
  
  screen.pixel((x*offset.spacing) + offset.x, (y*offset.spacing) + offset.y)
end

function draw_grid()
  if is_connected() ~= true then return end
  screen.level(1)
  offset = { x = 5, y = 5, spacing = 3 }
  
  for x = 1, gridSize.width do
    for y = 1, gridSize.height do
      draw_pixel(x,y)
    end
  end
  screen.stroke()
end

function draw_label()
  screen.level(15)
  local line_height = 8
  
  insetX = (gridSize.width*offset.spacing) + offset.x + 5
  screen.move(insetX, 0)
  if is_connected() ~= true then
    screen.text('Grid is not connected.')
  else
    screen.text(focus.x..','..focus.y)
    screen.move(insetX, line_height)
    if play then
      screen.text('KEY2 playing')
    else
      screen.text('KEY2 stopped')
    end
    screen.move(insetX, line_height * 2)
    screen.text('ENC2 bpm: '..clock.get_tempo())
    
  end
  
  
  screen.stroke()
end

function redraw()
  screen.clear()
  draw_frame()
  draw_grid()
  draw_label()
  screen.stroke()
  screen.update()
end

-- Utils

function clamp(val,min,max)
  return val < min and min or val > max and max or val
end
