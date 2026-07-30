#!/usr/bin/env bash
# install.sh — one-shot bootstrap for a freshly cloned nvim-min.
#
# What it does, in order:
#   1. Detects your OS/package manager and installs whatever's missing from
#      the requirements list (git, curl, tar, a C compiler, ripgrep, fd,
#      lazygit, node+npm). Skips anything already present.
#   2. Symlinks bin/nvim-min-setup and bin/nvims onto your PATH.
#   3. Wires the `nv` alias and PATH entry into your shell rc (idempotent —
#      safe to re-run).
#   4. Bootstraps nvim itself: installs plugins, treesitter parsers, and all
#      LSP servers/formatters via Mason (this genuinely takes a few minutes
#      the first time).
#   5. Prints where the docs live, and offers to launch the interactive
#      config CLI (nvim-min-setup) right now.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_MIN_APPNAME="nvim-min"

# ---- output helpers ---------------------------------------------------------
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
step() { printf '\n\033[1;34m▸\033[0m %s\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
skip() { printf '  \033[90m·\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
err()  { printf '  \033[31m✗\033[0m %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---- 1. detect package manager ----------------------------------------------
step "Detecting your platform"

PKG=""
if have brew; then
  PKG="brew"                    # Homebrew or Linuxbrew — no sudo needed, preferred when present
elif have apt-get; then PKG="apt"
elif have dnf; then PKG="dnf"
elif have pacman; then PKG="pacman"
elif have apk; then PKG="apk"
elif have zypper; then PKG="zypper"
fi

if [[ -z "$PKG" ]]; then
  warn "No known package manager found (brew/apt/dnf/pacman/apk/zypper)."
  warn "Install the requirements listed in README.md manually, then re-run this script."
else
  ok "Using '$PKG' to install missing tools"
fi

pkg_install() {
  # pkg_install <apt-name> <dnf-name> <pacman-name> <brew-name> <apk-name>
  local apt_n="$1" dnf_n="$2" pac_n="$3" brew_n="$4" apk_n="$5"
  case "$PKG" in
    brew)   brew install "$brew_n" ;;
    apt)    sudo apt-get update -qq && sudo apt-get install -y "$apt_n" ;;
    dnf)    sudo dnf install -y "$dnf_n" ;;
    pacman) sudo pacman -S --noconfirm "$pac_n" ;;
    apk)    sudo apk add "$apk_n" ;;
    zypper) sudo zypper install -y "$apt_n" ;;
    *)      return 1 ;;
  esac
}

ensure_tool() {
  # ensure_tool <check-cmd> <human-name> <apt> <dnf> <pacman> <brew> <apk>
  local cmd="$1" name="$2"
  if have "$cmd"; then
    skip "$name already installed"
    return 0
  fi
  if [[ -z "$PKG" ]]; then
    warn "$name missing — install it manually (see README.md)"
    return 1
  fi
  info_line="Installing $name via $PKG..."
  printf '  %s\n' "$info_line"
  if pkg_install "$3" "$4" "$5" "$6" "$7"; then
    ok "$name installed"
  else
    warn "$name install failed — install it manually (see README.md)"
  fi
}

# ---- 2. required tools -------------------------------------------------------
step "Checking requirements"

ensure_tool git      "git"        git    git    git    git    git
ensure_tool curl     "curl"       curl   curl   curl   curl   curl
ensure_tool tar      "tar"        tar    tar    tar    gnu-tar tar
ensure_tool cc       "a C compiler" build-essential gcc base-devel gcc build-base
ensure_tool rg       "ripgrep"    ripgrep ripgrep ripgrep ripgrep ripgrep
ensure_tool npm      "node + npm" nodejs nodejs nodejs node   nodejs

