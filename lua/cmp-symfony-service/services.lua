local M = {}

-- parse var/cache/dev/App_KernelDevDebugContainer.xml
-- we will use Sax parser over DOM for performance reason
-- todo: handle cache ?

local lxp = require("lxp")               -- sudo luarocks install luaexpat
local log = require("plenary.log").new({
	plugin = "cmp-symfony-service",
	level = "debug",
	use_console = true,
	highlight = true,
}) -- dependency
local cmp = require('cmp')
log.level = 'debug'


local function get_services()
	local indent = 0

	--@see https://github.com/Haehnchen/idea-php-symfony2-plugin/blob/c58958a5b15583d2bd898f421f76c2ac407f585e/src/main/java/fr/adrienbrault/idea/symfony2plugin/dic/container/util/ServiceContainerUtil.java#L761
	local services = {}

	local callbacks = {
		StartElement = function(parser, name, attr)
			-- log.debug(string.rep("  ", indent) .. "<" .. name .. ">")
			if name == 'service' and attr.id and not attr.id:match("^%.") and attr.class then
				table.insert(services, {
					label = "@" .. attr.id,
					kind = cmp.lsp.CompletionItemKind.Class,
					documentation = {
						kind = 'markdown',
						value = string.format('Class: `%s`', attr.class)
					}
				})
			end
			-- for k, v in pairs(attr) do
				-- log.debug(string.rep("  ", indent + 1) .. k .. '="' .. v .. '"')
			-- end
			indent = indent + 1
		end,

		EndElement = function(parser, name)
			indent = indent - 1
			--log.debug(string.rep("  ", indent) .. "</" .. name .. ">")
		end,

	}
	-- Create parser
	local parser = lxp.new(callbacks)

	-- Read XML file
	local path = "var/cache/dev/App_KernelDevDebugContainer.xml"
	-- local path = "lua/App_KernelDevDebugContainer.xml" -- for develop usage
	local file = io.open(path, "r")
	-- local file = io.open("lua/Simple_App_KernelDevDebugContainer.xml", "r")
	if not file then
		log.error('file does not exist')
		vim.notify("[cmp-symfony-service] XML file not found: " ..path, vim.log.levels.ERROR)
		return {}
	end
	local xml = file:read("*a")
	file:close()
	-- log.debug(xml)

	-- Parse it
	parser:parse(xml)
	parser:parse() -- End document
	parser:close()
	-- log.debug("debug services")
	-- log.debug(services)

	return services
end

M.find_services = function(query)
	-- log.debug("Fetching services from XML")
	local items = get_services()
	-- log.debug(items)
	if query and #query > 0 then
		local matches = {}
		for _, item in ipairs(items) do
			if item.label:lower():find(query:lower(), 1, true) then
				-- log.debug("Matched service: " .. item.label)
				table.insert(matches, item)
			end
		end
		return matches
	end
	-- log.debug(services)
	return items
end

-- Mapping when developing this module
-- nmap <Leader>w :write<CR>:source<CR>
-- M.list_services() -- for development purpose

return M

--[[ inspirations
https://github.com/Haehnchen/idea-php-symfony2-plugin

https://github.com/Haehnchen/idea-php-symfony2-plugin/blob/c58958a5b15583d2bd898f421f76c2ac407f585e/src/main/java/fr/adrienbrault/idea/symfony2plugin/dic/container/util/ServiceContainerUtil.java#L995

https://github.com/nvim-lua/plenary.nvim?tab=readme-ov-file#modules
--]]
