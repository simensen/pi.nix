{
  pkgs,
  lib ? pkgs.lib,
  jail,
}:

{
  inner,
  name ? "pi",
  allowedPkgs ? [ ],
  stateDirs ? [ ],
  forwardEnv ? [ ],
  network ? true,
}:

let
  c = jail.combinators;

  perms =
    [
      c.mount-cwd
      (c.add-pkg-deps allowedPkgs)
    ]
    ++ lib.optional network c.network
    ++ map (dir: c.readwrite (c.noescape "~/.pi/${dir}")) stateDirs
    ++ map c.try-fwd-env forwardEnv;
in
jail name inner perms
