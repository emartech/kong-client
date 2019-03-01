local cjson = require "cjson"
local kong_helpers = require "spec.helpers"
local test_helpers = require "spec.test_helpers"
local ResourceObject = require "kong_client.resources.resource_object"

describe("KongClient", function()

    local kong_client, send_admin_request

    setup(function()
        kong_helpers.start_kong({ plugins = 'bundled' })

        kong_client = test_helpers.create_kong_client()
        send_admin_request = test_helpers.create_request_sender(kong_helpers.admin_client())
    end)

    teardown(function()
        kong_helpers.stop_kong(nil)
    end)

    describe("resources", function()

        before_each(function()
            kong_helpers.db:truncate()
        end)

        describe("ResourceObject", function()
            it("should create a service", function()

                local resource = ResourceObject(kong_helpers.admin_client())

                local service_name = "test_service"

                local response = assert(resource:request({
                    method = "POST",
                    path = "services",
                    body = {
                        name = service_name,
                        url = "http://mockbin:8080/request"
                    }
                }))

                local raw_body = assert(response:read_body())
                local _, service = pcall(cjson.decode, raw_body)

                local service_response = send_admin_request({
                    method = "GET",
                    path = "/services/" .. service_name
                })

                assert.are.equal(service_response.body.id, service.id)
            end)
        end)

        describe("Service", function()
            it("should create a service", function()

                local service_name = "test_service"

                local service = kong_client.services:create({
                    name = service_name,
                    url = "http://mockbin:8080/request"
                })

                local service_response = send_admin_request({
                    method = "GET",
                    path = "/services/" .. service_name
                })

                assert.are.equal(service_response.body.id, service.id)
            end)

            it("should update a service", function()

                local service_name = "test_service"

                local service = kong_client.services:create({
                    name = service_name,
                    url = "http://mockbin:8080/request"
                })

                service.url = "http://mockbin:8080/headers"

                local updated_service = kong_client.services:update(service)

                local service_response = send_admin_request({
                    method = "GET",
                    path = "/services/" .. service_name
                })

                assert.are.equal(updated_service.path, "/headers")
                assert.are.equal(service_response.body.path, updated_service.path)
            end)

            context(":update_or_create", function()

                it("should update a service", function()

                    local service_name = "test_service"

                    local service = kong_client.services:create({
                        name = service_name,
                        url = "http://mockbin:8080/request"
                    })

                    local service_url = "http://mockbin:8080/headers"
                    service.url = service_url

                    local updated_service = kong_client.services:update_or_create(service)

                    local service_response = send_admin_request({
                        method = "GET",
                        path = "/services/" .. service_name
                    })

                    assert.are.equal(updated_service.path, "/headers")
                    assert.are.equal(service_response.body.path, updated_service.path)
                end)

                it("should create a service", function()

                    local service_id = "62c45fad-4b59-458d-b64f-8d8eebbe6866"
                    local service_name = "test_service"

                    local service = {
                        id = service_id,
                        name = service_name,
                        url = "http://mockbin:8080/request"
                    }

                    local created_service = kong_client.services:update_or_create(service)

                    local service_response = send_admin_request({
                        method = "GET",
                        path = "/services/" .. service_name
                    })

                    assert.are.equal(created_service.id, service_id)
                    assert.are.equal(service_response.body.id, created_service.id)
                end)

            end)

            it("should find a service by id", function()

                local service_name = "test_service"

                local service = kong_client.services:create({
                    name = service_name,
                    url = "http://mockbin:8080/request"
                })

                local found_service = kong_client.services:find_by_id(service.id)

                local service_response = send_admin_request({
                    method = "GET",
                    path = "/services/" .. service_name
                })

                assert.are.equal(service_response.body.id, found_service.id)
            end)

            it("should delete a service", function()

                local service_name = "test_service"

                local service = kong_client.services:create({
                    name = service_name,
                    url = "http://mockbin:8080/request"
                })

                kong_client.services:delete(service.id)

                local service_response = send_admin_request({
                    method = "GET",
                    path = "/services/" .. service_name
                })

                assert.are.equal(service_response.status, 404)
            end)

            it("should list all services", function()

                kong_client.services:create({
                    name = "test_service_1",
                    url = "http://mockbin:8080/request"
                })

                kong_client.services:create({
                    name = "test_service_2",
                    url = "http://mockbin:8080/request"
                })

                local limit = 1
                local services = kong_client.services:all(limit)

                local service_response = send_admin_request({
                    method = "GET",
                    path = "/services/",
                    body = {
                        limit = 100
                    }
                })

                assert.are.equal(#service_response.body.data, #services)
            end)
        end)

        describe("Route", function()
            it("should create a route for a service", function()

                local service_name = "test_service"

                local service = kong_client.services:create({
                    name = service_name,
                    url = "http://mockbin:8080/request"
                })

                local route = kong_client.routes:create_for_service(service.id, "/test_route")

                local service_routes_response = send_admin_request({
                    method = "GET",
                    path = "/services/" .. service_name .. "/routes/"
                })

                local expected_route = service_routes_response.body.data[1]

                assert.are.equal(expected_route.id, route.id)
            end)

            it("should list routes of a service", function()

                local service_name = "test_service"

                local service = kong_client.services:create({
                    name = service_name,
                    url = "http://mockbin:8080/request"
                })

                kong_client.routes:create_for_service(service.id, "/test_route")

                local routes = kong_client.services:list_routes(service.id)

                local service_routes_response = send_admin_request({
                    method = "GET",
                    path = "/services/" .. service_name .. "/routes/"
                })

                assert.are.same(service_routes_response.body, routes)
            end)
        end)

        describe("Plugin", function()
            it("should list enabled plugins", function()

                local plugins = kong_client.plugins:list_enabled()

                local plugins_response = send_admin_request({
                    method = "GET",
                    path = "/plugins/enabled"
                })

                assert.are.same(plugins_response.body.enabled_plugins, plugins)
            end)

            it("should get the schema of a plugin", function()

                local plugin_name = "key-auth"

                local schema = kong_client.plugins:get_schema(plugin_name)

                local plugin_schema_response = send_admin_request({
                    method = "GET",
                    path = "/plugins/schema/" .. plugin_name
                })

                assert.are.same(plugin_schema_response.body, schema)
            end)

            it("should create a plugin", function()

                local plugin_name = "key-auth"

                local plugin = kong_client.plugins:create({
                    name = plugin_name
                })

                local plugin_response = send_admin_request({
                    method = "GET",
                    path = "/plugins/",
                    body = {
                        name = plugin_name
                    }
                })

                local expected_plugin = plugin_response.body.data[1]

                assert.are.equal(expected_plugin.id, plugin.id)
            end)

            it("should create a plugin for a service", function()

                local service_name = "test_service"

                local service = kong_client.services:create({
                    name = service_name,
                    url = "http://mockbin:8080/request"
                })

                local plugin = kong_client.services:add_plugin(service.id, {
                    name = "key-auth"
                })

                local service_plugins_response = send_admin_request({
                    method = "GET",
                    path = "/services/" .. service_name .. "/plugins/"
                })

                local expected_plugin = service_plugins_response.body.data[1]

                assert.are.equal(expected_plugin.id, plugin.id)
            end)

            it("should create a plugin for a route", function()

                local service = kong_client.services:create({
                    name = "test_service",
                    url = "http://mockbin:8080/request"
                })

                local route = kong_client.routes:create_for_service(service.id, "/test_route")

                local plugin = kong_client.routes:add_plugin(route.id, {
                    name = "key-auth"
                })

                local route_plugins_response = send_admin_request({
                    method = "GET",
                    path = "/routes/" .. route.id .. "/plugins/"
                })

                local expected_plugin = route_plugins_response.body.data[1]

                assert.are.equal(expected_plugin.id, plugin.id)
            end)
        end)

    end)

end)
