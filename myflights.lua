
local perc, tonal

local PERC_VOICE = 1
local TONAL_VOICE = 2

-- provide a pattern mask
-- local mask = [0, 0, 0, 1]

-- divide the sample length by the number of steps in the pattern mask
-- provide an offset value for each step, scalar value combines

function init()
  perc = _path.code .. "nc02-rs/lib/nc02-perc.wav"
  tonal = _path.code .. "nc02-rs/lib/nc02-perc.wav"

  cs_voice_num = controlspec.new(1,6,'lin',1,1,'num')
  cs_sample_phasor = controlspec.new(0, 1, 'lin', 0, 0, 'phase')
  cs_voice_enable = controlspec.new(0, 1, 'lin', 1, 0, 'enable')
  cs_buffer_num = controlspec.new(1, 2, 'lin', 1, 1, 'buffnum')

  params:add_control("perc_voice_num","perc_voice_num",cs_voice_num)

  -- load a mono sound file into a mono buffer
  -- https://monome.org/norns/modules/softcut.html#buffer_read_mono
  params:add_control("perc_voice_load_start", "perc_voice_load_start", 
    cs_sample_count
  )
  params:add_control("perc_voice_buffer", "perc_voice_buffer", 
    cs_buffer_num
  )
  params:set("perc_voice_buffer", 1)
  softcut.buffer_read_mono(perc,
    params:get("perc_voice_load_start"), -- load the file from the beginning
    params:get("perc_voice_load_start"), -- load into the buffer at the beginning
    -1, -- load as much as can be read
    1, -- read from channel 1 of the source
    params:get("perc_voice_buffer") -- write to channel 1 of the buffer
  )

  -- set voice one to enabled
  -- https://monome.org/norns/modules/softcut.html#enable
  params:add_control("perc_voice_enable", "perc_voice_enable", 
    cs_voice_enable
  )
  params:set("perc_voice_enable", 1)
  softcut.enable(
    params:get("perc_voice_num"),
    params:get("perc_voice_enable")
  )

  -- attach the voice number to the buffer where the data was loaded
  -- https://monome.org/norns/modules/softcut.html#buffer
  softcut.buffer(
    params:get("perc_voice_num"),
    params:get("perc_voice_buffer")
  )


  softcut.level(1,1.0)
  softcut.loop(1,0)
  softcut.loop_start(1,0)
  softcut.loop_end(1,10)
  softcut.position(1,1)
  softcut.fade_time(1,0.01)
  softcut.rate(1,2.0)
  --softcut.play(1,1)
  softcut.level_slew_time(1,0.2)
end

function key(n,z)
  softcut.position(1,1)
  softcut.play(1,1)
end