# fd's binary is named `fd` everywhere except Debian/Ubuntu, where an
# unrelated package already owns that name and apt's fd-find package
# installs it as `fdfind` instead — `ensure_tool`'s single check-cmd can't
# express "either name", so this needs its own block (same reason
# tree-sitter-cli/lazygit below aren't plain ensure_tool calls either).
# Optional: snacks.nvim's file picker falls back to plain `find` without it.
if have fd || have fdfind; then
  skip "fd already installed"
elif [[ -n "$PKG" ]]; then
  printf '  Installing fd...\n'
  pkg_install fd-find fd-find fd fd fd && ok "fd installed" || warn "fd install failed (optional — find-files falls back to a slower search)"
else
  warn "fd not found — optional, find-files falls back to a slower search without it"
fi

# nvim-treesitter needs a *real* tree-sitter-cli 0.26+ to compile parsers.
# Distro packages are usually far too old (Ubuntu/Debian ship 0.20.x) —
# brew is the one place that reliably has a current version, so it's
# special-cased here the same way lazygit is below.
if have tree-sitter && [[ "$(tree-sitter --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)" > "0.25" ]]; then
  skip "tree-sitter-cli already installed (0.26+)"
elif have brew; then
  printf '  Installing tree-sitter-cli via brew (distro packages are usually too old)...\n'
  brew install tree-sitter-cli && ok "tree-sitter-cli installed" || warn "tree-sitter-cli install failed"
else
  warn "tree-sitter-cli 0.26+ not found and no brew available to install it."
  warn "Install manually: https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md"
  warn "(distro apt/dnf packages are typically too old — this needs a real 0.26+)"
fi

# basedpyright/ruff (the Python LSP servers) install via Mason using
# `python3 -m venv` + pip inside it. Checking `import venv` alone isn't
# enough — a venv can be created structurally but still lack a working pip
# (broken/disabled ensurepip is common on minimal Python installs), which
# fails these two installs at the pip step with a confusing
# "spawn: python3 failed" error. Actually create a throwaway venv and check
# for pip inside it, rather than trusting the module import.
venv_has_pip() {
  local tmp; tmp="$(mktemp -d)"
  python3 -m venv "$tmp" >/dev/null 2>&1
  local result=1
  [[ -x "$tmp/bin/pip" ]] && result=0
  rm -rf "$tmp"
  return $result
}

if venv_has_pip; then
  skip "python3 venv + pip already working"
elif have brew; then
  # Preferred even on apt/dnf systems: confirmed in practice that some
  # distro Python builds ship with ensurepip deliberately stripped out,
  # which apt installing python3-venv/python3-pip does not fix (the venv
  # module and pip package show up, but ensurepip inside a *created* venv
  # is still broken) — brew's Python doesn't have this problem, and
  # brew's bin dir is already ahead of /usr/bin on PATH so it's picked up
  # automatically, no shell config changes needed.
  printf '  Installing python3 via brew (working venv+pip, needed for basedpyright/ruff)...\n'
  brew install python@3.14 && ok "python3 (brew) installed" || warn "brew python install failed"
elif have python3; then
  if [[ "$PKG" == "apt" ]]; then
    py_minor="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
    printf '  Installing python3-venv + python3-pip (needed for basedpyright/ruff)...\n'
    if sudo apt-get install -y "python${py_minor}-venv" python3-pip 2>/dev/null || sudo apt-get install -y python3-venv python3-pip; then
      ok "python3-venv + python3-pip installed"
    else
      warn "install failed — basedpyright/ruff won't install until you run:"
      warn "  sudo apt-get install python${py_minor}-venv python3-pip"
    fi
  else
    warn "python3 can't create a working venv+pip — basedpyright/ruff may fail to install."
    warn "On Debian/Ubuntu this needs separate packages (python3-venv, python3-pip); other distros usually bundle both."
  fi
else
  warn "python3 not found — basedpyright/ruff (Python LSP) won't be installable until it is"
fi

if have lazygit; then
  skip "lazygit already installed"
elif [[ "$PKG" == "brew" ]]; then
  printf '  Installing lazygit via brew...\n'
  brew install lazygit && ok "lazygit installed" || warn "lazygit install failed"
