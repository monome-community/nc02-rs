-- adventure
-- 
-- this is a description
-- norns/circle 02

sc = softcut

function init()
  file = _path.code .. "nc02-rs/lib/nc02-tonal.wav"
  softcut.buffer_read_mono(file,0,0,-1,1,1) 
  file = _path.code .. "nc02-rs/lib/nc02-perc.wav"
  softcut.buffer_read_mono(file,0,10,-1,1,1) 
  softcut.enable(1,1)
  softcut.buffer(1,1)
  softcut.level(1,1.0)
  softcut.loop(1,1)
  softcut.loop_start(1,0)
  softcut.loop_end(1,0.5)
  softcut.fade_time(1,0.25)
  softcut.position(1,1)
  softcut.play(1,1)
  
  softcut.enable(2,1)
  softcut.buffer(2,1)
  softcut.level(2,1.0)
  softcut.loop(2,0)
  softcut.loop_start(2,10)
  softcut.loop_end(2,20)
  softcut.fade_time(2,0.25)
  softcut.position(2,10)
  softcut.rate(2,1)
  softcut.play(2,1)
  
  seek = clock.run(advance,1/4)
  clock.run(modulate) 
  clock.run(window)
  clock.run(taps)
end


arp = {0,3,7,10,14}
pos = 1
transpose = 0
loop_pos = 0

function ntor(n)
  return math.pow(2,n/12)
end


function taps()
  while true do
    clock.sync(1/2)
    sc.level(2,1.0)
    sc.position(2,10)
    clock.sync(1/16)
    sc.level(2,0)
  end
end
    

function advance(t)
  while true do
    for i=1,#arp do
      clock.sync(t)
      pos = (pos % #arp) + 1
      sc.rate(1,ntor(arp[pos]+transpose))
      redraw()
    end
  end
end

function modulate()
  while true do
    clock.sync(2)
    transpose = 12
    clock.sync(1)
    transpose = 0
  end
end

function window()
  while true do
    clock.sync(3)
    loop_pos = (loop_pos % 9) + 0.25
    sc.loop_start(1,loop_pos)
    sc.loop_end(1,loop_pos+0.1)
  end
end


function key(n,z)
  if n==3 and z==1 then
    --clock.run(later,1/(math.random(8)))
    clock.cancel(seek)
  end
end

function redraw()
  screen.clear()
  screen.move(63,40)
  screen.font_size(16)
  screen.text(arp[pos])
  screen.move(63,10)
  screen.text(params:get("clock_tempo"))
  screen.update()
end

function enc(n,d)
  if n==3 then
    params:delta("clock_tempo",d)
  end
end