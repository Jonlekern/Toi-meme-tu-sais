-- Minimal test runner: luajit tests/run.lua (from the project root)
package.path = "src/?.lua;src/?/init.lua;tests/?.lua;" .. package.path

local T = {}
function T.eq(a, b, msg)
  if a ~= b then
    error((msg and (msg .. ": ") or "") .. "expected " .. tostring(b) .. ", got " .. tostring(a), 2)
  end
end
function T.ok(v, msg)
  if not v then error(msg or "expected a truthy value", 2) end
end
function T.fails(fn)
  if pcall(fn) then error("expected the function to fail", 2) end
end
_G.T = T

-- List tests/test_*.lua (sorted)
local files = {}
local p = io.popen('ls tests/test_*.lua 2>/dev/null')
for line in p:lines() do files[#files + 1] = line end
p:close()
table.sort(files)

local pass, fail = 0, 0
for _, file in ipairs(files) do
  local chunk, err = loadfile(file)
  local suite = chunk and select(2, pcall(chunk))
  if type(suite) ~= "table" then
    fail = fail + 1
    print("FAIL " .. file .. " : " .. tostring(chunk and suite or err))
  else
    local names = {}
    for name in pairs(suite) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do
      local ok, e = pcall(suite[name])
      if ok then
        pass = pass + 1
        print("ok " .. name)
      else
        fail = fail + 1
        print("FAIL " .. name .. " : " .. tostring(e))
      end
    end
  end
end

print(pass .. " ok, " .. fail .. " FAIL")
os.exit(fail > 0 and 1 or 0)
