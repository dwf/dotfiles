{ lib, ...}: with lib; let
  camelToSnake =
    builtins.replaceStrings upperChars (map (c: "_${c}") lowerChars);

  # Definition inside a 'let' seems to be necessary for recursion.
  asLua = arg: let
    curlies = s: "{" + s + "}";
    handlers = {
      bool = value: if value then "true" else "false";
      int = toString;
      float = toString;
      list = l: curlies (concatMapStringsSep ", " asLua l);
      null = _: "nil";
      set = s: curlies (concatStringsSep ", "
        (mapAttrsToList (n: v: "${n} = ${asLua v}") s));
      string = lib.strings.escapeNixString;
    };
  in (getAttr (builtins.typeOf arg) handlers) arg;
in { inherit camelToSnake asLua; }
