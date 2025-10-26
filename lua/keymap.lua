vim.keymap.set({ "n", "i", "c", "v" }, "<C-s>", "<cmd>w!<CR>")
vim.keymap.set({ "n", "v" }, "<leader>qb", "<cmd>BufferClose<CR>")
vim.keymap.set({ "n", "v" }, "<leader>qw", "<cmd>q<CR>")
vim.keymap.set("n", "<A-Up>", ":m-2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-Down>", ":m+<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-/>", "gcc", { remap = true })
vim.keymap.set("v", "<C-/>", "gc", { remap = true })
vim.keymap.set("i", "<C-/>", function()
	vim.cmd("normal gcc")
end, { remap = true })
vim.keymap.set({ "n", "v", "i" }, "<A-Right>", function()
	vim.cmd("bnext")
end)
vim.keymap.set({ "n", "v", "i" }, "<A-Left>", function()
	vim.cmd("bprevious")
end)

vim.keymap.set("n", "<leader>fs", function()
	local fs_process = require("fs.utils.process")

	-- Check if we're in an actual directory (not home or root)
	local current_path = vim.fn.getcwd()
	local home_dir = vim.fn.expand("~")

	-- Don't start if we're in home directory or root
	if current_path == home_dir or current_path == "/" then
		vim.notify("Not starting Five Server in home or root directory", vim.log.levels.WARN)
		return
	end

	-- Check if there are actual files in the directory
	local has_files = false
	local uv = vim.uv or vim.loop -- Handle both neovim versions

	-- Use vim.fn.readdir() which is more reliable
	local files = vim.fn.readdir(current_path)
	if files then
		for _, file in ipairs(files) do
			local full_path = current_path .. "/" .. file
			local stat = uv.fs_stat(full_path)
			if stat and stat.type == "file" then
				has_files = true
				break
			end
		end
	end

	if not has_files then
		vim.notify("No files found in current directory", vim.log.levels.WARN)
		return
	end

	-- Check if there's already a server running for the current path
	if fs_process.path_has_instance(current_path) then
		-- Stop the server
		local job_id = fs_process.get_path_instance(current_path)
		if job_id then
			fs_process.stop(job_id)
		end
	else
		-- Start the server
		fs_process.start()
	end
end, { desc = "Toggle Five Server" })
