{ lib, pkgs, ... }:
{
  config = {
    extraPlugins = with pkgs.vimPlugins; [ llm-nvim ];
    extraPackages = with pkgs; [ llm-ls ];
    extraConfigLua =
      let
        llmConfig = {
          model = "codegemma:2b"; # the model ID, behavior depends on backend
          backend = "ollama"; # backend ID, "huggingface" | "ollama" | "openai" | "tgi"
          url = "http://localhost:11434/api/generate"; # the http url of the backend
          tokens_to_clear = [ "<|file_separator|>" ]; # tokens to remove from the model's output
          # parameters that are added to the request body, values are arbitrary, you can set any field:value pair here it will be passed as is to the backend
          request_body = {
            parameters = {
              max_new_tokens = 60;
              temperature = 0.2;
              top_p = 0.95;
            };
          };
          # set this if the model supports fill in the middle
          fim = {
            enabled = true;
            prefix = "<|fim_prefix|>";
            middle = "<|fim_middle|>";
            suffix = "<|fim_suffix|>";
          };
          debounce_ms = 150;
          accept_keymap = "<Tab>";
          dismiss_keymap = "<S-Tab>";
          tls_skip_verify_insecure = false;
          # llm-ls configuration, cf llm-ls section
          lsp = {
            bin_path = "${pkgs.llm-ls}/bin/llm-ls";
            version = "${lib.getVersion pkgs.llm-ls}";
          };
          tokenizer.repository = "google/codegemma-2b";
          context_window = 8192; # max number of tokens for the context window
          enable_suggestions_on_startup = false;
          enable_suggestions_on_files = "*"; # pattern matching syntax to enable suggestions on specific files, either a string or a list of strings
          disable_url_path_completion = false; # cf Backend
        };
      in
      # lua
      ''
        require("llm").setup(${lib.generators.toLua { } llmConfig})
      '';
  };
}
