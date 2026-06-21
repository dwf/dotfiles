{ lib, ... }:
let
  helpers = lib.nixvim;

  keys = {
    assignment = "=";
    call = "f";
    class = "c";
    conditional = "i";
    fold = "z";
    function = "m";
    loop = "l";
    parameter = "a";
    scope = "s";
  };

  mkSelectKeymap =
    {
      key,
      query,
      desc,
    }:
    {
      inherit key;
      mode = [
        "x"
        "o"
      ];
      action = helpers.mkRaw ''
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('${query}', 'textobjects')
        end
      '';
      options = { inherit desc; };
    };

  mkMoveKeymap =
    {
      key,
      fn,
      query,
      queryGroup ? "textobjects",
      desc,
    }:
    {
      inherit key;
      mode = [
        "n"
        "x"
        "o"
      ];
      action = helpers.mkRaw ''
        function()
          require('nvim-treesitter-textobjects.move').${fn}('${query}', '${queryGroup}')
        end
      '';
      options = { inherit desc; };
    };

  mkSwapKeymap =
    {
      key,
      fn,
      query,
      desc,
    }:
    {
      inherit key;
      mode = "n";
      action = helpers.mkRaw ''
        function()
          require('nvim-treesitter-textobjects.swap').${fn}('${query}')
        end
      '';
      options = { inherit desc; };
    };
