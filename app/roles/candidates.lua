-- Implement a custom role in app/roles/custom-role.lua
local cartridge = require('cartridge')
local rpc = require('cartridge.rpc')
local log = require('log')

local role_name = 'candidates'
local function http_timestamp(req)
  local result
  -- number of confirmations
  local limit = tonumber(req:stash('limit'))

  local cs = rpc.get_candidates(role_name)

  if limit > #cs - 1 then
    result = "More confirmations than hosts"
  elseif limit < 1 then
    result = "At least a confirmation"
  else
    local confirm = 0 -- current number of confirmations
    local i = 0
    local ts, newts
    local askedTo = {}

    repeat -- until I have not enough confirmations
      local c = cs[math.random(1,#cs)]
      if not askedTo[c] then
        -- found an host I haven't asked the timestamp yet
        local opts = { prefer_local = false, leader_only = false,
                       uri = c }
        newts = rpc.call(role_name,
	               'current_ts', {}, opts)
        if i == 0 then
          ts = newts
        end
        if ts == newts then
          i = i+1
        end
        askedTo[c] = true
      end
    until ts ~= newts or i >= limit

    if i == limit then
      result = {ts, askedTo}
    else
      result = {"No agreement", askedTo}
    end
  end

  return req:render{ json = result }
end

local function init()
    local httpd = cartridge.service_get('httpd')
    if httpd ~= nil then
	-- List all the hosts in this role
        httpd:route({
            method = 'GET', path = '/candidates', public = true,
        },
        function(req)
            return req:render{ json = rpc.get_candidates(role_name) }
        end
        )

	-- ts = timestamp
        httpd:route({
            method = 'GET', path = '/ts/:limit', public = true,
        },
        http_timestamp
        )
    end
end

local function stop()
end


local function current_ts()
  local ts = os.time();
  log.info('REQUESTED TIMESTAMP ' .. tostring(ts));
  return ts
end

return {
    role_name = role_name,
    current_ts = current_ts,
    init = init,
    stop = stop,
}
