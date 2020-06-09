-- dotty (nc02-rs)
-- @jemfiner

-- E1 volume
-- E2 tempo
-- E3 rhythmic change 
-- K2 shuffle
-- K3 draw

sc = softcut
pos_1 = math.random(1)
pos_2 = math.random(2)
pos_3 = math.random(5)
pitch = {0,2,4,7,9,12}
--pitch_2 = {0,3,5,7,12}
birdpitch = {-12,-5,0,-12,0,-5}
tpstns = {0,5,7}
primes = {1,1,2,2,3,3,5,5}
transpose = 0
note = 0
complexity = 2
final_pos_1 = 0
final_pos_2 = 0
final_pos_3 = 0
draw = 0
volume = 0.75
x = math.random(128)
y = math.random(64)
birdsync = 1
birdrate = 0
noterange = #pitch

params:set("clock_tempo",90)

function init()
  file = _path.code .. "nc02-rs/lib/nc02-tonal.wav"
  sc.buffer_read_mono(file,0,0,-1,1,1) 
  file = _path.code .. "nc02-rs_jf/lib/dawnchorus.wav"
  sc.buffer_read_stereo(file,0,20,-1,1,1) 
  --voice_1
  sc.enable(1,1)
  sc.buffer(1,1)
  sc.level(1,1.25)
  sc.loop(1,0)
  sc.loop_start(1,0)
  sc.loop_end(1,5)
  sc.fade_time(1,0.05)
  sc.position(1,0)
  sc.rate(1,1)
  sc.rate_slew_time(1,0.05)
  sc.post_filter_lp (1,1)
  sc.pan(1,0)
  sc.play(1,1)
  --voice_2
  sc.enable(2,1)
  sc.buffer(2,1)
  sc.level(2,1.0)
  sc.loop(2,0)
  sc.loop_start(2,10)
  sc.loop_end(2,10.1)
  sc.fade_time(2,0.15)
  sc.position(2,10)
  sc.rate(2,1)
  sc.post_filter_lp (2,1)
  sc.play(2,1)
   --voice_3
  for i=3,4 do
   sc.enable(i,1)
   sc.buffer(i,i==1 and 1 or 2)
   sc.level(i,0.15)
   sc.loop(i,0)
   sc.position(i,20)
   sc.loop_start(i,20)
   sc.loop_end(i,24)
   sc.fade_time(i,0.05)
   sc.rate(i,0.75)
   sc.rate_slew_time(i,0.5)
   sc.post_filter_lp (i,1)
   sc.play(i,1)
  end
  
   audio.level_dac(volume)
   
  clock.run(voice_1)
  clock.run(pstn_1)
  clock.run(notes)
  clock.run(transposition)
  clock.run(voice_2)
  clock.run(pstn_2)
  clock.run(voice_3)
  clock.run(birdsong)
  clock.run(display)
end

function ntor(n)
-- thanks @tehn
  return math.pow(2,n/12)
end

