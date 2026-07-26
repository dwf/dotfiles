{ lib, ... }:
let
  helpers = lib.nixvim;
  mkKey =
    key: fn: desc:
    {
      __unkeyed-1 = key;
      __unkeyed-2 = helpers.mkRaw "function() ${fn} end";
      mode = [ "n" ];
      desc = "dap: ${desc}";
    };
in
{
  config = {
    plugins.dap = {
      enable = true;
      lazyLoad.settings.keys = [
        (mkKey "<leader>db" "require('dap').toggle_breakpoint()" "toggle breakpoint")
        (mkKey "<leader>dB" "require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))" "conditional breakpoint")
        (mkKey "<leader>dc" "require('dap').continue()" "continue / start")
        (mkKey "<leader>di" "require('dap').step_into()" "step into")
        (mkKey "<leader>do" "require('dap').step_over()" "step over")
        (mkKey "<leader>dO" "require('dap').step_out()" "step out")
        (mkKey "<leader>dt" "require('dap').terminate()" "terminate")
        (mkKey "<leader>dr" "require('dap').repl.toggle()" "toggle repl")
        (mkKey "<leader>dl" "require('dap').run_last()" "re-run last")
      ];
      # dap-ui isn't triggered by any of the keys above, so force-load it
      # here (same trigger_load idiom as overseer.nix/neogen.nix) to make
      # sure `require("dapui")` below resolves once a debug session starts.
      extensionConfigLua = # lua
        ''
          require('lz.n').trigger_load('nvim-dap-ui')
          require("dap").listeners.after.event_initialized["dapui_config"] = function()
            require("dapui").open()
          end
          require("dap").listeners.before.event_terminated["dapui_config"] = function()
            require("dapui").close()
          end
          require("dap").listeners.before.event_exited["dapui_config"] = function()
            require("dapui").close()
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
    plugins.dap-python = {
      enable = true;
      resolvePython = # lua
        ''
          function()
            return vim.fn.exepath("python3")
          end
        '';
    };

    plugins.dap-virtual-text.enable = true;

    plugins.dap-ui = {
      enable = true;
      lazyLoad.settings.keys = [
        (mkKey "<leader>du" "require('dapui').toggle()" "toggle ui")
      ];
    };
  };
}
