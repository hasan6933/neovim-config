return {
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		config = function()
			require("lazydev").setup({
				library = {
					-- Or relative, which means they will be resolved from the plugin dir.
					-- It can also be a table with trigger words / mods
					"snacks.nvim",
					-- Only load luvit types when the `vim.uv` word is found
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
					-- always load the LazyVim library
					"LazyVim",
					-- Only load the lazyvim library when the `LazyVim` global is found
					{ path = "LazyVim", words = { "LazyVim" } },
					-- Load the wezterm types when the `wezterm` module is required
					-- Needs `justinsgithub/wezterm-types` to be installed
					{ path = "wezterm-types", mods = { "wezterm" } },
					-- Load the xmake types when opening file named `xmake.lua`
					-- Needs `LelouchHe/xmake-luals-addon` to be installed
					{ path = "xmake-luals-addon/library", files = { "xmake.lua" } },
				},
				-- always enable unless `vim.g.lazydev_enabled = false`
				-- This is the default
				enabled = function(root_dir)
					root_dir = root_dir
					return vim.g.lazydev_enabled == nil and true or vim.g.lazydev_enabled
				end,
				runtime = vim.env.VIMRUNTIME,
			})
		end,
	},
}
