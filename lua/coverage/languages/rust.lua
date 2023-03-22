local M = {}

local common = require "coverage.languages.common"
local util = require "coverage.util"
local Path = require "plenary.path"

--- Returns a list of signs to be placed.
M.sign_list = common.sign_list

--- Returns a summary report.
M.summary = common.summary

--- Loads a coverage report.
-- @param callback called with the results of the coverage report
M.load = function(callback)
  vim.notify("Run tests...", vim.log.levels.INFO, {
    title = "Coverage",
    timeout = 1000,
  })

  local cmd = "cargo llvm-cov test --no-report --tests --benches --examples --all-targets --all-features --workspace"
  vim.fn.jobstart(cmd, {
    on_exit = vim.schedule_wrap(function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Tests fails with code " .. exit_code, vim.log.levels.ERROR, {
          title = "Coverage",
        })
        return
      end

      local tmpreport = os.tmpname()

      vim.fn.jobstart("cargo llvm-cov report --lcov --output-path " .. tmpreport, {
        on_exit = vim.schedule_wrap(function()
          if exit_code ~= 0 then
            vim.notify("Report fail with code " .. exit_code, vim.log.levels.ERROR, {
              title = "Coverage",
            })
            return
          end

          print(tmpreport)

          callback(util.lcov_to_table(Path:new(tmpreport)))
        end),
      })
    end),
  })
end

return M