in
{
  config = {
    plugins.treesitter-textobjects = {
      enable = true;
      lazyLoad.settings = {
        event = [ "DeferredUIEnter" ];
        after = ''
          function()
            require('nvim-treesitter-textobjects').setup {
              select = {
                lookahead = true,
              },
              move = {
                set_jumps = true,
              },
            }
          end
        '';

      };
    };

    keymaps =
      # Keymaps as suggested by https://www.josean.com/posts/nvim-treesitter-and-textobjects
      map mkSelectKeymap [
        {
          key = "a${keys.assignment}";
          query = "@assignment.outer";
          desc = "outer part of an assignment";
        }
        {
          key = "i${keys.assignment}";
          query = "@assignment.inner";
          desc = "inner part of an assignment";
        }
        {
          key = "l${keys.assignment}";
          query = "@assignment.lhs";
          desc = "left hand side of an assignment";
        }
        {
          key = "r${keys.assignment}";
          query = "@assignment.rhs";
          desc = "right hand side of an assignment";
        }
        {
          key = "a${keys.parameter}";
          query = "@parameter.outer";
          desc = "outer part of a parameter/argument";
        }
        {
          key = "i${keys.parameter}";
          query = "@parameter.inner";
          desc = "inner part of a parameter/argument";
        }
        {
          key = "a${keys.conditional}";
          query = "@conditional.outer";
          desc = "outer part of a conditional";
        }
        {
          key = "i${keys.conditional}";
          query = "@conditional.inner";
          desc = "inner part of a conditional";
        }
        {
          key = "a${keys.loop}";
          query = "@loop.outer";
          desc = "outer part of a loop";
        }
        {
          key = "i${keys.loop}";
          query = "@loop.inner";
          desc = "inner part of a loop";
        }
        {
          key = "a${keys.call}";
          query = "@call.outer";
          desc = "outer part of a function call";
        }
        {
          key = "i${keys.call}";
          query = "@call.inner";
          desc = "inner part of a function call";
        }
        {
          key = "a${keys.function}";
          query = "@function.outer";
          desc = "outer part of a method/function definition";
        }
        {
          key = "i${keys.function}";
          query = "@function.inner";
          desc = "inner part of a method/function definition";
        }
        {
          key = "a${keys.class}";
          query = "@class.outer";
          desc = "outer part of a class";
        }
        {
          key = "i${keys.class}";
          query = "@class.inner";
          desc = "inner part of a class";
        }
      ]
      ++ map mkMoveKeymap [
        {
          key = "]${keys.call}";
          fn = "goto_next_start";
          query = "@call.outer";
          desc = "Next function call start";
        }
        {
          key = "]${keys.function}";
          fn = "goto_next_start";
          query = "@function.outer";
          desc = "Next method/function definition start";
        }
        {
          key = "]${keys.class}";
          fn = "goto_next_start";
          query = "@class.outer";
          desc = "Next class start";
        }
        {
          key = "]${keys.conditional}";
          fn = "goto_next_start";
          query = "@conditional.outer";
          desc = "Next conditional start";
        }
        {
          key = "]${keys.loop}";
          fn = "goto_next_start";
          query = "@loop.outer";
          desc = "Next loop start";
        }
        {
          key = "]${keys.scope}";
          fn = "goto_next_start";
          query = "@local.scope";
          queryGroup = "locals";
          desc = "Next scope";
        }
        {
          key = "]${keys.fold}";
          fn = "goto_next_start";
          query = "@fold";
          queryGroup = "folds";
          desc = "Next fold";
        }
        {
          key = "]${keys.assignment}";
          fn = "goto_next_start";
          query = "@assignment.outer";
          desc = "Next assignment";
        }
        {
          key = "]${keys.parameter}";
          fn = "goto_next_start";
          query = "@parameter.inner";
          desc = "Next parameter/argument start";
        }
        {
          key = "]${lib.toUpper keys.call}";
          fn = "goto_next_end";
          query = "@call.outer";
          desc = "Next function call end";
        }
        {
          key = "]${lib.toUpper keys.function}";
          fn = "goto_next_end";
          query = "@function.outer";
          desc = "Next method/function definition end";
        }
        {
          key = "]${lib.toUpper keys.class}";
          fn = "goto_next_end";
          query = "@class.outer";
          desc = "Next class end";
        }
        {
          key = "]${lib.toUpper keys.conditional}";
          fn = "goto_next_end";
          query = "@conditional.outer";
          desc = "Next conditional end";
        }
        {
          key = "]${lib.toUpper keys.loop}";
          fn = "goto_next_end";
          query = "@loop.outer";
          desc = "Next loop end";
        }
        {
          key = "]${lib.toUpper keys.parameter}";
          fn = "goto_next_end";
          query = "@parameter.inner";
          desc = "Next parameter/argument end";
        }
        {
          key = "[${keys.call}";
          fn = "goto_previous_start";
          query = "@call.outer";
          desc = "Previous function call start";
        }
        {
          key = "[${keys.function}";
          fn = "goto_previous_start";
          query = "@function.outer";
          desc = "Previous method/function definition start";
        }
        {
          key = "[${keys.class}";
          fn = "goto_previous_start";
          query = "@class.outer";
          desc = "Previous class start";
        }
        {
          key = "[${keys.conditional}";
          fn = "goto_previous_start";
          query = "@conditional.outer";
          desc = "Previous conditional start";
        }
        {
          key = "[${keys.loop}";
          fn = "goto_previous_start";
          query = "@loop.outer";
          desc = "Previous loop start";
        }
        {
          key = "[${keys.assignment}";
          fn = "goto_previous_start";
          query = "@assignment.outer";
          desc = "Previous assignment";
        }
        {
          key = "[${keys.parameter}";
          fn = "goto_previous_start";
          query = "@parameter.inner";
          desc = "Previous parameter/argument start";
        }
        {
          key = "[${lib.toUpper keys.call}";
          fn = "goto_previous_end";
          query = "@call.outer";
          desc = "Previous function call end";
        }
        {
          key = "[${lib.toUpper keys.function}";
          fn = "goto_previous_end";
          query = "@function.outer";
          desc = "Previous method/function definition end";
        }
        {
          key = "[${lib.toUpper keys.class}";
          fn = "goto_previous_end";
          query = "@class.outer";
          desc = "Previous class end";
        }
        {
          key = "[${lib.toUpper keys.conditional}";
          fn = "goto_previous_end";
          query = "@conditional.outer";
          desc = "Previous conditional end";
        }
        {
          key = "[${lib.toUpper keys.loop}";
          fn = "goto_previous_end";
          query = "@loop.outer";
          desc = "Previous loop end";
        }
        {
          key = "[${lib.toUpper keys.parameter}";
          fn = "goto_previous_end";
          query = "@parameter.inner";
          desc = "Previous parameter/argument end";
        }
      ]
      ++ map mkSwapKeymap [
        {
          key = "<leader>a";
          fn = "swap_next";
          query = "@parameter.inner";
          desc = "Swap with next parameter/argument";
        }
        {
          key = "<leader>A";
          fn = "swap_previous";
          query = "@parameter.inner";
          desc = "Swap with previous parameter/argument";
        }
      ];

    # The textobjects defined by treesitter-textobjects for nix doesn't include
    # assignment.  Define the obvious mappings:
    # - rhs and inner are the expression after =, like in Python
    # - lhs is the (possibly length one) attribute path to the left
    # - outer is the entire statement
    #
    # N.B. defining in queries/ instead of after/queries wipes out the globally
    # defined nix textobjects, and the '; extends' is load bearing for them to
    # combine properly.
    extraFiles."after/queries/nix/textobjects.scm".text = # query
      ''
        ; extends

        (binding
          attrpath: (attrpath attr: (_) @attrpath_component) @assignment.lhs
          expression: (_) @assignment.rhs @assignment.inner) @assignment.outer
      '';

    files."ftplugin/nix.lua" = {
      plugins.treesitter.enable = true;
      keymaps =
        map
          (
            {
              key,
              fn,
              desc,
            }:
            {
              inherit key;
              mode = [
                "n"
                "x"
                "o"
              ];
              action = helpers.mkRaw ''
                function()
                  require('nvim-treesitter-textobjects.move').${fn}('@attrpath_component', 'textobjects')
                end
              '';
              options = {
                inherit desc;
                buffer = true;
              };
            }
          )
          [
            {
              key = "]r";
              fn = "goto_next_start";
              desc = "Next attribute path component start";
            }
            {
              key = "[r";
              fn = "goto_previous_start";
              desc = "Previous attribute path component start";
            }
            {
              key = "]R";
              fn = "goto_next_end";
              desc = "Next attribute path component end";
            }
            {
              key = "[R";
              fn = "goto_previous_end";
              desc = "Previous attribute path component end";
            }
          ];
    };
  };
}