function shift(tbl)
--inserts contents of random index at index + 1
    index = math.random(#tbl)
    newindex = 1
    temp = tbl[index]
    table.remove(tbl,index)
    newindex = index+1
    newindex = newindex>#tbl and 1 or newindex
    table.insert(tbl,newindex,temp)
end

function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function notes()
  while true do
    for i=1,noterange do
      clock.sync(2/3)
      note = pitch[i]
    end
  end
end

function birdsong()
  while true do
    for i=1,#birdpitch do
      clock.sync(birdsync*8)
      birdrate = birdpitch[i]
    end
  shift(pitch)
  end
end

function transposition()
  while true do
    clock.sync(5)
    shift(pitch)
    transpose  = tpstns[math.random(#tpstns)]
  end
end
      
function pstn_1()
   clock.sync(5)
   pos_1 = (pos_1+(0.01*complexity*2))%1
end

function pstn_2()
   clock.sync(7)
   pos_2 = (pos_1+0.01)%4
end
    
function display()
  while true do
    clock.sync(10/params:get("clock_tempo"))
    redraw()
  end
end

function voice_1()
  while true do
    for i=1,primes[complexity] do
     clock.sync(2/3)
     sc.level(1,draw > 0 and 0.75 or 1.25)
     sc.position(1,pos_1 + (i/2))
     sc.loop_start(1,pos_1 + (i/2))
     final_pos_1 = pos_1 + (i/2)
     sc.rate(1,draw > 0 and ntor(note+transpose) or 1)
    end
  end
end

function voice_2()
  while true do
    for i=1,primes[complexity + 1] do
     clock.sync(2/5)
     sc.position(2,pos_2 + (i/2))
     sc.loop_start(2,pos_2 + (i/2))
     final_pos_2 = pos_2 + (i/2)
     sc.pan(2,2*math.random()-1)
     sc.pan_slew_time(2,2*clock.get_beat_sec()/5)
    end
  end
end

function voice_3()
  while true do
    pos_3 = (pos_3 + 0.025) % 4
    for j = 3,4 do
     sc.position(j,pos_3 + 20)
     sc.loop_start(j,pos_3 + 20)
     sc.loop_end(j,pos_3 + 20 + (birdsync*clock.get_beat_sec()))
     sc.rate_slew_time(j,birdsync*clock.get_beat_sec())
     sc.rate(j,ntor(birdrate))
    end
    final_pos_3 = pos_3
    sc.pan(3,-1)
    sc.pan(4,1)
    clock.sync(birdsync)
  end
end

function redraw()
  if draw < 2 then
  screen.aa(1)
  screen.clear()
  for i = 1,12 do
    for j = 1,5 do
     screen.level(math.random(complexity+1)-1)
     screen.circle(i*15 - 11,j * 11,5)
     screen.fill()
     screen.stroke()
    end
   end
  --voice 1
  screen.level(15)
  screen.circle(9 + (125/5)*final_pos_1,10 + (draw == 0 and 0 or (note*3.75)),9)
  screen.fill()
  screen.stroke()
  --voice 2
  screen.level(14)
  screen.circle(8 + (125/11)*final_pos_2,35,8)
  screen.fill()
  screen.stroke()
  --birds
  screen.level(13)
  screen.circle(7 + (125/11)*final_pos_3,52 + birdrate,7)
  screen.fill()
  screen.stroke()
  screen.update()
  else
    screen.font_size(8)
    screen.move(0,60)
    screen.level(3)
    screen.text("draw !")
    screen.level(15)
    screen.pixel(x,y)
    screen.fill()
    screen.update()
  end
end

function enc(n,d)
  if n==1 then
    volume = util.clamp(volume + d/100,0.0,1)
    audio.level_dac(volume)
  elseif n==2 then
    if draw < 2 then
      params:delta("clock_tempo",d) 
    else  
      x = util.clamp(x + d,0,127)
      notesync = (x * (7.9/128)) + 0.1
      for i=1,3 do
      sc.post_filter_fc (i, 200 + (x * 12.5))
      end
   end
elseif n==3 then
    if draw < 2 then
     complexity=util.clamp(complexity+d,1,#primes-1)
     noterange = #pitch
    else
      y = util.clamp(y - d,0,63)
      noterange = 1 + math.floor(y * (#pitch/64))
      for i=1,3 do
      sc.post_filter_rq (i, 1.2 - y/64)
      end
    end
  end
  redraw()
end

function key(n,z)
  if n==2 and z==1 then
    choose = 0
    choose = math.random(3)
    pos_1 = choose == 1 and math.random() or pos_1
    pos_2 = choose == 2 and math.random() or pos_2
    pos_3 = choose == 3 and 5*math.random() or pos_3
    shuffle(pitch)
    shuffle(birdpitch)
  elseif n == 3 and z == 1 then
    draw = (draw + 1) % 3
    if draw == 2 then
      screen.clear()
      x = math.random(128)
      y = math.random(64)
    end
  end
end