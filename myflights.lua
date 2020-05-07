
local PARAMS_DEBUG = true

local perc, tonal

-- Control Spec Definitions (min, max, warp, step, default, unit)
local cs_voice_num        = controlspec.new(1, 6, 'lin', 1, 1, 'num')
local cs_sample_phasor    = controlspec.new(0, 1, 'lin', 0, 0, 'phase')
local cs_voice_enable     = controlspec.new(0, 1, 'lin', 1, 0, 'enable')
local cs_buffer_num       = controlspec.new(1, 2, 'lin', 1, 1, 'buffnum')
local cs_voice_level      = controlspec.new(0, 1, 'lin', 0, 0, 'level')
local cs_voice_loop       = controlspec.new(0, 1, 'lin', 1, 0, 'loop')
local cs_voice_loop_pos   = controlspec.new(0, 10, 'lin', 0, 0, 's')
local cs_voice_fade_time  = controlspec.new(0, 5, 'lin', 0, 0.1, 's')
local cs_voice_rate       = controlspec.new(0, 10, 'lin', 0, 1, 's')
local cs_voice_level_slew_time  = controlspec.new(0, 2, 'lin', 0, 0.2, 's')

-- provide a pattern mask
-- local mask = [0, 0, 0, 1]

-- divide the sample length by the number of steps in the pattern mask
-- provide an offset value for each step, scalar value combines

function init()
  perc = _path.code .. "nc02-rs/lib/nc02-perc.wav"
  tonal = _path.code .. "nc02-rs/lib/nc02-tonal.wav"

  init_voice("perc_voice", perc)
end

-- todo: file to load and offsets of existing loaded data
function init_voice(voice_name, file_name)

  local ch, samples, samplerate = audio.file_info(file_name)
  local duration = samples/samplerate
  print("loading file: "..file_name)
  print("  channels:\t"..ch)
  print("  samples:\t"..samples)
  print("  sample rate:\t"..samplerate.."hz")
  print("  duration:\t"..duration.." sec")

  params:add_control(voice_name.."_num",voice_name.."_num",cs_voice_num)

  -- load a mono sound file into a mono buffer
  -- https://monome.org/norns/modules/softcut.html#buffer_read_mono
  params:add_control(voice_name.."_load_start", voice_name.."_load_start", 
    cs_sample_count
  )
  params:add_control(voice_name.."_buffer", voice_name.."_buffer", 
    cs_buffer_num
  )
  params:set(voice_name.."_buffer", 1)
  softcut.buffer_read_mono(file_name,
    params:get(voice_name.."_load_start"), -- read the file from the beginning
    params:get(voice_name.."_load_start"), -- write into the buffer at the beginning
    samples, -- load all samples
    1, -- read from channel 1 of the source
    params:get(voice_name.."_buffer") -- write to channel 1 of the buffer
  )

  -- set voice one to enabled
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
        params:get(voice_name.."_num"),
        x  
      ) 
    end
  )
  params:set(voice_name.."_enable", 1)


  -- attach the voice number to the buffer where the data was loaded
  -- https://monome.org/norns/modules/softcut.html#buffer
  softcut.buffer(
    params:get(voice_name.."_num"),
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
        params:get(voice_name.."_num"),
        x  
      ) 
    end
  )
  params:set(voice_name.."_level", 1.0)


  -- disable loop
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
        params:get(voice_name.."_num"),
        x  
      ) 
    end
  )
  params:set(voice_name.."_loop", 0)


  -- set loop start to 0s
  -- https://monome.org/norns/modules/softcut.html#loop_start
  params:add_control(voice_name.."_loop_start", voice_name.."_loop_start", 
    cs_voice_loop_pos
  )
  params:set_action(voice_name.."_loop_start", 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name.."_loop_start to: "..x)
      end
      softcut.loop_start(
        params:get(voice_name.."_num"),
        x  
      ) 
    end
  )
  params:set(voice_name.."_loop_start", 0)


  -- set loop end to 10s @todo use actual sample data and padding values
  -- https://monome.org/norns/modules/softcut.html#loop_end
  params:add_control(voice_name.."_loop_end", voice_name.."_loop_end", 
    cs_voice_loop_pos
  )
  params:set_action(voice_name.."_loop_end", 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name.."_loop_end to: "..x)
      end
      softcut.loop_end(
        params:get(voice_name.."_num"),
        x  
      ) 
    end
  )
  params:set(voice_name.."_loop_end", duration)


  -- https://monome.org/norns/modules/softcut.html#position
  params:add_control(voice_name.."_position", voice_name.."_position",
    cs_voice_loop_pos
  )
  params:set_action(voice_name.."_position", 
    function(x)
      if (PARAMS_DEBUG) then
        print("Setting "..voice_name.."_position to: "..x)
      end
      softcut.position(
        params:get(voice_name.."_num"),
        x  
      ) 
    end
  )
  params:set(voice_name.."_position", 0)


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
        params:get(voice_name.."_num"),
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
        params:get(voice_name.."_num"),
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
        params:get(voice_name.."_num"),
        x  
      ) 
    end
  )
  params:set(voice_name.."_level_slew_time", 0.3)

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