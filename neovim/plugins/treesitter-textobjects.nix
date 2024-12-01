{ lib, ... }:
{
  config = {
    plugins.treesitter-textobjects =
      let
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
      in
      {
        enable = true;
        select = {
          enable = true;
          lookahead = true;

          # Keymaps as suggested by https://www.josean.com/posts/nvim-treesitter-and-textobjects
          keymaps = {
            "a${keys.assignment}" = {
              query = "@assignment.outer";
              desc = "outer part of an assignment";
            };
            "i${keys.assignment}" = {
              query = "@assignment.inner";
              desc = "inner part of an assignment";
            };
            "l${keys.assignment}" = {
              query = "@assignment.lhs";
              desc = "left hand side of an assignment";
            };
            "r${keys.assignment}" = {
              query = "@assignment.rhs";
              desc = "right hand side of an assignment";
            };
            "a${keys.parameter}" = {
              query = "@parameter.outer";
              desc = "outer part of a parameter/argument";
            };
            "i${keys.parameter}" = {
              query = "@parameter.inner";
              desc = "inner part of a parameter/argument";
            };
            "a${keys.conditional}" = {
              query = "@conditional.outer";
              desc = "outer part of a conditional";
            };
            "i${keys.conditional}" = {
              query = "@conditional.inner";
              desc = "inner part of a conditional";
            };
            "a${keys.loop}" = {
              query = "@loop.outer";
              desc = "outer part of a loop";
            };
            "i${keys.loop}" = {
              query = "@loop.inner";
              desc = "inner part of a loop";
            };
            "a${keys.call}" = {
              query = "@call.outer";
              desc = "outer part of a function call";
            };
            "i${keys.call}" = {
              query = "@call.inner";
              desc = "inner part of a function call";
            };
            "a${keys.function}" = {
              query = "@function.outer";
              desc = "outer part of a method/function definition";
            };
            "i${keys.function}" = {
              query = "@function.inner";
              desc = "inner part of a method/function definition";
            };
            "a${keys.class}" = {
              query = "@class.outer";
              desc = "outer part of a class";
            };
            "i${keys.class}" = {
              query = "@class.inner";
              desc = "inner part of a class";
            };
          };
        };
        move = {
          enable = true;
          setJumps = true;
          gotoNextStart = {
            "]${keys.call}" = {
              query = "@call.outer";
              desc = "Next function call start";
            };
            "]${keys.function}" = {
              query = "@function.outer";
              desc = "Next method/function definition start";
            };
            "]${keys.class}" = {
              query = "@class.outer";
              desc = "Next class start";
            };
            "]${keys.conditional}" = {
              query = "@conditional.outer";
              desc = "Next conditional start";
            };
            "]${keys.loop}" = {
              query = "@loop.outer";
              desc = "Next loop start";
            };
            "]${keys.scope}" = {
              query = "@scope";
              queryGroup = "locals";
              desc = "Next scope";
            };
            "]${keys.fold}" = {
              query = "@fold";
              queryGroup = "folds";
              desc = "Next fold";
            };
            "]${keys.assignment}" = {
              query = "@assignment.outer";
              desc = "Next assignment";
            };
            "]${keys.parameter}" = {
              query = "@parameter.inner";
              desc = "Next parameter/argument start";
            };
          };
          gotoNextEnd = {
            "]${lib.toUpper keys.call}" = {
              query = "@call.outer";
              desc = "Next function call end";
            };
            "]${lib.toUpper keys.function}" = {
              query = "@function.outer";
              desc = "Next method/function definition end";
            };
            "]${lib.toUpper keys.class}" = {
              query = "@class.outer";
              desc = "Next class end";
            };
            "]${lib.toUpper keys.conditional}" = {
              query = "@conditional.outer";
              desc = "Next conditional end";
            };
            "]${lib.toUpper keys.loop}" = {
              query = "@loop.outer";
              desc = "Next loop end";
            };
            "]${lib.toUpper keys.parameter}" = {
              query = "@parameter.inner";
              desc = "Next parameter/argument end";
            };
          };
          gotoPreviousStart = {
            "[${keys.call}" = {
              query = "@call.outer";
              desc = "Previous function call start";
            };
            "[${keys.function}" = {
              query = "@function.outer";
              desc = "Previous method/function definition start";
            };
            "[${keys.class}" = {
              query = "@class.outer";
              desc = "Previous class start";
            };
            "[${keys.conditional}" = {
              query = "@conditional.outer";
              desc = "Previous conditional start";
            };
            "[${keys.loop}" = {
              query = "@loop.outer";
              desc = "Previous loop start";
            };
            "[${keys.assignment}" = {
              query = "@assignment.outer";
              desc = "Previous assignment";
            };
            "[${keys.parameter}" = {
              query = "@parameter.inner";
              desc = "Previous parameter/argument start";
            };
          };
          gotoPreviousEnd = {
            "[${lib.toUpper keys.call}" = {
              query = "@call.outer";
              desc = "Previous function call end";
            };
            "[${lib.toUpper keys.function}" = {
              query = "@function.outer";
              desc = "Previous method/function definition end";
            };
            "[${lib.toUpper keys.class}" = {
              query = "@class.outer";
              desc = "Previous class end";
            };
            "[${lib.toUpper keys.conditional}" = {
              query = "@conditional.outer";
              desc = "Previous conditional end";
            };
            "[${lib.toUpper keys.loop}" = {
              query = "@loop.outer";
              desc = "Previous loop end";
            };
            "[${lib.toUpper keys.parameter}" = {
              query = "@parameter.inner";
              desc = "Previous parameter/argument end";
            };
          };
        };
        swap = {
          enable = true;
          swapNext = {
            "<leader>a" = "@parameter.inner";
          };
          swapPrevious = {
            "<leader>A" = "@parameter.inner";
          };
        };
      };

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

    files."ftplugin/nix.lua".plugins = {
      treesitter.enable = true;
      treesitter-textobjects = {
        enable = true;
        move = {
          enable = true;
          gotoNextStart."]r" = {
            query = "@attrpath_component";
            desc = "Next attribute path component start";
          };
          gotoPreviousStart."[r" = {
            query = "@attrpath_component";
            desc = "Previous attribute path component start";
          };
          gotoNextEnd."]R" = {
            query = "@attrpath_component";
            desc = "Next attribute path component end";
          };
          gotoPreviousEnd."[R" = {
            query = "@attrpath_component";
            desc = "Previous attribute path component end";
          };
        };
      };
    };
  };
}
