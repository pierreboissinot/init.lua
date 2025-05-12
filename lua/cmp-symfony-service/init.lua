local source = {}

local function log(msg)
  vim.notify("[cmp-symfony-service] " .. msg, vim.log.levels.INFO)
end

source.new = function()
  log("Source created")
  return setmetatable({}, { __index = source })
end

source.is_available = function()
  local ft = vim.bo.filetype
  return ft == "php" or ft == "twig"
end

source.get_trigger_characters = function()
  return { '@' }
end

source.get_keyword_pattern = function()
  return [[@\k*]]
end

source.complete = function(self, params, callback)
  local ft = vim.bo[params.context.bufnr].filetype
  if ft ~= "php" and ft ~= "twig" then
    callback({})
    return
  end
  log("complete called")
  local input = params.context.cursor_before_line
  local query = input:match("@(%w*)$") or ""
  local items = require('cmp-symfony-service.services').get_services(query)
  log("Fetched " .. tostring(#items) .. " services")
  callback(items)
end

return source
