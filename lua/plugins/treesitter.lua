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
	end,
}
