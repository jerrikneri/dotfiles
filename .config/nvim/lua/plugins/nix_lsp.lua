-- ~/.config/nvim/lua/plugins/lsp-nix.lua
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      nil_ls = {
        settings = {
          ["nil"] = {
            formatting = {
              command = { "alejandra" }, -- use alejandra for formatting
            },
          },
        },
      },
    },
  },
}

