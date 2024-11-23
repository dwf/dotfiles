{
  config = {
    plugins.treesitter-textobjects = {
      enable = true;
      select = {
        enable = true;
        lookahead = true;

        # Keymaps as suggested by https://www.josean.com/posts/nvim-treesitter-and-textobjects
        keymaps = {
          "a=" = {
            query = "@assignment.outer";
            desc = "outer part of an assignment";
          };
          "i=" = {
            query = "@assignment.inner";
            desc = "inner part of an assignment";
          };
          "l=" = {
            query = "@assignment.lhs";
            desc = "left hand side of an assignment";
          };
          "r=" = {
            query = "@assignment.rhs";
            desc = "right hand side of an assignment";
          };
          "aa" = {
            query = "@parameter.outer";
            desc = "outer part of a parameter/argument";
          };
          "ia" = {
            query = "@parameter.inner";
            desc = "inner part of a parameter/argument";
          };
          "ai" = {
            query = "@conditional.outer";
            desc = "outer part of a conditional";
          };
          "ii" = {
            query = "@conditional.inner";
            desc = "inner part of a conditional";
          };
          "al" = {
            query = "@loop.outer";
            desc = "outer part of a loop";
          };
          "il" = {
            query = "@loop.inner";
            desc = "inner part of a loop";
          };
          "af" = {
            query = "@call.outer";
            desc = "outer part of a function call";
          };
          "if" = {
            query = "@call.inner";
            desc = "inner part of a function call";
          };
          "am" = {
            query = "@function.outer";
            desc = "outer part of a method/function definition";
          };
          "im" = {
            query = "@function.inner";
            desc = "inner part of a method/function definition";
          };
          "ac" = {
            query = "@class.outer";
            desc = "outer part of a class";
          };
          "ic" = {
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
