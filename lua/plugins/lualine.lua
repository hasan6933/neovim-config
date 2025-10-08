return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		{ "nvim-tree/nvim-web-devicons" },
	},
	config = function()
		local function lsp_component()
			-- Custom LSP component for lualine
			-- Get all active LSP clients for the current buffer
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				return ""
			end

			-- Define your preferred LSP servers (order affects display priority)
			local preferred_servers = require("mason-lspconfig").get_installed_servers()

			-- Collect all client names
			local names = {}
			for _, client in ipairs(clients) do
				table.insert(names, client.name)
			end

			-- Sort names based on preferred order (preferred first, others follow)
			local preferred_index = {}
			for idx, server in ipairs(preferred_servers) do
				preferred_index[server] = idx
			end

			table.sort(names, function(a, b)
				local a_pos = preferred_index[a] or #preferred_servers + 1
				local b_pos = preferred_index[b] or #preferred_servers + 1
				return a_pos < b_pos
			end)

			-- Format the output with an icon and commas
			return " " .. table.concat(names, ", ") -- Use your preferred icon
		end
		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "auto",
				component_separators = "",
				section_separators = { left = "", right = "" },
				-- disabled_filetypes = {
				--   statusline = {},
				--   winbar = {},
				-- },
				disabled_filetypes = {
					"snacks_dashboard",
				},
				ignore_focus = {},
				always_divide_middle = true,
				always_show_tabline = true,
				globalstatus = true,
				update_in_insert = true,
				refresh = {
					statusline = 50,
					tabline = 100,
					winbar = 100,
				},
			},
			sections = {
				lualine_a = { { "mode", icon = "" } },
				lualine_b = { { "branch", icon = "" }, { "diff", icon = "" } },
				lualine_c = { { lsp_component } },
				lualine_x = {
					"diagnostics",
					"filesize",
					"encoding",
					"filetype",
				},
				lualine_y = { "progress" },
				lualine_z = { { "location", icon = "" } },
			},
			inactive_sections = {
				lualine_a = { { "mode", icon = "" } },
				lualine_b = { { "branch", icon = "" }, { "diff", icon = "" } },
				lualine_c = { { lsp_component } },
				lualine_x = {
					"diagnostics",
					"filesize",
					"encoding",
					"filetype",
				},
				lualine_y = { "progress" },
				lualine_z = { { "location", icon = "" } },
			},
			tabline = {},
			winbar = {},
			inactive_winbar = {},
			extensions = {},
		})
	end,
}
