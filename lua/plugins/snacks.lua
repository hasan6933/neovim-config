return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {},
	keys = {
		{
			"<C-e>",
			mode = { "n", "i", "v", "c" },
			function()
				Snacks.picker.explorer({
					diagnostics_open = true,
					git_status_open = true,
					git_untracked = true,
					watch = true,
					hidden = true,
					ignored = true,
					git_status = true,
				})
			end,
		},
		{
			"<a-t>",
			mode = { "n", "t", "v" },
			function()
				Snacks.terminal.toggle("/usr/bin/bash", {
					win = {
						border = "double",
						title = "  Terminal ",
						title_pos = "center",
						enter = true,
						focusable = true,
						width = 0.7,
						height = 0.8,
						backdrop = 45,
					},
				})
			end,
		},
	},
	config = function()
		local function rename_lsp_symbol()
			local current_word = vim.fn.expand("<cword>")
			Snacks.input({
				prompt = "Rename Symbol: ",
				default = current_word,
				focus = true,
			}, function(new_name)
				vim.lsp.buf.rename(new_name)
			end)
		end

		vim.keymap.set("n", "<leader>rn", rename_lsp_symbol, { desc = "Rename symbol via LSP (Snacks)" })

		require("snacks").setup({
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			bigfile = { enabled = false },
			dashboard = {
				sections = {
					{ section = "header" },
					{ section = "keys", gap = 1, padding = 1 },
					{ Snacks.dashboard.sections.startup({ icon = "  " }) },
				},
				enabled = true,
				preset = {
					keys = {
						{
							icon = " ",
							key = "f",
							desc = "Find File",
							action = ":lua Snacks.dashboard.pick('files')",
						},
						{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
						{
							icon = " ",
							key = "g",
							desc = "Find Text",
							action = ":lua Snacks.dashboard.pick('live_grep')",
						},
						{
							icon = " ",
							key = "r",
							desc = "Recent Files",
							action = ":lua Snacks.dashboard.pick('oldfiles')",
						},
						{
							icon = " ",
							key = "c",
							desc = "Config",
							action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
						},
						{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
						{
							icon = "󰒲 ",
							key = "L",
							desc = "Lazy",
							action = ":Lazy",
							enabled = package.loaded.lazy ~= nil,
						},
						{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
					},
				},
			},
			explorer = { enabled = true },
			indent = {
				enabled = true,
				scope = {
					hl = {
						"RainbowDelimiterViolet",
						"RainbowDelimiterRed",
						"RainbowDelimiterYellow",
						"RainbowDelimiterBlue",
						"RainbowDelimiterOrange",
						"RainbowDelimiterGreen",
						"RainbowDelimiterCyan",
					},
					refresh = 10,
				},
			},
			input = { enabled = true, icon = " " },
			picker = {
				enabled = true,
				icons = {
					diagnostics = {
						Error = " ",
						Hint = " ",
						Warn = " ",
						Info = " ",
					},
					files = {
						dir = "",
						dir_open = "",
						enabled = true,
						file = "",
					},
					keymaps = {
						nowait = " ",
					},
					tree = {
						vertical = "│ ",
						middle = "├╴",
						last = "╰╴",
					},
					git = {
						added = "",
						commit = "",
						deleted = "",
						ignored = "",
						modified = "",
						renamed = "",
						staged = "",
						unmerged = "",
						untracked = "",
					},
					kinds = {
						Array = " ",
						Boolean = " ",
						Class = " ",
						Color = " ",
						Control = " ",
						Collapsed = " ",
						Constant = " ",
						Constructor = " ",
						Copilot = " ",
						Enum = " ",
						EnumMember = " ",
						Event = " ",
						Field = " ",
						File = " ",
						Folder = " ",
						Function = " ",
						Interface = " ",
						Key = " ",
						Keyword = " ",
						Method = " ",
						Module = " ",
						Namespace = "󰦮 ",
						Null = " ",
						Number = "󰎠 ",
						Object = " ",
						Operator = " ",
						Package = " ",
						Property = " ",
						Reference = " ",
						Snippet = "󱄽 ",
						String = " ",
						Struct = " ",
						Text = " ",
						TypeParameter = " ",
						Unit = " ",
						Unknown = " ",
						Value = " ",
						Variable = " ",
					},
					lsp = {
						attached = "",
						disabled = "󰨙",
						enabled = "󰔡",
					},
					ui = {},
					undo = {},
				},
				sources = {
					explorer = {
						layout = {
							layout = {
								width = 40,
							},
							auto_hide = { "input" },
						},
					},
				},
			},

			notifier = {
				enabled = true,
				icons = {
					debug = "",
					info = "",
					error = "",
					warn = "",
				},
			},
			quickfile = { enabled = true },
			scope = {
				enabled = true,
				debounce = 10,
			},
			scroll = {
				enabled = false,
			},
			statuscolumn = {
				enabled = true,
				left = { "mark", "sign" },
				right = { "fold", "git" },
				folds = {
					open = true,
				},
			},
			words = {
				enabled = true,
				debounce = 30,
			},
			styles = {
				notifier = {
					fixbuf = true,
				},
				notification = {

					fixbuf = true,
					border = "double",
					wo = {
						winblend = 0,
						wrap = true,
					},
				},
			},
		})
	end,
}
