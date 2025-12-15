return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").install({
			"lua",
			"rust",
			"c",
			"cpp",
			"html",
			"css",
			"javascript",
			"typescript",
			"jsonc",
			"json",
			"json5",
			"python",
			"markdown",
			"markdown_inline",
			"toml",
		})
		vim.api.nvim_create_autocmd("FileType", {
			pattern = {
				"lua",
				"rust",
				"c",
				"cpp",
				"html",
				"css",
				"javascript",
				"typescript",
				"jsonc",
				"json",
				"json5",
				"python",
				"markdown",
				"markdown_inline",
				"toml",
			},
			callback = function(arg)
				-- syntax highlighting, provided by Neovim
				vim.treesitter.start(arg.buf)
			end,
		})
	end,
}
