local Object = require "classic"
local Pager = require "kong_client.helpers.pager"
local merge = require "kong_client.helpers.merge".shallow_merge

local ResourceObject = Object:extend()

ResourceObject.PATH = nil

function ResourceObject:new(http_client)
    self.http_client = http_client
end

function ResourceObject:create(resource_data)
    return self:request({
        method = "POST",
        path = self.PATH,
        body = resource_data
    })
end

function ResourceObject:find_by_id(resource_id)
    return self:request({
        method = "GET",
        path = self.PATH .. "/" .. resource_id
    })
end

function ResourceObject:find_by_name_or_id(resource_name_or_id)
    return self:request({
        method = "GET",
        path = self.PATH .. "/" .. resource_name_or_id
    })
end

function ResourceObject:each(callback, limit)
    limit = limit or 100

    local pager = Pager(function(offset)
        return self:request({
            method = "GET",
            path = self.PATH,
            query = {
                offset = offset,
                limit = limit
            }
        })
    end)

    pager:each(callback)
end

function ResourceObject:all(limit)
    local resources = {}

    self:each(function(resource)
        table.insert(resources, resource)
    end, limit)

    return resources
end

function ResourceObject:update(resource_data)
    return self:request({
        method = "PATCH",
        path = self.PATH .. "/" .. resource_data.id,
        body = resource_data
    })
end

function ResourceObject:update_or_create(resource_data)
    return self:request({
        method = "PUT",
        path = self.PATH .. "/" .. resource_data.id,
        body = resource_data
    })
end

function ResourceObject:delete(resource_id)
    return self:request({
        method = "DELETE",
        path = self.PATH .. "/" .. resource_id
    })
end

local function make_relative_path(path)
    return "/" .. path
end

local function get_request_headers(options)
    local headers = {}

    if type(options.body) == "table" then
        headers["Content-Type"] = "application/json"
    end

    merge(headers, options.headers)

    return headers
end

function ResourceObject:request(options)
    return self.http_client:send({
        method = options.method,
        path = make_relative_path(options.path),
        query = options.query,
        body = options.body,
        headers = get_request_headers(options)
    })
end

return ResourceObject
