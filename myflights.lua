
local PARAMS_DEBUG = true
local BUFF_DEBUG = false

local perc_file, tonal_file, my_file -- file names to load

local buffer_index = {
  samples_loaded = 0,
  start_time = 0,
  end_time = 0,
  samples = {}
}

local voices = {
  one = {
    num = 1,
    name = "voice_one",
    params = {}
  },
  two = {
    num = 2,
    name = "voice_two",
    params = {}
  },
  three = {
    num = 3,
    name = "voice_three",
    params = {}
  }
}

-- Control Spec Definitions (min, max, warp, step, default, unit)
local cs_voice_level      = controlspec.new(0, 1, 'lin', 0, 0, 'lev')
local cs_voice_loop_time  = controlspec.new(0, 40, 'lin', 0, 0.01, 's')
local cs_voice_fade_time  = controlspec.new(0, 5, 'lin', 0, 0.1, 's')
local cs_voice_rate       = controlspec.new(-10, 10, 'lin', 0, 1, 's')
local cs_voice_rate_slew_time  = controlspec.new(0, 5, 'lin', 0, 0.2, 's')


function init()
  perc_file = _path.code .. "nc02-rs/lib/nc02-perc.wav"
  tonal_file = _path.code .. "nc02-rs/lib/nc02-tonal.wav"

  init_voice(voices.one, perc_file, 1)
  
  if (BUFF_DEBUG) then
    tab.print(buffer_index)
    tab.print(buffer_index.samples[voice.one.name])
  end

  init_voice(voices.two, tonal_file, 1)
  
  if (BUFF_DEBUG) then
    tab.print(buffer_index)
    tab.print(buffer_index.samples[voice_two_name])
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


