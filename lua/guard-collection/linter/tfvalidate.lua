local lint = require('guard.lint')

local severities = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
}

return {
  cmd = 'terraform',
  args = { 'validate', '-json', '-no-color' },
  stdin = false,
  parse = function(result, bufnr, fname, cwd)
    if not result or result == '' then
      return {}
    end

    local ok, decoded = pcall(vim.json.decode, result)
    if not ok or decoded.valid or not decoded.diagnostics then
      return {}
    end

    local current = fname:sub(#cwd + 2)

    local output = {}
    for _, d in ipairs(decoded.diagnostics) do
      local range = d.range
      if range and range.filename == current then
        local first = range.start or {}
        local last = range['end'] or first

        table.insert(
          output,
          lint.diag_fmt(
            bufnr,
            (first.line or 1) - 1,
            (first.column or 1) - 1,
            d.detail and string.format('%s - %s', d.summary or '', d.detail) or (d.summary or ''),
            severities[d.severity] or vim.diagnostic.severity.HINT,
            'terraform',
            (last.line or first.line or 1) - 1,
            (last.column or first.column or 1) - 1,
            nil
          )
        )
      end
    end

    return output
  end,
}