elif have brew; then
  printf '  Installing lazygit via brew (fallback — not reliably packaged by %s)...\n' "$PKG"
  brew install lazygit && ok "lazygit installed" || warn "lazygit install failed"
else
  warn "lazygit not found and no brew available to install it."
  warn "Install manually: https://github.com/jesseduffield/lazygit#installation"
fi

if ! have nvim; then
  warn "Neovim not found."
  if [[ "$PKG" == "brew" ]]; then
    printf '  Installing neovim via brew...\n'
    brew install neovim && ok "neovim installed"
  else
    err "Install Neovim 0.12+ yourself (https://github.com/neovim/neovim/releases), then re-run this script."
    exit 1
  fi
else
  nvim_version="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
  ok "Neovim $nvim_version found"
  major="$(echo "$nvim_version" | cut -d. -f1)"
  minor="$(echo "$nvim_version" | cut -d. -f2)"
  if (( major == 0 && minor < 12 )); then
    warn "nvim-min needs Neovim 0.12+; you have $nvim_version."
    warn "Distro-packaged Neovim is often outdated — consider https://github.com/neovim/neovim/releases"
  fi
fi

# ---- 3. install the setup CLI's own dependencies ----------------------------
step "Installing nvim-min-setup's dependencies (@clack/prompts, picocolors)"

# These belong to the CLI in bin/, not to nvim — installed here, in the repo
# root's own package.json, entirely separate from nvim's runtime.
( cd "$REPO_DIR" && npm install --no-fund --no-audit --silent )
ok "CLI dependencies installed"

# ---- 4. symlink the CLI helpers ---------------------------------------------
step "Linking bin/ helpers onto PATH"

mkdir -p "$HOME/.local/bin"
for tool in nvim-min-setup nvims; do
  ln -sf "$REPO_DIR/bin/$tool" "$HOME/.local/bin/$tool"
  ok "$tool -> ~/.local/bin/$tool"
done

# ---- 5. shell rc (idempotent) ------------------------------------------------
step "Wiring up your shell"

detect_rc() {
  case "${SHELL:-}" in
    */zsh) echo "$HOME/.zshrc" ;;
    */bash) echo "$HOME/.bashrc" ;;
    *) echo "$HOME/.profile" ;;
  esac
}
RC_FILE="$(detect_rc)"
touch "$RC_FILE"

# Checks for the actual functional content, not a marker comment — so this
# stays idempotent even against a manual edit that didn't come from this
# script (e.g. ~/.local/bin already on PATH from an unrelated dotfiles setup).
add_once() {
  local label="$1" grep_pattern="$2" line="$3"
  if grep -qE "$grep_pattern" "$RC_FILE" 2>/dev/null; then
    skip "$label already configured in $RC_FILE"
  else
    printf '\n# %s\n%s\n' "$label" "$line" >> "$RC_FILE"
    ok "Added $label to $RC_FILE"
  fi
}

add_once '~/.local/bin on PATH' '\.local/bin' 'export PATH="$HOME/.local/bin:$PATH"'
add_once 'nv alias (nvim-min)' 'alias nv=' "alias nv=\"NVIM_APPNAME=$NVIM_MIN_APPNAME nvim\""

# ---- 6. bootstrap nvim itself -------------------------------------------------
step "Installing plugins, LSP servers, and treesitter parsers (this takes a few minutes)"

export NVIM_APPNAME="$NVIM_MIN_APPNAME"
nvim --headless "+Lazy! sync" +qa 2>&1 | grep -v '^$' || true

