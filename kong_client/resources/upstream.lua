local ResourceObject = require "kong_client.resources.resource_object"

local Upstream = ResourceObject:extend()

Upstream.PATH = "upstreams"

function Upstream:show_health(upstream_id_or_name)
    return self:request({
        method = "GET",
        path = self.PATH .. "/" .. upstream_id_or_name .. "/health"
    })
end

function Upstream:add_target(upstream_id_or_name, target_data)
    return self:request({
        method = "POST",
        path = self.PATH .. "/" .. upstream_id_or_name .. "/targets",
        body = target_data
    })
end

function Upstream:list_targets(upstream_id_or_name)
    return self:request({
        method = "GET",
        path = self.PATH .. "/" .. upstream_id_or_name .. "/targets"
    })
end

return Upstream