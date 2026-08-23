{ pkgs, ... }:
{
  config.plugins.lsp = {
    enable = true;
    keymaps = {
      diagnostic = {
        "]d" = "goto_next";
        "[d" = "goto_prev";
      };
      lspBuf = {
        "<Leader>rn" = "rename";
        "<Leader>ca" = "code_action";
        "<C-k>" = "signature_help";
        g0 = "document_symbol";
        gW = "workspace_symbol";
        gd = "definition";
        gD = "declaration";
        gi = "implementation";
        gr = "references";
        gt = "type_definition";
      };
    };
    onAttach = # lua
      ''
        vim.api.nvim_command("augroup LSP")
        vim.api.nvim_command("autocmd!")
        if client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_command("autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()")
          vim.api.nvim_command("autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()")
          vim.api.nvim_command("autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()")
        end
        vim.api.nvim_command("augroup END")

        require("completion").on_attach(client, bufnr)
      '';
    servers = {
      arduino_language_server.enable = true;
      bashls.enable = true;
      jsonls.enable = true;
      just = {
        enable = true;
        # nixpkgs' just-lsp is pinned to 0.4.5; overrideAttrs can't bump it
        # since rustPlatform.buildRustPackage computes the vendor (cargoHash)
        # derivation from the original attrs before overrideAttrs runs, so a
        # new cargoHash there is silently ignored (the fetch still targets the
        # 0.4.5 vendor hash). Rebuild via buildRustPackage directly instead.
        package = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
          pname = "just-lsp";
          version = "0.6.2";
          src = pkgs.fetchFromGitHub {
            owner = "terror";
            repo = "just-lsp";
            tag = finalAttrs.version;
            hash = "sha256-B9ydV1q73auAVVaW9FyYmgyPncX9OXlE4w1IPst9buU=";
          };
          cargoHash = "sha256-vUILbwu5/EQFG/8GCr3tQtmipGrVVwzgoV1oyDHWx0o=";
          # `mod::recipe` dependencies aren't resolved into the submodule's
          # namespace (https://github.com/terror/just-lsp/issues/496), so the
          # missing-dependencies rule flags every cross-module dependency as
          # unresolved. Skip module-qualified names (containing "::") rather
          # than disabling the rule outright, so a genuinely missing bare
          # recipe still errors.
          postPatch = ''
            substituteInPlace src/rule/missing_dependencies.rs \
              --replace-fail \
                "if !recipe_names.contains(&dependency.name) {" \
                "if !dependency.name.contains(\"::\") && !recipe_names.contains(&dependency.name) {"
          '';
          nativeInstallCheckInputs = [ pkgs.versionCheckHook ];
          doInstallCheck = true;
          meta = {
            description = "Language server for just";
            homepage = "https://github.com/terror/just-lsp";
            license = pkgs.lib.licenses.cc0;
            mainProgram = "just-lsp";
          };
        });
      };
      pyrefly.enable = true;
      nil_ls = {
        enable = true;
        settings.diagnostics.ignored = [ "unused_binding" ]; # handled by deadnix
      };
      lua_ls = {
        enable = true;
        settings = {
          diagnostics.globals = [ "vim" ];
          runtime.version = "Lua 5.1";
        };
      };
    };
  };
}