function init_voice(voice, file_name, buff_num)

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
  print("  voice_num:\t"..voice.num)
  print("  buff_num:\t"..buff_num)
  print("  buff_duration:\t"..buff_duration.." sec")
  print("  pre_roll_time:\t"..pre_roll_time.." sec")
  print("  post_roll_time:\t"..post_roll_time.." sec")
  print("  buff_start_time:\t"..buff_start_time.." sec")

  -- load a mono sound file into a mono buffer
  -- https://monome.org/norns/modules/softcut.html#buffer_read_mono  
  softcut.buffer_read_mono(
    file_name,
    0, -- start point in source file
    buff_start_time, -- start point in buffer to write
    buff_duration,
    1, -- read from channel 1 of the source
    buff_num
  )

  -- data loaded, save data in the buffer index
  buffer_index.samples_loaded = buffer_index.samples_loaded + 1
  buffer_index.end_time = pre_roll_time + buff_duration + post_roll_time
  buffer_index.samples[voice.name] = {
    file_name       = file_name,
    file_channels   = ch,
    file_samples    = samples,
    file_samplerate = samplerate,
    file_duration   = duration,
    voice_num       = voice.num,
    buff_num        = buff_num,
    buff_duration   = buff_duration,
    buff_channel    = buff_channel, 
    buff_start_time = buff_start_time,
    pre_roll_time   = pre_roll_time,
    post_roll_time  = post_roll_time
  }

  voice.params = {
    level           = voice.name.."_level",
    loop            = voice.name.."_loop",
    loop_start      = voice.name.."_loop_start",
    loop_end        = voice.name.."_loop_end",
    fade_time       = voice.name.."_fade_time",
    rate            = voice.name.."_rate",
    rate_slew_time  = voice.name.."_rate_slew_time"
  }

  -- set voice enabled
  -- https://monome.org/norns/modules/softcut.html#enable
  softcut.enable(
    voice.num,
    1
  )


  -- attach the voice number to the buffer where the data was loaded
  -- https://monome.org/norns/modules/softcut.html#buffer

  -- assign to a softcut voice
  print("Voice: "..voice.num)
  print("Buffer: "..buff_num)

  softcut.buffer(
    voice.num,
    buff_num
  )

  -- set the playback level
  -- https://monome.org/norns/modules/softcut.html#level
  params:add_control(voice.params.level, voice.params.level, 
    cs_voice_level
  )
  params:set_action(voice.params.level, 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice.params.level.." to: "..x)
      end
      softcut.level(
        voice.num,
        x  
      ) 
    end
  )
  params:set(voice.params.level, 1.0)


  -- set loop enable
  -- https://monome.org/norns/modules/softcut.html#loop
  params:add_number(voice.params.loop, voice.params.loop, 
    0, 
    1, 
    0
  )
  params:set_action(voice.params.loop, 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice.params.loop.." to: "..x)
      end
      softcut.loop(
        voice.num,
        x  
      ) 
    end
  )
  params:set(voice.params.loop, 0) -- @todo: loop settings seem sticky


  -- set loop start to buffer_start_time
  -- https://monome.org/norns/modules/softcut.html#loop_start
  params:add_control(voice.params.loop_start, voice.params.loop_start, 
    cs_voice_loop_time
  )
  params:set_action(voice.params.loop_start, 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice.params.loop_start.." to: "..x)
      end
      softcut.loop_start(
        voice.num,
        x  
      ) 
    end
  )
  params:set(voice.params.loop_start, buff_start_time)


  -- set loop end to buff_start_time + buff_duration
  -- https://monome.org/norns/modules/softcut.html#loop_end
  params:add_control(voice.params.loop_end, voice.params.loop_end, 
    cs_voice_loop_time
  )
  params:set_action(voice.params.loop_end, 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice.params.loop_end.." to: "..x)
      end
      softcut.loop_end(
        voice.num,
        x  
      ) 
    end
  )
  params:set(voice.params.loop_end, (buff_start_time + buff_duration))


  -- set position
  -- https://monome.org/norns/modules/softcut.html#position
  softcut.position(
    voice.num,
    buff_start_time
  ) 


  -- https://monome.org/norns/modules/softcut.html#fade_time
  params:add_control(voice.params.fade_time, voice.params.fade_time,
    cs_voice_fade_time
  )
  params:set_action(voice.params.fade_time, 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice.params.fade_time.." to: "..x)
      end
      softcut.fade_time(
        voice.num,
        x  
      ) 
    end
  )
  params:set(voice.params.fade_time, 0.1)


  -- https://monome.org/norns/modules/softcut.html#rate
  params:add_control(voice.params.rate, voice.params.rate, 
    cs_voice_rate
  )
  params:set_action(voice.params.rate, 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice.params.rate.." to: "..x)
      end
      softcut.rate(
        voice.num,
        x  
      ) 
    end
  )
  params:set(voice.params.rate, 1)


  -- https://monome.org/norns/modules/softcut.html#level_slew_time
  params:add_control(voice.params.rate_slew_time, voice.params.rate_slew_time,
    cs_voice_rate_slew_time
  )
  params:set_action(voice.params.rate_slew_time, 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice.params.rate_slew_time.." to: "..x)
      end
      softcut.rate_slew_time(
        voice.num,
        x
      ) 
    end
  )
  params:set(voice.params.rate_slew_time, 0.3)

  -- set a conservative polling rate of .5 Seconds
  softcut.phase_quant(voice.num, 0.5)
end


function key(n,z)
  if (n==2 and z==1) then
    print("Playing Perc Voice: "..buffer_index.samples.voice_one.voice_num)

    softcut.position(
      buffer_index.samples["voice_one"].voice_num, 
      buffer_index.samples["voice_one"].buff_start_time
    )

    softcut.pan(
      buffer_index.samples["voice_one"].voice_num, 
      0.75
    )

    softcut.play(
      buffer_index.samples["voice_one"].voice_num,
      1
    )
  end

  if (n==3 and z==1) then
    print("Playing Tonal Voice: "..buffer_index.samples["voice_two"].voice_num)

    softcut.position(
      buffer_index.samples["voice_two"].voice_num, 
      buffer_index.samples["voice_two"].buff_start_time
    )

    softcut.pan(
      buffer_index.samples["voice_two"].voice_num, 
      0.25
    )

    softcut.play(
      buffer_index.samples["voice_two"].voice_num,
      1
    )
  end
end