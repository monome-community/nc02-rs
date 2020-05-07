
local PARAMS_DEBUG = true
local BUFF_DEBUG = false

local perc, tonal -- file names to load

local buffer_index = {
  samples_loaded = 0,
  start_time = 0,
  end_time = 0,
  samples = {}
}

-- Control Spec Definitions (min, max, warp, step, default, unit)
local cs_voice_num        = controlspec.new(1, 6, 'lin', 1, 1, 'num')
local cs_sample_phasor    = controlspec.new(0, 1, 'lin', 0, 0, 'phase')
local cs_voice_enable     = controlspec.new(0, 1, 'lin', 1, 0, 'enable')
local cs_buffer_num       = controlspec.new(1, 2, 'lin', 1, 1, 'buffnum')
local cs_voice_level      = controlspec.new(0, 1, 'lin', 0, 0, 'level')
local cs_voice_loop       = controlspec.new(0, 1, 'lin', 1, 0, 'loop')
local cs_voice_loop_pos   = controlspec.new(0, 40, 'lin', 0, 0.01, 's')
local cs_voice_loop_time  = controlspec.new(0, 40, 'lin', 0, 0.01, 's')
local cs_voice_fade_time  = controlspec.new(0, 5, 'lin', 0, 0.1, 's')
local cs_voice_rate       = controlspec.new(0, 10, 'lin', 0, 1, 's')
local cs_voice_level_slew_time  = controlspec.new(0, 2, 'lin', 0, 0.2, 's')


function init()
  perc = _path.code .. "nc02-rs/lib/nc02-perc.wav"
  tonal = _path.code .. "nc02-rs/lib/nc02-tonal.wav"

  init_voice("perc_voice", perc, 1, 1) -- NOTE: loading voice 2 first
  
  if (BUFF_DEBUG) then
    tab.print(buffer_index)
    tab.print(buffer_index.samples["perc_voice"])
  end

  init_voice("tonal_voice", tonal, 1, 2)
  
  if (BUFF_DEBUG) then
    tab.print(buffer_index)
    tab.print(buffer_index.samples["tonal_voice"])
  end

  -- setup a poll
  --softcut.phase_quant(voice,time)
  --softcut.event_phase(update_positions)
  --softcut.poll_start_phase()

  params:bang()

end

function update_positions(voice,position)
  print(voice,position)
end


