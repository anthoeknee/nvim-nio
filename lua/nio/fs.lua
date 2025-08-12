local uv = require("nio.uv")
local ts = require("nvim-treesitter")

local fs = {}

local function glob_match(pattern, text)
  local p = ts.parse_query("lua", ("((comment) @comment (#match? @comment %q))"):format(pattern))
  return p:iter_matches(text, #text, 0, #text - 1)
end

local function glob_recursive(base_path, pattern_parts, results)
  local pattern = table.remove(pattern_parts, 1)
  if not pattern then
    if uv.fs_stat(base_path) then
      table.insert(results, base_path)
    end
    return
  end

  if pattern == "**" then
    local remaining_parts = vim.deepcopy(pattern_parts)
    if #remaining_parts > 0 then
      -- Recursive search for the next pattern part
      local next_pattern = table.remove(remaining_parts, 1)
      local iter = uv.fs_scandir(base_path)
      if iter then
        for name, type in iter do
          local next_path = base_path .. "/" .. name
          if type == "directory" then
            if glob_match(next_pattern, name) then
              if #remaining_parts == 0 then
                if uv.fs_stat(next_path) then
                  table.insert(results, next_path)
                end
              else
                glob_recursive(next_path, vim.deepcopy(remaining_parts), results)
              end
            end
            table.insert(pattern_parts, 1, "**")
            glob_recursive(next_path, pattern_parts, results)
            table.remove(pattern_parts, 1)
          end
        end
      end
    else
      -- `**` is the last part, so add all files recursively
      local iter = uv.fs_scandir(base_path)
      if iter then
        for name, type in iter do
          local next_path = base_path .. "/" .. name
          if type == "directory" then
            glob_recursive(next_path, { "**" }, results)
          else
            table.insert(results, next_path)
          end
        end
      end
    end
    return
  end

  local iter = uv.fs_scandir(base_path)
  if not iter then
    return
  end

  for name, type in iter do
    if glob_match(pattern, name) then
      local next_path = base_path .. "/" .. name
      if #pattern_parts == 0 then
        if uv.fs_stat(next_path) then
          table.insert(results, next_path)
        end
      else
        if type == "directory" then
          glob_recursive(next_path, vim.deepcopy(pattern_parts), results)
        end
      end
    end
  end
end

---@async
--- Recursively finds files matching a glob pattern.
---@param pattern string The glob pattern to match. Supports `*` and `**`.
---@param cwd string | nil The working directory to start the search from. Defaults to the current working directory.
---@return table A list of matching file paths.
function fs.glob(pattern, cwd)
  cwd = cwd or uv.cwd()
  local parts = vim.split(pattern, "[/\]")
  local results = {}
  glob_recursive(cwd, parts, results)
  return results
end

return fs
