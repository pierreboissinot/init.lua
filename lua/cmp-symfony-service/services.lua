---@see https://microsoft.github.io/language-server-protocol/specifications/specification-current/
local M = {}

local function log(msg)
  vim.notify("[cmp-symfony-service.services] " .. msg, vim.log.levels.INFO)
end

local function parse_xml_services()
  local items = {}
  local xml_path = "var/cache/dev/App_KernelDevDebugContainer.xml"
  if vim.fn.filereadable(xml_path) == 0 then
    log("File not found: " .. xml_path)
    return items
  end
  log("Parsing: " .. xml_path)
  local lines = vim.fn.readfile(xml_path)
  for _, line in ipairs(lines) do
    -- Look for lines like: <service id="App\Service\MyService" ... />
    local service_id = line:match('<service%s+id="([^"]+)"')
    if service_id then
      table.insert(items, {
        label = service_id,
        kind = require('cmp').lsp.CompletionItemKind.Class,
        documentation = {
          kind = 'markdown',
          value = string.format('Symfony service: `%s`', service_id)
        }
      })
    end
  end
  log("Parsed " .. tostring(#items) .. " services from XML")
  return items
end

function M.get_services(query)
  log("Fetching services from XML")
  local items = parse_xml_services()
  if query and #query > 0 then
    local matches = {}
    for _, item in ipairs(items) do
      if item.label:lower():find(query:lower(), 1, true) then
        log("Matched service: " .. item.label)
        table.insert(matches, item)
      end
    end
    return matches
  end
  return items
end

function M.clear_cache()
  -- No-op, cache removed
end

return M
