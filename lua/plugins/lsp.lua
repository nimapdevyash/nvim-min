return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = { ui = { border = "rounded" } },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "b0o/schemastore.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Installs non-LSP tools (formatters) mason-lspconfig doesn't manage.
      -- Uses mason.nvim's own registry API directly instead of pulling in
      -- mason-tool-installer.nvim for what's a ~10-line job.
      local function mason_ensure_installed(names)
        local registry = require("mason-registry")
        local function install_missing()
          for _, name in ipairs(names) do
            local ok, pkg = pcall(registry.get_package, name)
            if ok and not pkg:is_installed() then
              pkg:install()
            end
          end
        end
        registry.refresh(install_missing)
      end
      -- Buffer-local keymaps + perf tweaks, set once per attached buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          -- Treesitter already highlights syntax; LSP semantic tokens would
          -- redo that work (a real per-edit cost on vtsls/eslint) for little
          -- extra benefit here, so skip it.
          if client then
            client.server_capabilities.semanticTokensProvider = nil
          end

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
          end

          map("n", "gd", function() require("fzf-lua").lsp_definitions() end, "Goto definition")
          map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
          map("n", "gr", function() require("fzf-lua").lsp_references() end, "Goto references")
          map("n", "gI", function() require("fzf-lua").lsp_implementations() end, "Goto implementation")
          map("n", "gy", function() require("fzf-lua").lsp_typedefs() end, "Goto type definition")
          map("n", "K", vim.lsp.buf.hover, "Hover docs")
          map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("n", "<leader>cs", function() require("fzf-lua").lsp_document_symbols() end, "Document symbols")
          map("n", "<leader>cS", function() require("fzf-lua").lsp_live_workspace_symbols() end, "Workspace symbols")
          map({ "n", "v" }, "<leader>cf", function()
            require("conform").format({ async = true, lsp_fallback = true })
          end, "Format buffer")

          -- Highlight references under cursor, only if the server actually supports it
          if client and client:supports_method("textDocument/documentHighlight") then
            local group = vim.api.nvim_create_augroup("lsp_doc_highlight_" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = bufnr,
              group = group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd("CursorMoved", {
              buffer = bufnr,
              group = group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      -- Don't recompute diagnostics on every keystroke — big win on large TS files
      vim.diagnostic.config({ update_in_insert = false })

      -- Apply blink.cmp's capabilities to every server
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- ---- Per-server overrides (only where the defaults aren't enough) ----

      vim.lsp.config("vtsls", {
        settings = {
          typescript = {
            tsserver = { maxTsServerMemory = 4096 },
            inlayHints = {
              parameterNames = { enabled = "literals" },
              variableTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = false },
              functionLikeReturnTypes = { enabled = false },
            },
          },
          vtsls = {
            experimental = { completion = { enableServerSideFuzzyMatch = true } },
          },
        },
      })

      -- Auto-fix eslint issues on save, using the buffer-local command lspconfig creates
      local base_eslint_on_attach = vim.lsp.config.eslint and vim.lsp.config.eslint.on_attach
      vim.lsp.config("eslint", {
        settings = { workingDirectories = { mode = "auto" } },
        on_attach = function(client, bufnr)
          if base_eslint_on_attach then base_eslint_on_attach(client, bufnr) end
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "silent! LspEslintFixAll",
          })
        end,
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            diagnostics = { globals = { "vim" } },
            hint = { enable = true },
          },
        },
      })

      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            analysis = { typeCheckingMode = "standard", autoImportCompletions = true },
          },
        },
      })

      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })

      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" },
            schemas = require("schemastore").yaml.schemas(),
          },
        },
      })

      vim.lsp.config("tailwindcss", {
        filetypes = { "html", "css", "javascript", "typescript", "javascriptreact", "typescriptreact" },
      })

      -- ---- Install + enable ---- (mason.nvim itself is set up by its own plugin spec)
      mason_ensure_installed({ "prettierd", "stylua", "shfmt" })
      require("mason-lspconfig").setup({
        ensure_installed = {
          "vtsls", "eslint", "html", "cssls", "tailwindcss", "jsonls", "yamlls",
          "lua_ls", "basedpyright", "ruff", "bashls", "dockerls",
          "docker_compose_language_service", "terraformls", "marksman",
        },
        automatic_enable = true,
      })
    end,
  },
}
