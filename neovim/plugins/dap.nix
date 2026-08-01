{ lib, ... }:
let
  helpers = lib.nixvim;
  mkKey = key: fn: desc: {
    __unkeyed-1 = key;
    __unkeyed-2 = helpers.mkRaw "function() ${fn} end";
    mode = [ "n" ];
    desc = "dap: ${desc}";
  };
in
{
  config = {
    # DapStoppedSign colors just the stopped-line marker glyph in
    # tokyonight's orange (moon palette), not the whole line. Must be
    # `highlightOverride` (-> extraConfigLuaPost) rather than `highlight`
    # (-> extraConfigLuaPre): the `colorscheme` command itself runs from
    # extraConfigLuaPre too, and `:colorscheme` does an implicit `hi clear`
    # that wipes any highlight set before it.
    highlightOverride.DapStoppedSign.fg = "#ff966c";
    plugins = {

      dap = {
        enable = true;
        signs = {
          dapBreakpoint.text = "🛑";
          dapStopped.texthl = "DapStoppedSign";
        };
        lazyLoad.settings.keys = [
          (mkKey "<leader>db" "require('dap').toggle_breakpoint()" "toggle breakpoint")
          (mkKey "<leader>dB" "require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))"
            "conditional breakpoint"
          )
          (mkKey "<leader>dc" "require('dap').continue()" "continue / start")
          (mkKey "<leader>di" "require('dap').step_into()" "step into")
          (mkKey "<leader>do" "require('dap').step_over()" "step over")
          (mkKey "<leader>dO" "require('dap').step_out()" "step out")
          (mkKey "<leader>dt" "require('dap').terminate()" "terminate")
          (mkKey "<leader>dr" "require('dap').repl.toggle()" "toggle repl")
          (mkKey "<leader>dl" "require('dap').run_last()" "re-run last")
          # VSCode-style single-key bindings for the actions pressed repeatedly
          # in a tight loop while stepping through a debug session.
          (mkKey "<F5>" "require('dap').continue()" "continue / start")
          (mkKey "<F9>" "require('dap').toggle_breakpoint()" "toggle breakpoint")
          (mkKey "<F10>" "require('dap').step_over()" "step over")
          (mkKey "<F11>" "require('dap').step_into()" "step into")
          (mkKey "<F12>" "require('dap').step_out()" "step out")
        ];
        # dap-ui, dap-python and dap-virtual-text aren't triggered by any of
        # the keys above, so force-load them here (same trigger_load idiom as
        # overseer.nix/neogen.nix). Wrapped in `mkBefore`: dap-python's own
        # module contributes its `require("dap-python").setup(...)` call to
        # this same option (it uses `callSetup = false` and writes directly
        # here rather than generating its own deferred config), and plain
        # `types.lines` definitions from separate files aren't guaranteed to
        # merge in any particular order - `mkBefore` forces our trigger_load
        # ahead of it regardless, so nvim-dap-python is guaranteed to be on
        # the runtimepath before its own setup() call runs.
        extensionConfigLua =
          lib.mkBefore # lua
            ''
              require('lz.n').trigger_load('nvim-dap-ui')
              require('lz.n').trigger_load('nvim-dap-python')
              require('lz.n').trigger_load('nvim-dap-virtual-text')
              local shown_fkey_hint = false
              require("dap").listeners.after.event_initialized["dapui_config"] = function()
                shown_fkey_hint = false
                require("dapui").open()
              end
              require("dap").listeners.before.event_terminated["dapui_config"] = function()
                require("dapui").close()
              end
              require("dap").listeners.before.event_exited["dapui_config"] = function()
                require("dapui").close()
              end
              -- Reminder of the F-key bindings above, shown once per session
              -- the first time a real breakpoint (not a step/pause/exception)
              -- stops execution.
              require("dap").listeners.after.event_stopped["fkey_hint"] = function(_, body)
                if shown_fkey_hint or not (body and body.reason == "breakpoint") then
                  return
                end
                shown_fkey_hint = true
                vim.notify(
                  "### Debug keys\n\n"
                    .. "- `F5` continue\n"
                    .. "- `F9` toggle breakpoint\n"
                    .. "- `F10` step over\n"
                    .. "- `F11` step into\n"
                    .. "- `F12` step out",
                  vim.log.levels.INFO,
                  { title = "Debugger stopped", timeout = 6000 }
                )
              end
            '';
      };

      # Default `adapterPythonPath` already builds a python3 + debugpy closure
      # via Nix and default `configurations.python` (launch file/module,
      # attach) via `includeConfigs`, so there's nothing else to wire up here.
      # `resolvePython` is overridden below: it decides which interpreter
      # actually *runs the debuggee* (separate from `adapterPythonPath`, which
      # only runs the debugpy engine itself). The plugin default checks
      # $VIRTUAL_ENV/$CONDA_PREFIX, which a Nix devShell typically doesn't
      # set, so it'd otherwise fall back to the debugpy closure and miss the
      # project's own dependencies. Resolving python3 off $PATH instead
      # always matches whatever devShell/venv Neovim was launched from.
      dap-python = {
        enable = true;
        # No commands/keys of its own to trigger on - it only ever contributes
        # text to `plugins.dap.extensionConfigLua` above (see `mkBefore` note),
        # so it's force-loaded from there instead of gaining a real trigger.
        lazyLoad.settings.lazy = true;
        resolvePython = # lua
          ''
            function()
              return vim.fn.exepath("python3")
            end
          '';
      };

      dap-virtual-text = {
        enable = true;
        lazyLoad.settings.cmd = [
          "DapVirtualTextEnable"
          "DapVirtualTextDisable"
          "DapVirtualTextToggle"
          "DapVirtualTextForceRefresh"
        ];
        lazyLoad.settings.keys = [
          (mkKey "<leader>dv" "require('nvim-dap-virtual-text').toggle()" "toggle virtual text")
        ];
      };

      dap-ui = {
        enable = true;
        lazyLoad.settings.keys = [
          (mkKey "<leader>du" "require('dapui').toggle()" "toggle ui")
        ];
      };
    };
  };
}
