return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	config = function()
		require("tokyonight").setup({
			style = "night",
			light_style = "day",
			cache = true,
			day_brightness = 0.3,
			styles = {
				comments = { italic = false },
				keywords = { italic = false },
				functions = {},
				variables = {},
			},
			plugins = {
				all = true,
				auto = true,
			},
			transparent = false,
			dim_inactive = false,
			lualine_bold = false,
			terminal_colors = true,
			on_colors = function(colors)
				colors.error = colors.red
				colors.warning = colors.yellow
				colors.info = colors.blue
				colors.hint = colors.green1
			end,
			on_highlights = function(highlights, colors)
				highlights.NvimTreeWinSeparator = {
					bg = colors.bg,
					fg = colors.bg,
				}
				highlights.NvimTreeModifiedIcon = {
					fg = colors.warning,
					link = 0,
					global_link = 0,
				}

				highlights.DiagnosticUnderlineError.undercurl = nil
				highlights.DiagnosticUnderlineError.underdashed = true

				highlights.DiagnosticUnderlineWarn.undercurl = nil
				highlights.DiagnosticUnderlineWarn.underdashed = true

				highlights.DiagnosticUnderlineInfo.undercurl = nil
				highlights.DiagnosticUnderlineInfo.underdashed = true

				highlights.DiagnosticUnderlineHint.undercurl = nil
				highlights.DiagnosticUnderlineHint.underdashed = true

				highlights["@lsp.type.unresolvedReference"].undercurl = nil
				highlights["@lsp.type.unresolvedReference"].underdashed = true

				highlights.BlinkCmpKindFile = {
					bg = "NONE",
					link = 0,
					global_link = 0,
				}

				highlights.NvimTreeIndentMarker = {
					fg = colors.comment,
				}

				highlights["LspReferenceText"] = {
					bg = colors.bg_highlight,
				}

				highlights.PreProc = {
					fg = colors.green1,
				}

				highlights["@keyword.import"] = {
					fg = "#bb9af7",
				}

				highlights["@lsp.type.variable"] = {
					fg = colors.fg,
				}

				highlights["@type.builtin"] = {
					fg = "#ff9cae",
				}

				highlights["@lsp.type.enum"] = {
					fg = colors.green1,
				}

				highlights.Type = {
					fg = "#ffcc66",
				}

				highlights.Special = {
					fg = colors.cyan,
				}

				highlights["@lsp.type.method"] = {
					fg = colors.blue1,
				}

				highlights["@lsp.type.function"] = {
					fg = colors.blue,
				}

				highlights["@lsp.typemod.macro.defaultLibrary.rust"] = {
					fg = colors.blue,
				}

				highlights["@markup.link.label.markdown_inline"] = {
					fg = "#70b1da",
				}

				highlights["@lsp.type.formatSpecifier"] = {
					fg = colors.green1,
				}

				highlights["@lsp.type.lifetime.rust"] = {
					fg = colors.fg,
				}

				highlights["@lsp.typemod.function.defaultLibrary.lua"] = {
					link = nil,
				}

				highlights["@lsp.typemod.method.defaultLibrary.rust"] = {
					link = nil,
				}

				highlights["@lsp.typemod.struct.defaultLibrary.rust"] = {
					link = nil,
				}

				highlights["@lsp.typemod.enum.defaultLibrary.rust"] = {
					link = nil,
				}

				highlights["@lsp.type.struct.rust"] = {
					link = "@type.builtin",
				}

				highlights["@lsp.type.struct.rust"] = {
					link = "Type",
				}

				highlights["@lsp.typemod.enumMember.defaultLibrary.rust"] = {
					link = nil,
				}
			end,
		})
		vim.cmd([[colorscheme tokyonight]])
	end,
}
