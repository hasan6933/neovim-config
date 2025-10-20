return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
		vim.opt.termguicolors = true
		require("nvim-tree").setup({
			actions = {
				use_system_clipboard = true,
				change_dir = {
					enable = true,
					global = true,
					restrict_above_cwd = true,
				},
			},
			diagnostics = {
				enable = true,
				show_on_dirs = true,
				show_on_open_dirs = true,
				debounce_delay = 0,
				severity = {
					min = vim.diagnostic.severity.HINT,
					max = vim.diagnostic.severity.ERROR,
				},
				icons = {
					hint = "",
					info = "",
					warning = "",
					error = "",
				},
			},
			modified = {
				enable = true,
			},
			view = {
				width = 37,
				signcolumn = "no",
				preserve_window_proportions = true,
			},
			sync_root_with_cwd = true,
			reload_on_bufenter = true,
			respect_buf_cwd = true,
			renderer = {
				root_folder_label = false,
				indent_width = 2,
				indent_markers = {
					enable = true,
					icons = {
						corner = "╰",
						edge = "│",
						item = "│",
						bottom = "",
						none = " ",
					},
				},
				icons = {
					symlink_arrow = "  ",
					diagnostics_placement = "after",
					bookmarks_placement = "after",
					glyphs = {
						default = "",
						symlink = "",
						bookmark = "",
						modified = "●",
						hidden = "󰜌",
						folder = {
							arrow_closed = "",
							arrow_open = "",
							default = "",
							open = "",
							empty = "",
							empty_open = "",
							symlink = "",
							symlink_open = "",
						},
						git = {
							unstaged = "✗",
							staged = "✓",
							unmerged = "",
							renamed = "",
							untracked = "",
							deleted = "",
							ignored = "",
						},
					},
				},
			},
			update_focused_file = {
				enable = true,
				update_root = {
					enable = false,
					ignore_list = {},
				},
				exclude = false,
			},
		})
	end,
}
