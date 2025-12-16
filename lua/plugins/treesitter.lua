return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local parsers = {
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
		}
		require("nvim-treesitter").install(parsers)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = parsers,
			callback = function(arg)
				-- syntax highlighting, provided by Neovim
				vim.treesitter.start(arg.buf)
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.wo.foldmethod = "expr"
				-- indentation, provided by nvim-treesitter
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})
	end,
}
