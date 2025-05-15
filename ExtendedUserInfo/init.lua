local json = require("json")

local function get_target_username(ctx)
  if #ctx.words < 2 then
    if ctx.channel and ctx.channel:get_name() then
      return ctx.channel:get_name()
    else
      ctx.channel:add_system_message("Error: Unable to determine target username or channel.")
      return nil
    end
  else
    return ctx.words[2]
  end
end

local function fetch_api_data(ctx, url, success_callback)
  local request = c2.HTTPRequest.create(c2.HTTPMethod.Get, url)

  request:on_success(function(response)
    local data_str = response:data()
    local status_code = response:status()

    if status_code == 200 then
      local success, parsed_data = pcall(json.decode, data_str)
      if success and parsed_data then
        success_callback(parsed_data)
      else
        ctx.channel:add_system_message("Error: Failed to parse API response.")
      end
    else
      ctx.channel:add_system_message("Error: API returned HTTP " .. tostring(status_code))
    end
  end)

  request:on_error(function(response)
    local error_msg = response and response:error() or "Unknown error."
    ctx.channel:add_system_message("Error: Failed to connect to API. " .. error_msg)
  end)

  request:execute()
end

local function cmd_pastnames(ctx)
  local username = get_target_username(ctx)
  if not username then return end

  local url = "https://logs.zonian.dev/namehistory/login:" .. username

  fetch_api_data(ctx, url, function(history_data)
    local logins = {}
    for _, entry in ipairs(history_data) do
      if entry.user_login then
        table.insert(logins, entry.user_login)
      end
    end
    if #logins > 0 then
      ctx.channel:add_system_message("Past usernames: " .. table.concat(logins, ", "))
    else
      ctx.channel:add_system_message("No past usernames found for " .. username .. ".")
    end
  end)
end

local function cmd_follows(ctx)
  local username = get_target_username(ctx)
  if not username then return end

  local url = "https://tools.2807.eu/api/getfollows/" .. username

  fetch_api_data(ctx, url, function(follow_data)
    local follows = {}
    for _, follow in ipairs(follow_data) do
      if follow.displayName then
        table.insert(follows, follow.displayName)
      end
    end
    if #follows > 0 then
      ctx.channel:add_system_message("Follows: " .. table.concat(follows, ", "))
    else
      ctx.channel:add_system_message(username .. " does not follow anyone (or the data is unavailable).")
    end
  end)
end

local function cmd_mods(ctx)
  local username = get_target_username(ctx)
  if not username then return end

  local url = "https://tools.2807.eu/api/getmods/" .. username

  fetch_api_data(ctx, url, function(mod_data)
    local mods = {}
    for _, mod in ipairs(mod_data) do
      if mod.displayName then
        table.insert(mods, mod.displayName)
      end
    end
    if #mods > 0 then
      ctx.channel:add_system_message("Moderators: " .. table.concat(mods, ", "))
    else
      ctx.channel:add_system_message("No moderators found for " .. username .. " (or the data is unavailable).")
    end
  end)
end

local function cmd_vips(ctx)
  local username = get_target_username(ctx)
  if not username then return end

  local url = "https://tools.2807.eu/api/getvips/" .. username

  fetch_api_data(ctx, url, function(vip_data)
    local vips = {}
    for _, vip in ipairs(vip_data) do
      if vip.displayName then
        table.insert(vips, vip.displayName)
      end
    end
    if #vips > 0 then
      ctx.channel:add_system_message("VIPs: " .. table.concat(vips, ", "))
    else
      ctx.channel:add_system_message("No VIPs found for " .. username .. " (or the data is unavailable).")
    end
  end)
end

-- you need to use the get prefix because you cant override the build it /mods /vips etc
c2.register_command("/getnames", cmd_pastnames)
c2.register_command("/getfollowing", cmd_follows)
c2.register_command("/getmods", cmd_mods)
c2.register_command("/getvips", cmd_vips)
