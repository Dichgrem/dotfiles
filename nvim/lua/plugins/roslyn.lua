return {
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    opts = {
      filewatching = "nvim",
    },
    config = function(_, opts)
      vim.lsp.config["roslyn"] = vim.tbl_deep_extend("force", vim.lsp.config["roslyn"] or {}, {
        capabilities = {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
        },
      })
      require("roslyn").setup(opts)
    end,
  },
}
