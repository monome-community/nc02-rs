-- innominate (nc02-rs)
-- @tehn
--
-- E1 volume
-- E2 velocity
-- E3 tempo 
-- K2 shuffle
-- K3 draw

function init()
  file = _path.code .. "nc02-rs/lib/nc02-tonal.wav"
  softcut.buffer_read_mono(file,0,0,-1,1,1)
  softcut.enable(1,1)
  softcut.buffer(1,1)
  softcut.level(1,1.0)
  softcut.loop(1,0)
  softcut.loop_start(1,0)
  softcut.loop_end(1,10)
  softcut.position(1,1)
  softcut.fade_time(1,0.01)
  softcut.rate(1,2.0)
  softcut.play(1,1)
  softcut.level_slew_time(1,0.2)

  clock.run(move)
end

x = 2
y = 7

function move()
  while true do
    clock.sync(3/8)
    softcut.level(1,1)
    softcut.position(1,math.random(y)*0.25+x)
    clock.sync(1/8)
    softcut.level(1,0)
  end
end

function enc(n,d)
    
end

function key(n,z)

end

function redraw()
  screen.clear()
  screen.move(64,50)
  screen.aa(1)
  screen.font_face(4)
  screen.font_size(50)
  screen.text_center("0")
  screen.update()
end
