-- innominate (nc02-rs)
-- @tehn
--
-- E1 volume
-- E2 velocity
-- E3 regularity 
-- K2 shuffle
-- K3 draw

sc = softcut

function init()
  norns.enc.sens(3,8)

  file = paths.this.lib.."nc02-tonal.wav"
  sc.buffer_read_mono(file,0,0,-1,1,1)
  sc.enable(1,1)
  sc.buffer(1,1)
  sc.level(1,1.0)
  sc.loop(1,0)
  sc.loop_start(1,0)
  sc.loop_end(1,10)
  sc.position(1,0)
  sc.fade_time(1,0.05)
  sc.rate(1,1.0)
  sc.play(1,1)
  sc.pan(1,-0.2)
  sc.level_slew_time(1,0.2)
  
  file = paths.this.lib.."nc02-perc.wav"
  sc.buffer_read_mono(file,0,10,-1,1,1)
  sc.enable(2,1)
  sc.buffer(2,1)
  sc.level(2,0)
  sc.loop(2,0)
  sc.loop_start(2,10)
  sc.loop_end(2,20)
  sc.rate(2,1.5)
  sc.position(2,10)
  sc.pan(2,0.2)
  sc.play(2,1)
  
  file = paths.this.lib.."faraway.wav"
  sc.buffer_read_mono(file,0,20,-1,1,1)
  sc.enable(3,1)
  sc.buffer(3,1)
  sc.level(3,1)
  sc.loop(3,1)
  sc.loop_start(3,20)
  sc.loop_end(3,29.5)
  sc.rate(3,1.0)
  sc.position(3,20)
  sc.play(3,1)
  sc.rate_slew_time(3,5)
  sc.fade_time(3,1)
  

  clock.run(shift)
  clock.run(trans)
  clock.run(seek)
  clock.run(beat)
  clock.run(windy)

  clock.run(redraw_clock)
end

function redraw_clock()
  while true do
    clock.sleep(1/15)
    redraw()
  end
end


b = 0

function beat()
  while true do
    clock.sync(1/math.random(complexity))
    sc.position(2,10+b)
    sc.level(2,1.0)
    clock.sleep(1/32*math.random(3))
    sc.level(2,0)
    b = (b + 0.05) % 2
  end
end

function windy()
  while true do
    clock.sleep(math.random(5))
    sc.rate(3,1.25-math.random()/2)
  end
end
    

options = {
  {0,3,5,7,10,15},
  {0,-12,7,10,7,12,5},
  {0,12,5,0,12,10,17},
  {0,0,0,3,12,5}
}

arp = {table.unpack(options[1])}
pos = 1
transpose = 0
complexity = 1

function window(p)
  sc.loop_start(1,p)
  sc.loop_end(1,p+0.2)
end

function ntor(n)
  return math.pow(2,n/12)
end

x = 0
y = 1
z = 0

function seek()
  while true do
    clock.sync(1/4)
    sc.rate(1,ntor(arp[pos]+transpose))
    pos = (pos % #arp) + 1
    sc.position(1,z)
  end
end

function shift()
  while true do
    clock.sync(#arp/2)
    z = (z+0.25) % 3
  end
end

function trans()
  while true do
    clock.sync(#arp/4)
    transpose = -12
    clock.sync(0.25)
    transpose = 0
    b=b+2
  end
end

function enc(n,d)
  if n==1 then
    params:delta("output_level",d)
  elseif n==2 then
    params:delta("clock_tempo",d)
  elseif n==3 then
    complexity = util.clamp(complexity+d,1,4)
  end
end

function key(n,z)
  if n==3 and z==1 then
    pos = 1
    arp = {table.unpack(options[math.random(#options)])}
    z=math.random(3)-1
  elseif n==2 and z==1 then
    for i=1,2 do
      table.insert(arp,math.random(#arp),arp[math.random(#arp)]) -- clone random element
    end
    tab.print(arp)
    
  end
end


c = {}
c.x = 63
c.y = 63
c.px = 63
c.py = 63
c.dx = 5
c.dy = -5

function update_c()
  c.px = c.x
  c.py = c.y
  c.dx = util.clamp(c.dx + (math.random()-0.5)*complexity,-10,10)
  c.dy = util.clamp(c.dy + (math.random()-0.5)*complexity,-10,10)
  c.x = (c.x + c.dx) % 140
  c.y = (c.y + c.dy) % 80
end


function redraw()
  screen.clear()
  update_c()
  if (math.abs(c.px-c.x)<50) and (math.abs(c.py-c.y)<50) then
    screen.level(1)
    screen.move(c.x,c.y)
    screen.line(c.px,c.py)
    screen.stroke()
  end
  screen.level(15)
  local pp=64-#arp
  for i=1,#arp do
    screen.move(pp,50)
    screen.line_rel(0,-arp[i]*2-2)
    screen.stroke()
    pp = pp + 2
  end
  screen.update()
end
