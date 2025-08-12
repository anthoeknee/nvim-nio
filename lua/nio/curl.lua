local process = require("nio.process")

local nio = {}

---@class nio.curl
nio.curl = {}

---@class nio.curl.RequestOpts
---@field method string The HTTP method to use
---@field url string The URL to request
---@field headers table<string, string> The headers to send
---@field body string The body to send

---@async
--- Makes an HTTP request using the curl command-line tool.
---@param opts nio.curl.RequestOpts The request options.
---@return string #The response body from stdout.
---@raise string An error message if the curl command fails.
function nio.curl.request(opts)
  if not opts or type(opts) ~= "table" then
    error("nio.curl.request(opts): opts is a required table", 2)
  end

  if not opts.url or type(opts.url) ~= "string" then
    error("nio.curl.request(opts): opts.url is a required string", 2)
  end

  local args = { "curl", "-sS" }

  if opts.method then
    table.insert(args, "-X")
    table.insert(args, opts.method)
  end

  if opts.headers then
    for key, value in pairs(opts.headers) do
      table.insert(args, "-H")
      table.insert(args, string.format("%s: %s", key, value))
    end
  end

  if opts.body then
    table.insert(args, "--data")
    table.insert(args, opts.body)
  end

  table.insert(args, opts.url)

  local p = process.run({
    cmd = args,
  })

  local code = p:wait()

  if code ~= 0 then
    local stderr = p.stderr:read_to_end()
    error("nio.curl.request failed with exit code " .. tostring(code) .. ":\n" .. stderr)
  end

  return p.stdout:read_to_end()
end

return nio
