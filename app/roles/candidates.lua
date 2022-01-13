-- Implement a custom role in app/roles/custom-role.lua
local cartridge = require('cartridge')
local rpc = require('cartridge.rpc')
local log = require('log')

local role_name = 'candidates'

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
        httpd:route({
            method = 'GET', path = '/iam', public = true,
        },
        function(req)
	    local cs = rpc.get_candidates(role_name)
	    local opts = { prefer_local = false, leader_only = false,
	                   uri = 'localhost:3302' }
            return req:render{ 
		    json = rpc.call(role_name,
		                    'current_ts', {}, opts) 
	    }
        end
        )
    end
end

local function stop()
end


local function current_ts()
    log.info('REQUESTED TIMESTAMP');
    return os.time()
end

return {
    role_name = role_name,
    current_ts = current_ts,
    init = init,
    stop = stop,
}
