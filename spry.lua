local message = ""
local pack_dir = os.getenv("HOME") .. "/.config/nvim/pack"
local packfile_path = os.getenv("HOME") .. "/.config/nvim/packfile"

local function read_file(file_path)
  local file = io.open(file_path, "r") -- Opens a file in read mode
  if not file then
    return nil
  end
  local content = file:read("*a") -- Read the entire content of the file
  file:close()
  return content
end

local function exists(name)
  local f = io.open(name, "r")
  if f then
    io.close(f)
    return true
  else
    return false
  end
end

local function getDirectories(directory)
  local i = 0
  local t = {}
  local pfile = io.popen("find " .. directory .. " -maxdepth 1 ! -path " .. directory .. " -type d")
  for filename in pfile:lines() do
    i = i + 1
    t[i] = filename
  end
  pfile:close()
  return t
end

local function extract_after_last_slash(input)
  local pattern = ".*/(.*)"
  local result = string.match(input, pattern)
  return result or input
end

local function iop(str)
  io.write(("\b \b"):rep(#message)) -- erase old line
  io.write(str) -- write new line
  io.flush()
  message = str
end

local function update_nvim_plugins()
  -- For each directory in the nvim pack directory
  for _, dir in ipairs(getDirectories(pack_dir)) do
    local start_dir = dir .. "/start"
    -- For each directory in the start directory
    for _, repo in ipairs(getDirectories(start_dir)) do
      local name = extract_after_last_slash(repo)
      iop("Updating: " .. name)
      -- Change into the repo directory and pull
      os.execute("cd " .. repo .. " && git pull --quiet")
    end
  end
  iop("")
  print("All plugins were updated.")
end

local function install_spry()
  if not exists(packfile_path) then
    iop("You need a packfile.")
    return nil
  end

  if exists("pack") then
    os.execute("rm -rf pack")
  end

  local data = read_file(packfile_path)
  os.execute("git config --global advice.detachedHead false")

  local category = nil
  local start_dir = nil
  for line in data:gmatch("[^\r\n]+") do
    if line:match("^%S") then
      -- This is a category line (no leading spaces)
      category = line
      start_dir = os.getenv("HOME") .. "/.config/nvim/pack/" .. category .. "/start"
      os.execute("mkdir -p " .. start_dir)
    end
    if line:match("^%s+") then
      -- This is a URL and ref line (with leading spaces)
      local url, ref = line:match("^%s*(.-),%s*(.-)%s*$")
      if start_dir and url and ref then
        iop("Installing: " .. url)
        os.execute(string.format("cd %s && git clone --quiet --depth=1 --branch %s https://github.com/%s.git > /dev/null", start_dir, ref, url))
      end
    end
  end

  os.execute("git config --global advice.detachedHead true")
  iop("")
  print("All plugins were installed.")
  print("Configure your plugins in " .. os.getenv("HOME") .. "/.config/nvim/plugin/packages")
end

vim.api.nvim_create_user_command("SpryUpdate", update_nvim_plugins, {})
vim.api.nvim_create_user_command("SpryInstall", install_spry, {})
