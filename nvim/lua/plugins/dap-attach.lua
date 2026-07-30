return {
  {
    "mfussenegger/nvim-dap",
    dependencies = { "rcarriga/nvim-dap-ui" },
    opts = function(_, opts)
      local dap = require "dap"

      -- Walk up from the current buffer to find the nearest .vscode/launch.json
      -- that is NOT the one getcwd() already covers (to avoid duplicating the built-in provider)
      local builtin_path = vim.fn.getcwd() .. "/.vscode/launch.json"
      dap.providers.configs["dap.vscode.walk"] = function(bufnr)
        local path = vim.api.nvim_buf_get_name(bufnr)
        if path == "" then return {} end
        local dir = vim.fn.fnamemodify(path, ":h")
        while dir ~= "/" do
          local candidate = dir .. "/.vscode/launch.json"
          if vim.fn.filereadable(candidate) == 1 then
            if candidate == builtin_path then return {} end
            local ok, configs = pcall(require("dap.ext.vscode").getconfigs, candidate)
            if ok and configs then
              for _, c in ipairs(configs) do
                c.name = "[repo] " .. c.name
                if c.pid == "${command:pickProcess}" then
                  local program = c.program
                  c.pid = function() return require("dap.utils").pick_process(program) end
                end
                -- codelldb requires env to be a map, not an array
                if type(c.env) == "table" and vim.islist(c.env) then c.env = {} end
              end
              return configs
            end
            return {}
          end
          dir = vim.fn.fnamemodify(dir, ":h")
        end
        return {}
      end

      -- Deduplicate dap.configurations by name to guard against mason-nvim-dap
      -- re-registering defaults on repeated opts calls
      local function dedup(configs)
        local seen, result = {}, {}
        for _, c in ipairs(configs or {}) do
          if not seen[c.name] then
            seen[c.name] = true
            table.insert(result, c)
          end
        end
        return result
      end
      vim.schedule(function()
        for ft, configs in pairs(dap.configurations) do
          local deduped = dedup(configs)
          for _, c in ipairs(deduped) do
            if not c.name:match("^%[") then
              c.name = "[global] " .. c.name
            end
          end
          dap.configurations[ft] = deduped
        end
      end)

      -- Shared state between pid and program pickers
      local last_pick = { pid = nil, program = nil }

      require("dap.utils").pick_process = function(program_hint)
        last_pick.pid = nil
        last_pick.program = nil

        local output = vim.fn.system "ps -eo pid,args"
        local lines = vim.split(output, "\n", { trimempty = true })
        table.remove(lines, 1)

        local procs = {}
        for _, line in ipairs(lines) do
          local pid, args = line:match "^%s*(%d+)%s+(.+)$"
          if pid and args then table.insert(procs, { pid = tonumber(pid), args = args }) end
        end

        local pickers = require "telescope.pickers"
        local finders = require "telescope.finders"
        local conf = require("telescope.config").values
        local actions = require "telescope.actions"
        local action_state = require "telescope.actions.state"

        local binary_hint = program_hint
          and vim.fn.fnamemodify(vim.fn.expand(program_hint), ":t")
          or ""

        local co = coroutine.running()

        pickers
          .new({}, {
            prompt_title = "Attach to Process",
            default_text = binary_hint,
            finder = finders.new_table {
              results = procs,
              entry_maker = function(proc)
                local exe = proc.args:match "^%S+" or ""
                local basename = vim.fn.fnamemodify(exe, ":t")
                local flags = proc.args:sub(#exe + 1)
                return {
                  value = proc,
                  display = string.format("[%d] %s", proc.pid, proc.args),
                  ordinal = string.format("%d %s%s", proc.pid, basename, flags),
                }
              end,
            },
            sorter = conf.generic_sorter {},
            attach_mappings = function(buf, _)
              actions.select_default:replace(function()
                actions.close(buf)
                local proc = action_state.get_selected_entry().value
                last_pick.pid = proc.pid
                last_pick.program = proc.args:match "^(%S+)"
                if co then coroutine.resume(co) end
              end)
              return true
            end,
          })
          :find()

        if co then
          coroutine.yield()
        else
          vim.wait(30000, function() return last_pick.pid ~= nil end, 50)
        end
        return last_pick.pid
      end

      -- Use the system universal lldb-dap for "lldb" type so it can debug both
      -- arm64 and x86_64 (Rosetta) processes. mason codelldb is arm64-only and
      -- produces "Resolved locations: 0" when attaching to Rosetta processes.
      dap.adapters.lldb = {
        type = "executable",
        command = "/usr/local/bin/lldb-dap",
      }
      dap.adapters["lldb-dap"] = dap.adapters.lldb

      -- Ensure the cpp configurations table exists
      dap.configurations.cpp = dap.configurations.cpp or {}
      -- Add the attach configuration
      table.insert(dap.configurations.cpp, {
        name = "Attach to running process",
        type = "lldb",
        request = "attach",
        pid = function() return require("dap.utils").pick_process() end,
        program = function() return last_pick.program end,
        cwd = "${workspaceFolder}",
      })
      -- Mirror it for C and Rust
      dap.configurations.c = dap.configurations.cpp
      dap.configurations.rust = dap.configurations.cpp

      -- Persist breakpoints per CWD
      local bp_file = function()
        return vim.fn.stdpath "data" .. "/dap_breakpoints_" .. vim.fn.sha256(vim.fn.getcwd()) .. ".json"
      end

      -- Restore on startup
      local f = io.open(bp_file(), "r")
      if f then
        local raw = f:read "*a"
        f:close()
        local ok, data = pcall(vim.json.decode, raw)
        if ok and data then
          pcall(require("dap.breakpoints").set_state, data)
        end
      end

      -- Save on exit
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          local bps = require("dap.breakpoints").get()
          if not vim.tbl_isempty(bps) then
            local out = io.open(bp_file(), "w")
            if out then
              out:write(vim.json.encode(bps))
              out:close()
            end
          end
        end,
      })
    end,
  },
}
