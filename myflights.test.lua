luaunit = require('luaunit')

function testeasy()
  luaunit.assertEquals(true,true)
end

os.exit( luaunit.LuaUnit.run() )