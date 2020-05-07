
local perc, tonal

local PERC_VOICE = 1
local TONAL_VOICE = 2

-- provide a pattern mask
-- local mask = [0, 0, 0, 1]

-- divide the sample length by the number of steps in the pattern mask
-- provide an offset value for each step, scalar value combines

function init()
  perc = _path.code .. "nc02-rs/lib/nc02-perc.wav"
  tonal = _path.code .. "nc02-rs/lib/nc02-tonal.wav"

  local perc_ch, perc_samples, perc_samplerate = audio.file_info(perc)
  local perc_duration = perc_samples/perc_samplerate
  print("loading file: "..perc)
  print("  channels:\t"..perc_ch)
  print("  samples:\t"..perc_samples)
  print("  sample rate:\t"..perc_samplerate.."hz")
  print("  duration:\t"..perc_duration.." sec")

  cs_voice_num = controlspec.new(1,6,'lin',1,1,'num')
  cs_sample_phasor = controlspec.new(0, 1, 'lin', 0, 0, 'phase')
  cs_voice_enable = controlspec.new(0, 1, 'lin', 1, 0, 'enable')
  cs_buffer_num = controlspec.new(1, 2, 'lin', 1, 1, 'buffnum')
  cs_voice_level = controlspec.new(0, 1, 'lin', 0, 0, 'level')
  cs_voice_loop = controlspec.new(0, 1, 'lin', 1, 0, 'loop')
  cs_voice_loop_pos = controlspec.new(0, 10, 'lin', 0, 0, 's')
  cs_voice_fade_time = controlspec.new(0, 5, 'lin', 0, .01, 's')
  cs_voice_playback_rate = controlspec.new(0, 10, 'lin', 0, 1, 's')
  cs_voice_slew_time = controlspec.new(0, 2, 'lin', 0, 0.1, 's')

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
    params:get("perc_voice_load_start"), -- read the file from the beginning
    params:get("perc_voice_load_start"), -- write into the buffer at the beginning
    perc_samples, -- load all samples
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

  -- set the playback level
  -- https://monome.org/norns/modules/softcut.html#level
  params:add_control("perc_voice_level", "perc_voice_level", 
    cs_voice_level
  )
  params:set("perc_voice_level", 1.0)
  softcut.level(
    params:get("perc_voice_num"),
    params:get("perc_voice_level")
  )

  -- disable loop
  -- https://monome.org/norns/modules/softcut.html#loop
  params:add_control("perc_voice_loop", "perc_voice_loop", 
    cs_voice_loop
  )
  params:set("perc_voice_loop", 0)
  softcut.loop(
    params:get("perc_voice_num"),
    params:get("perc_voice_loop")
  )

  -- set loop start to 0s
  -- https://monome.org/norns/modules/softcut.html#loop_start
  params:add_control("perc_voice_loop_start", "perc_voice_loop_start", 
    cs_voice_loop_pos
  )
  params:set("perc_voice_loop_start", 0)
  softcut.loop_start(
    params:get("perc_voice_num"),
    params:get("perc_voice_loop_start")
  )

  -- set loop end to 10s @todo use actual sample data and padding values
  -- https://monome.org/norns/modules/softcut.html#loop_end
  params:add_control("perc_voice_loop_end", "perc_voice_loop_end", 
    cs_voice_loop_pos
  )
  params:set("perc_voice_loop_end", 10)
  softcut.loop_end(
    params:get("perc_voice_num"),
    params:get("perc_voice_loop_end")
  )

  -- https://monome.org/norns/modules/softcut.html#position
  params:add_control("perc_voice_position", "perc_voice_position",
    cs_voice_loop_pos
  )
  params:set("perc_voice_position", 0)
  softcut.position(
    params:get("perc_voice_num"),
    params:get("perc_voice_position")
  )

  -- https://monome.org/norns/modules/softcut.html#fade_time
  params:add_control("perc_voice_fade_time", "perc_voice_fade_time",
    cs_voice_fade_time
  )
  softcut.fade_time(
    params:get("perc_voice_num"),
    params:get("perc_voice_fade_time")
  )

  -- https://monome.org/norns/modules/softcut.html#rate
  params:add_control("perc_voice_playback_rate", "perc_voice_playback_rate", 
    cs_voice_playback_rate
  )
  softcut.rate(
    params:get("perc_voice_num"),
    params:get("perc_voice_playback_rate")
  )

  -- https://monome.org/norns/modules/softcut.html#level_slew_time
  params:add_control("perc_voice_slew_time", "perc_voice_slew_time",
    cs_voice_slew_time
  )
  softcut.level_slew_time(
    params:get("perc_voice_num"),
    params:get("perc_voice_slew_time")
  )
end

function key(n,z)
  params:set("perc_voice_position", 0)
  softcut.position(
    params:get("perc_voice_num"),
    params:get("perc_voice_position")
  )

  softcut.play(
    params:get("perc_voice_num"),
    1
  )
end