function init_voice(voice_name, file_name, buff_num, voice_num)

  local ch, samples, samplerate = audio.file_info(file_name)
  local buff_duration = samples / samplerate
  local pre_roll_time = 1 -- amount of time to pad the beginning of the sample in Seconds
  local post_roll_time = pre_roll_time 
  local buff_start_time = buffer_index.end_time + pre_roll_time -- time in the buffer to start loading sample data into
  local duration = samples/samplerate

  print("loading file: "..file_name)
  print("  channels:\t"..ch)
  print("  samples:\t"..samples)
  print("  sample rate:\t"..samplerate.."hz")
  print("  duration:\t"..duration.." sec")
  print("  voice_num:\t"..voice_num)
  print("  buff_num:\t"..buff_num)
  print("  buff_duration:\t"..buff_duration.." sec")
  print("  pre_roll_time:\t"..pre_roll_time.." sec")
  print("  post_roll_time:\t"..post_roll_time.." sec")
  print("  buff_start_time:\t"..buff_start_time.." sec")

  -- load a mono sound file into a mono buffer
  -- https://monome.org/norns/modules/softcut.html#buffer_read_mono
  params:add_control(voice_name.."_load_start", voice_name.."_load_start", 
    cs_sample_count
  )
  params:set(voice_name.."_load_start", buff_start_time)

  params:add_control(voice_name.."_buffer", voice_name.."_buffer", 
    cs_buffer_num
  )
  params:set(voice_name.."_buffer", buff_num)
  
  softcut.buffer_read_mono(
    file_name,
    0, -- start point in source file
    buff_start_time, -- start point in buffer to write
    buff_duration,
    1, -- read from channel 1 of the source
    params:get(voice_name.."_buffer")
  )

  -- data loaded, save data in the buffer index
  buffer_index.samples_loaded = buffer_index.samples_loaded + 1
  buffer_index.end_time = pre_roll_time + buff_duration + post_roll_time
  buffer_index.samples[voice_name] = {
    file_name       = file_name,
    file_channels   = ch,
    file_samples    = samples,
    file_samplerate = samplerate,
    file_duration   = duration,
    voice_num       = voice_num,
    buff_num        = buff_num,
    buff_duration   = buff_duration,
    buff_channel    = buff_channel, 
    buff_start_time = buff_start_time,
    pre_roll_time   = pre_roll_time,
    post_roll_time  = post_roll_time
  }

  -- set voice enabled
  -- https://monome.org/norns/modules/softcut.html#enable
  params:add_control(voice_name.."_enable", voice_name.."_enable", 
    cs_voice_enable
  )
  params:set_action(voice_name.."_enable", 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name.."_enable to: "..x)
      end
      softcut.enable(
        voice_num,
        x  
      ) 
    end
  )
  -- todo: does this line up with ^
  params:set(voice_name.."_enable", 1)


  -- attach the voice number to the buffer where the data was loaded
  -- https://monome.org/norns/modules/softcut.html#buffer

  -- assign to a softcut voice
  print("Voice: "..voice_num)
  print("Buffer: "..params:get(voice_name.."_buffer"))

  softcut.buffer(
    voice_num,
    params:get(voice_name.."_buffer")
  )

  -- set the playback level
  -- https://monome.org/norns/modules/softcut.html#level
  params:add_control(voice_name.."_level", voice_name.."_level", 
    cs_voice_level
  )
  params:set_action(voice_name.."_level", 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name.."_level to: "..x)
      end
      softcut.level(
        voice_num,
        x  
      ) 
    end
  )
  params:set(voice_name.."_level", 1.0)


  -- set loop enable
  -- https://monome.org/norns/modules/softcut.html#loop
  params:add_control(voice_name.."_loop", voice_name.."_loop", 
    cs_voice_loop
  )
  params:set_action(voice_name.."_loop", 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name.."_loop to: "..x)
      end
      softcut.loop(
        voice_num,
        x  
      ) 
    end
  )
  params:set(voice_name.."_loop", 1) -- @todo: loop settings seem sticky


  -- set loop start to buffer_start_time
  -- https://monome.org/norns/modules/softcut.html#loop_start
  params:add_control(voice_name.."_loop_start", voice_name.."_loop_start", 
    cs_voice_loop_time
  )
  params:set_action(voice_name.."_loop_start", 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name.."_loop_start to: "..x)
      end
      softcut.loop_start(
        voice_num,
        x  
      ) 
    end
  )
  print("buff_start_time: "..buff_start_time)
  params:set(voice_name.."_loop_start", buff_start_time)


  -- set loop end to buff_start_time + buff_duration
  -- https://monome.org/norns/modules/softcut.html#loop_end
  local param_name = "_loop_end"
  params:add_control(voice_name..param_name, voice_name..param_name, 
    cs_voice_loop_time
  )
  params:set_action(voice_name..param_name, 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name..param_name.." to: "..x)
      end
      softcut.loop_end(
        voice_num,
        x  
      ) 
    end
  )
  print("buff_start_time + buff_duration: "..(buff_start_time + buff_duration))
  params:set(voice_name..param_name, (buff_start_time + buff_duration))


  -- set position
  -- https://monome.org/norns/modules/softcut.html#position
  softcut.position(
    voice_num,
    buff_start_time
  ) 


  -- https://monome.org/norns/modules/softcut.html#fade_time
  params:add_control(voice_name.."_fade_time", voice_name.."_fade_time",
    cs_voice_fade_time
  )
  params:set_action(voice_name.."_fade_time", 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name.."_fade_time to: "..x)
      end
      softcut.fade_time(
        voice_num,
        x  
      ) 
    end
  )
  params:set(voice_name.."_fade_time", 0.1)


  -- https://monome.org/norns/modules/softcut.html#rate
  params:add_control(voice_name.."_rate", voice_name.."_rate", 
    cs_voice_rate
  )
  params:set_action(voice_name.."_rate", 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name.."_rate to: "..x)
      end
      softcut.rate(
        voice_num,
        x  
      ) 
    end
  )
  params:set(voice_name.."_rate", 1)


  -- https://monome.org/norns/modules/softcut.html#level_slew_time
  params:add_control(voice_name.."_level_slew_time", voice_name.."_level_slew_time",
    cs_voice_level_slew_time
  )
  params:set_action(voice_name.."_level_slew_time", 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name.."_level_slew_time to: "..x)
      end
      softcut.level_slew_time(
        voice_num,
        x  
      ) 
    end
  )
  params:set(voice_name.."_level_slew_time", 0.3)

  -- set a conservative polling rate of .5 Seconds
  softcut.phase_quant(voice_num, 0.5)
end


function key(n,z)
  if (n==2 and z==1) then
    print("Playing Perc Voice: "..params:get("perc_voice_num"))

    softcut.position(
      buffer_index.samples["perc_voice"].voice_num, 
      buffer_index.samples["perc_voice"].buff_start_time
    )

    softcut.pan(
      buffer_index.samples["perc_voice"].voice_num, 
      0.75
    )

    softcut.play(
      buffer_index.samples["perc_voice"].voice_num,
      1
    )
  end

  if (n==3 and z==1) then
    print("Playing Tonal Voice: "..params:get("tonal_voice_num"))

    softcut.position(
      buffer_index.samples["tonal_voice"].voice_num, 
      buffer_index.samples["tonal_voice"].buff_start_time
    )

    softcut.pan(
      buffer_index.samples["tonal_voice"].voice_num, 
      0.25
    )

    softcut.play(
      buffer_index.samples["tonal_voice"].voice_num,
      1
    )
  end
end