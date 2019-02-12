package = "kong-client"
version = "1.0.0-1"
supported_platforms = {"linux", "macosx"}
source = {
  url = "git+https://github.com/emartech/kong-plugin-boilerplate.git",
  tag = "1.0.0"
}
description = {
  summary = "Boilerplate for Kong API gateway plugins.",
  homepage = "https://github.com/emartech/kong-plugin-boilerplate",
  license = "MIT"
}
dependencies = {
  "lua ~> 5.1",
  "classic 0.1.0-1",
  "LuaCov >= 0.13.0-1"
}
build = {
  type = "builtin",
  modules = {
    ["kong_client"] = "src/kong_client.lua",
    ["kong_client.resources.resource_object"] = "src/resources/resource_object.lua",
    ["kong_client.resources.service"] = "src/resources/service.lua",
    ["kong_client.resources.route"] = "src/resources/route.lua",
    ["kong_client.resources.plugin"] = "src/resources/plugin.lua",
    ["kong_client.resources.consumer"] = "src/resources/consumer.lua",
    ["kong_client.helpers.merge"] = "src/helpers/merge.lua",
    ["kong_client.helpers.pager"] = "src/helpers/pager.lua",
    ["kong_client.test_helpers"] = "spec/test_helpers.lua"
  }
}
