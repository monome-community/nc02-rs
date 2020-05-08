-- innominate (nc02-rs)
-- @tehn
--
-- E1 volume
-- E2 velocity
-- E3 tempo 
-- K2 shuffle
-- K3 draw

sc = softcut

function init()
  file = _path.code .. "nc02-rs/lib/nc02-tonal.wav"
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
  sc.level_slew_time(1,0.2)
  
  file = _path.code .. "nc02-rs/lib/nc02-perc.wav"
  sc.buffer_read_mono(file,0,10,-1,1,1)  sc.enable(2,1)
  sc.buffer(2,1)
  sc.level(2,0)
  sc.loop(2,0)
  sc.loop_start(2,10)
  sc.loop_end(2,20)
  sc.rate(2,1.0)
  sc.position(2,10)
  sc.play(2,1)
  

  --clock.run(move)
  --clock.run(retrig)
  clock.run(shift)
  clock.run(trans)
  clock.run(seek)
  clock.run(beat)
end

function beat()
  while true do
    clock.sync(1)
    sc.position(2,10)
    sc.level(2,1.0)
    clock.sync(1/16)
    sc.level(2,0)
  end
end
    

arp = {0,3,5,7,10,15}
pos = 1
transpose = 0

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

function retrig()
  while true do
    clock.sync(1/4)
    sc.position(1,z)
  end
end

function seek()
  while true do
    clock.sync(0.125)
    sc.rate(1,ntor(arp[pos]+transpose))
    pos = (pos % #arp) + 1
    sc.position(1,z)
  end
end

function move()
  while true do
    clock.sync(3/8)
    sc.level(1,1)
    y = (y+1)%8
    sc.position(1,y*z+x)
    clock.sync(1/8)
    sc.level(1,0)
  end
end

function shift()
  while true do
    clock.sync(2)
    z = (z+0.25) % 10 
    --window(z)
  end
end

function trans()
  while true do
    clock.sync(4)
    transpose = 12
    clock.sync(0.25)
    transpose = 0
  end
end

function enc(n,d)
    
end

function key(n,z)

end

function redraw()
  screen.clear()
  screen.move(63,40)
  screen.text_center(z)
  screen.update()
end
