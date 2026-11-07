function love.conf(t)
  t.identity = "detoimeme"
  t.window.title = "Toi-même tu sais"
  t.window.width = 720
  t.window.height = 480
  t.window.resizable = true
  -- Full-resolution drawing on high-density screens (phones, Retina);
  -- sizes and coordinates stay in window units. Not on the console.
  t.window.highdpi = love._os == "Web" or love._os == "OS X"
end
