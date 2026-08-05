local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local events = require("luasnip.util.events")
local c = require("luasnip.extras.conditions")

-- True unless the cursor sits inside a string or comment node -- guards
-- against a trigger typed as prose (a comment mentioning "pkgs.", a string
-- containing "with lib;") being mistaken for real code and adding a module
-- argument. Mirrors python/auto_imports.lua's not_in_string_or_comment,
-- but against tree-sitter-nix's node names: plain strings are
-- string_expression, `''...''` strings are indented_string_expression, and
-- both `#` and `/* */` comments are just comment.
--
-- A `${...}` interpolation's contents are real Nix code even though it's
-- nested inside a string_expression/indented_string_expression -- e.g. in
-- `"before ${pkgs.foo} after"`, pkgs.foo's own ancestor chain runs
-- ...select_expression < interpolation < string_expression..., so walking
-- all the way up would wrongly treat it as "inside a string". Stop at the
-- first interpolation and treat that as code, not string content.
local function not_in_string_or_comment()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "nix")
  if not ok or not parser then
    return true
  end
  -- get_node() doesn't force a parse itself -- it just returns nil for any
  -- position on a tree that hasn't been parsed yet, which would silently
  -- fail this check open (permissive) rather than actually detecting
  -- string/comment context.
  parser:parse()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, math.max(cursor[2] - 1, 0)
  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { row, col } })
  while node do
    local node_type = node:type()
    if node_type == "interpolation" then
      return true
    end
    if node_type == "string_expression" or node_type == "indented_string_expression" or node_type == "comment" then
      return false
    end
    node = node:parent()
  end
  return true
end

-- Deferred (vim.schedule), not run synchronously in pre_expand: these are
-- autosnippets (expand on typing, no expand key), same mechanism as
-- python-helpers' jnp. snippet -- and for the same reason that one needs
-- deferring, this does too: ensure_arg's insertion point can coincide
-- with the spot the snippet's own extmark for re-inserting the trigger
-- text sits at (e.g. typing `pkgs.` at the very start of a headerless
-- file), and editing there synchronously, before that extmark settles,
-- garbles the two together. Deferring until after the snippet has
-- finished placing its nodes avoids the collision.
--
-- By the time the deferred callback runs, `trig` (e.g. "pkgs." or
-- "with pkgs;") is back in the buffer right before the cursor -- but as a
-- bare, unfinished expression (nothing typed after the dot yet, no
-- enclosing binding) it's very often not valid Nix on its own, e.g.
-- sitting directly inside `{ }` with nothing else. That doesn't just fail
-- ensure_arg's "is this an attrset" check, it can make tree-sitter unable
-- to find *any* top-level expression at all, which ensure_arg treats as
-- "can't do anything here". So: pull `trig` back out first, run
-- ensure_arg against the buffer exactly as if this snippet hadn't been
-- typed yet, then put it back (extmark-tracked, so it lands correctly
-- even if ensure_arg inserted a new header above it).
local function ensure_arg_callback(name, trig)
  return {
    condition = c.make_condition(not_in_string_or_comment),
    callbacks = {
      [-1] = {
        [events.pre_expand] = function()
          local bufnr = vim.api.nvim_get_current_buf()
          vim.schedule(function()
            local win = vim.api.nvim_get_current_win()
            if vim.api.nvim_win_get_buf(win) ~= bufnr then
              require("nix-module-args").ensure_arg(bufnr, name)
              return
            end

            local cur = vim.api.nvim_win_get_cursor(win)
            local row = cur[1] - 1
            local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, true)[1] or ""
            -- The cursor should sit right after `trig` (its end column),
            -- but luasnip's implicit final tabstop for a snippet with no
            -- explicit insert node can land one column short of that --
            -- check both rather than assume which.
            local end_col
            for _, candidate in ipairs({ cur[2], cur[2] + 1 }) do
              if line:sub(candidate - #trig + 1, candidate) == trig then
                end_col = candidate
                break
              end
            end
            if not end_col then
              -- Not actually right before the cursor (e.g. this got
              -- invoked some other way than a normal expand) -- fall
              -- back to operating on the buffer as-is.
              require("nix-module-args").ensure_arg(bufnr, name)
              return
            end

            local ns = vim.api.nvim_create_namespace("nix_module_args")
            local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, row, end_col - #trig, {})
            vim.api.nvim_buf_set_text(bufnr, row, end_col - #trig, row, end_col, { "" })

            require("nix-module-args").ensure_arg(bufnr, name)

            local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, {})
            vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
            vim.api.nvim_buf_set_text(bufnr, mark[1], mark[2], mark[1], mark[2], { trig })
            if vim.api.nvim_win_get_buf(win) == bufnr then
              vim.api.nvim_win_set_cursor(win, { mark[1] + 1, mark[2] + #trig })
            end
          end)
        end,
      },
    },
  }
end

-- Typing `pkgs.` auto-adds `pkgs` as a module parameter if it isn't one
-- already; the snippet's own body is just the trigger text again, so it's
-- a no-op text-wise beyond firing the callback.
local function dot_autoimport_snippet(name)
  local dotted = name .. "."
  return s(dotted, { t(dotted) }, ensure_arg_callback(name, dotted))
end

-- Same idea for `with pkgs;`.
local function with_autoimport_snippet(name)
  local trig = "with " .. name .. ";"
  return s(trig, { t(trig) }, ensure_arg_callback(name, trig))
end

return {
  s(
    { trig = "_skel", desc = "Basic module template", hidden = true },
    fmt(
      [[
      {{ {}... }}:
      {{
        {}
      }}
      ]],
      {
        i(1),
        i(0),
      }
    ),
    {
      callbacks = {
        [-1] = {
          -- Deferred (vim.schedule), not run synchronously: `leave` can
          -- fire from a CursorMoved-driven auto-exit (cursor wanders out
          -- of the snippet's region while it's still active), and editing
          -- text directly from inside that handler raises "Not allowed to
          -- change text or change window" (E565, textlock). Same fix as
          -- ensure_arg_callback above, different trigger for hitting it.
          [events.leave] = function()
            local bufnr = vim.api.nvim_get_current_buf()
            vim.schedule(function()
              require("nix-module-args").prune_empty_arg(bufnr)
            end)
          end,
        },
      },
    }
  ),
}, {
  dot_autoimport_snippet("pkgs"),
  dot_autoimport_snippet("lib"),
  dot_autoimport_snippet("config"),
  with_autoimport_snippet("pkgs"),
  with_autoimport_snippet("lib"),
}
