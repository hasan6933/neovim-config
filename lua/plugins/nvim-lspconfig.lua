return {
	"neovim/nvim-lspconfig",
	dependencies = { "saghen/blink.cmp" },
	config = function()
		vim.lsp.config("emmylua_ls", {
			cmd = { "emmylua_ls", "--editor", "neovim" },
			settings = {
				Lua = {
					workspace = {
						library = vim.api.nvim__get_runtime({ "" }, true, {
							is_lua = true,
						}),
					},
					diagnostics = {
						globals = { "*" },
						globalsRegex = { "*" },
					},
				},
			},
		})
		vim.lsp.config("rust_analyzer", {
			capabilities = {
				experimental = {
					commands = {
						commands = {
							"rust-analyzer.showReferences",
							"rust-analyzer.runSingle",
							"rust-analyzer.debugSingle",
						},
					},
				},
			},
			settings = {
				["rust-analyzer"] = {
					cachePriming = {
						numThreads = 255,
					},
					completion = {
						privateEditable = {
							enable = true,
						},
						fullFunctionSignatures = {
							enable = true,
						},
					},
					inlayHints = {
						expressionAdjustmentHints = {
							enable = "always",
						},
						discriminantHints = {
							enable = "always",
						},
						genericParameterHints = {
							type = {
								enable = true,
							},
							lifetime = {
								enable = true,
							},
						},
						implicitDrops = {
							enable = true,
						},
						implicitSizedBoundHints = {
							enable = true,
						},
						lifetimeElisionHints = {
							useParameterNames = true,
							enable = true,
						},
					},
					semanticHighlighting = {
						operator = {
							specialization = {
								enable = true,
							},
						},
						punctuation = {
							enable = true,
							separate = {
								macro = {
									bang = true,
								},
							},
							specialization = {
								enable = true,
							},
						},
					},
				},
			},
		})

		vim.lsp.config("ruff", {
			init_options = {
				settings = {
					-- Ruff language server settings go here
					lint = {
						enable = false,
					},
				},
			},
		})

		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = "*.rs",
			callback = function(args)
				vim.lsp.codelens.refresh({ bufnr = args.buf })
			end,
		})
	end,
}
