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
          function = "m";
          loop = "l";
          parameter = "a";
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
    extraFiles."after/queries/nix/textobjects.scm" = # query
      ''
        ; extends

        (binding
          attrpath: (_) @assignment.lhs
          expression: (_) @assignment.rhs @assignment.inner) @assignment.outer
      '';
  };
}