# Everything below needs plugins force-loaded regardless of their normal
# lazy-load trigger (event/cmd/keys) — there's no file buffer open to fire
# nvim-treesitter's BufReadPost, and mason-lspconfig's own automatic install
# intentionally never runs in headless mode (checked its source: it skips
# ensure_installed whenever #vim.api.nvim_list_uis() == 0, which is always
# true under --headless). Both work fine on your first real, interactive
# launch regardless — calling the same functions directly here just means
# it's already done by the time you open nvim.
BOOTSTRAP_LUA="$(mktemp)"
cat > "$BOOTSTRAP_LUA" <<'LUA'
-- Force-loading nvim-lspconfig runs lsp.lua's config(), which is what calls
-- mason-lspconfig.setup({ ensure_installed = {...} }) with the real list —
-- without this, mason-lspconfig.features.ensure_installed() below would see
-- an empty list and do nothing.
require("lazy").load({ plugins = { "nvim-treesitter", "nvim-lspconfig" } })
require("nvim-treesitter.install").ensure_installed_sync()

local mr = require("mason-registry")

-- Belt-and-suspenders: ensure_installed() resolves lua/plugins/lsp.lua's
-- actual ensure_installed list (the single source of truth) via
-- mason-lspconfig's own lspconfig-name -> mason-package-name mapping. The
-- explicit `targets` list below is a hardcoded fallback that's already been
-- verified to work end-to-end even if that resolution ever changes shape —
-- both are idempotent, so having both costs nothing.
mr.refresh(function()
  require("mason-lspconfig.features.ensure_installed")()
end)

local targets = {
  "vtsls", "eslint-lsp", "html-lsp", "css-lsp", "tailwindcss-language-server",
  "json-lsp", "yaml-language-server", "lua-language-server", "basedpyright",
  "ruff", "bash-language-server", "dockerfile-language-server",
  "docker-compose-language-service", "terraform-ls", "marksman",
  "prettierd", "stylua", "shfmt",
}
for _, name in ipairs(targets) do
  local ok, pkg = pcall(mr.get_package, name)
  if ok and not pkg:is_installed() and not pkg:is_installing() then
    pkg:install()
  end
end

vim.wait(600000, function()
  for _, name in ipairs(targets) do
    local ok, pkg = pcall(mr.get_package, name)
    if ok and not pkg:is_installed() then return false end
  end
  return true
end, 1000)
LUA

printf '  Waiting for LSP servers + formatters to install (up to 10 min on a slow connection)\n'
nvim --headless -c "luafile $BOOTSTRAP_LUA" +qa >/dev/null 2>&1 || true
rm -f "$BOOTSTRAP_LUA"
ok "nvim bootstrap complete"

# ---- 7. wrap up ----------------------------------------------------------------
echo
printf '\033[1;32m╭──────────────────────────────────────────────────────────────╮\033[0m\n'
printf '\033[1;32m│\033[0m  \033[1mnvim-min is installed\033[0m                                          \033[1;32m│\033[0m\n'
printf '\033[1;32m╰──────────────────────────────────────────────────────────────╯\033[0m\n'
cat <<EOF

  Launch it              $(printf '\033[1mnv\033[0m')
  Pick between configs   $(printf '\033[1mnvims\033[0m')

  📖 Read the docs — start here:
     $(printf '\033[1;36m%s/docs/index.md\033[0m' "$REPO_DIR")
     or serve it properly:  cd docs && npm install && npm run dev

     • Getting started    docs/guide/getting-started.md
     • Keybindings        docs/guide/keybindings.md   (also: <leader>? inside nvim)
     • The setup CLI      docs/guide/setup-cli.md
     • AI features        docs/guide/ai-features.md
     • Why things are built this way — the decision history:
                          docs/decisions/index.md

  Quick reference without the docs site: README.md, KEYBINDINGS.md

  ⚠ Restart your shell (or run 'source $RC_FILE') to pick up the new
    PATH entry and the 'nv' alias.

EOF

read -r -p "Customize your setup now (AI provider + API key, theme)? [y/N]: " ans
if [[ "$ans" =~ ^[Yy] ]]; then
  "$HOME/.local/bin/nvim-min-setup"
else
  bold "You can run 'nvim-min-setup' any time to configure your AI provider/key, theme, or feature toggles."
fi
