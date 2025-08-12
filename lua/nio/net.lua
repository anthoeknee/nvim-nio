local uv = require("nio.uv")
local tasks = require("nio.tasks")
local streams = require("nio.streams")

local net = {}

---@class nio.net.Stream: nio.streams.StreamReaderWriter
local Stream = {}
Stream.__index = Stream
setmetatable(Stream, { __index = streams.StreamReaderWriter })

---@async
--- Connects to a TCP server.
---@param host string The host to connect to.
---@param port number The port to connect to.
---@return nio.net.Stream #A stream object for the connection.
---@raise string An error message if the connection fails.
function net.connect(host, port)
  local handle = vim.loop.new_tcp()
  if not handle then
    error("nio.net.connect: failed to create TCP handle", 0)
  end

  local connect_async = tasks.wrap(function(h, p, cb)
    handle:connect(h, p, cb)
  end, 2)

  local err = connect_async(host, port)

  if err then
    handle:close()
    error("nio.net.connect: failed to connect to " .. host .. ":" .. port .. ": " .. err, 0)
  end

  local stream = setmetatable({}, Stream)
  local reader = streams._socket_reader(handle)
  local writer = streams._writer(handle)

  stream.read = reader.read
  stream.write = writer.write
  stream.close = function()
    return uv.close(handle)
  end
  stream.handle = handle

  return stream
end

return net
