local M = {}

local id_counter = 0

local stdout = vim.loop.new_tty(1, false)
if not stdout then
	error("failed to open stdout")
end

local uv = vim.uv
if not uv then
	uv = vim.loop
end

-- Lines 15-37 from http://lua-users.org/wiki/BaseSixtyFour
local ba = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function enc(data)
	return (
		(data:gsub(".", function(x)
			local r, b = "", x:byte()
			for i = 8, 1, -1 do
				r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
			end
			return r
		end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
			if #x < 6 then
				return ""
			end
			local c = 0
			for i = 1, 6 do
				c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
			end
			return ba:sub(c + 1, c + 1)
		end) .. ({ "", "==", "=" })[#data % 3 + 1]
	)
end
-- End of code from http://lua-users.org/wiki/BaseSixtyFour

local Image = {}
Image.__index = Image

function Image:new(filepath)
	id_counter = id_counter + 1
	local obj = setmetatable({}, self)
	obj.filepath_o = filepath
	obj.filepath = filepath
	obj.id = id_counter
	obj.properties = {}
	obj.properties.zoom = 0.9
	obj.properties.o_x = 0
	obj.properties.o_y = 0
	obj.properties.rotation = 0
	return obj
end

function Image:draw(x, y, w, h)
	self.properties.w = w
	self.properties.h = h
	self:pngify()
	self:rescale()
	local file = io.open(self.filepath, "rb")
	if not file then
		print("Error: Could not open file.")
		return
	end
	local data = file:read("*all")
	file:close()
	local encoded_data = enc(data)
	local pos = 1
	local chunk_size = 4096
	stdout:write("\27[" .. x + 2 .. ";" .. y + 4 .. "H")
	while pos <= #encoded_data do
		local chunk = encoded_data:sub(pos, pos + chunk_size - 1)
		pos = pos + chunk_size
		local m = (pos <= #encoded_data) and "1" or "0"
		local cmd
		cmd = "\27_Ga=T,i=10,p="
			.. self.id
			.. ",q=1,r="
			.. h
			.. ",c="
			.. w
			.. ",C=1,f=100,m="
			.. m
			.. ";"
			.. chunk
			.. "\27\\"
		stdout:write(cmd)
		uv.sleep(1)
	end
	stdout:write("\27[" .. x + 1 .. ";" .. y + 3 .. "H")
end

function Image:unload()
	stdout:write("\27_Ga=d\27\\")
end

function Image:rescale()
	local w, h = self.properties.w, self.properties.h
	local o_x, o_y = self.properties.o_x, self.properties.o_y
	local rotation = self.properties.rotation
	local temp_file = "/tmp/scaled" .. self.id .. ".png"
	if vim.fn.filereadable(temp_file) == 1 then
		vim.fn.delete(temp_file)
	end
	local o_x_str = o_x >= 0 and "+" .. o_x or tostring(o_x)
	local o_y_str = o_y >= 0 and "+" .. o_y or tostring(o_y)
	local r_w, r_h = w * self.properties.zoom * 10, h * self.properties.zoom * 23
	local cmd = "magick "
		.. self.filepath
		.. " -resize "
		.. r_w
		.. "x"
		.. r_h
		.. " -background none -rotate "
		.. rotation
		.. " -gravity center -background none "
		.. "-extent "
		.. (w * 10)
		.. "x"
		.. (h * 23)
		.. o_x_str
		.. o_y_str
		.. " "
		.. temp_file
	local result = vim.fn.system(cmd)
	if vim.v.shell_error == 0 then
		self.filepath = temp_file
	else
		vim.api.nvim_err_writeln("Error converting image: " .. result)
		self.filepath = ""
	end
end

function Image:pngify()
	local temp_file = "/tmp/pngify" .. self.id .. ".png"
	local file_type = vim.fn.fnamemodify(self.filepath_o, ":e")
	local cmd
	if file_type == "png" then
		self.filepath = self.filepath_o
		return
	end
	if file_type == "gif" then
		cmd = "magick " .. self.filepath_o .. "[0] " .. temp_file
	else
		cmd = "magick " .. self.filepath_o .. " " .. temp_file
	end
	local result = vim.fn.system(cmd)
	if vim.v.shell_error == 0 then
		self.filepath = temp_file
		self.filepath_o = temp_file
	else
		vim.api.nvim_err_writeln("Error converting image: " .. result)
		self.filepath = ""
	end
end

function M.setup(config)
	local opts = config or {}
	local allowed_types = { png = true, jpg = true, jpeg = true, gif = true, bmp = true }
	local filetypes = {}
	for _, ft in ipairs(opts.filetypes or { "png", "jpg", "jpeg", "gif", "bmp" }) do
		if allowed_types[ft] then
			table.insert(filetypes, ft)
		end
	end
	local formatted = "*." .. table.concat(filetypes, ",*.")
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = formatted,
		callback = function()
			if not vim.b.img then
				vim.b.img = Image:new(vim.fn.expand("%:p"))
			end
			vim.cmd("setlocal buftype=nofile")
			vim.cmd("setlocal nonumber")
			vim.cmd("setlocal norelativenumber")
			vim.cmd("setlocal modifiable")
			local buf = vim.api.nvim_get_current_buf()
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
			vim.cmd("setlocal nomodifiable")
			vim.cmd("setlocal nowrap")
			vim.cmd("setlocal nolist")
			local debounce_timer = nil
			local debounce_interval = 50
			local keypress_state = { o_x = 0, o_y = 0, zoom = 0, rotation = 0 }
			local function redraw()
				if not vim.b.img then
					return
				end
				local image = vim.b.img
				setmetatable(image, Image)
				local win = vim.api.nvim_get_current_win()
				local window_height = vim.api.nvim_win_get_height(win)
				local window_width = vim.api.nvim_win_get_width(win)
				local MAX_OFFSET_X = (window_width * 10) - 150
				local MIN_OFFSET_X = (-window_width * 10) + 150
				local MAX_OFFSET_Y = (window_height * 23) - 150
				local MIN_OFFSET_Y = (-window_height * 23) + 150
				image.properties.o_x =
					math.min(math.max(image.properties.o_x + keypress_state.o_x, MIN_OFFSET_X), MAX_OFFSET_X)
				image.properties.o_y =
					math.min(math.max(image.properties.o_y + keypress_state.o_y, MIN_OFFSET_Y), MAX_OFFSET_Y)
				image.properties.zoom = math.min(math.max(image.properties.zoom + keypress_state.zoom, 0.1), 5)
				image.properties.rotation = (image.properties.rotation + keypress_state.rotation) % 360
				keypress_state = { o_x = 0, o_y = 0, zoom = 0, rotation = 0 }
				local cursor = vim.api.nvim_win_get_position(win)
				local x, y = cursor[1], cursor[2]
				image:draw(x, y, window_width - 6, window_height - 1)
				vim.b.img = image
			end
			local function schedule_redraw()
				if debounce_timer then
					debounce_timer:stop()
					debounce_timer:close()
				end
				debounce_timer = vim.defer_fn(function()
					redraw()
					debounce_timer = nil
				end, debounce_interval)
			end
			local keymaps = {
				move_left = { "<Left>", "h" },
				move_right = { "<Right>", "l" },
				move_down = { "<Down>", "j" },
				move_up = { "<Up>", "k" },
				zoom_in = { "=", "+" },
				zoom_out = { "-", "_" },
				rotate_clockwise = "t",
				rotate_counterclockwise = "T",
				reset = "o",
				rerender = "r",
			}
			local actions = {
				move_left = function()
					keypress_state.o_x = keypress_state.o_x - 30
					schedule_redraw()
				end,
				move_right = function()
					keypress_state.o_x = keypress_state.o_x + 30
					schedule_redraw()
				end,
				move_down = function()
					keypress_state.o_y = keypress_state.o_y + 30
					schedule_redraw()
				end,
				move_up = function()
					keypress_state.o_y = keypress_state.o_y - 30
					schedule_redraw()
				end,
				zoom_in = function()
					keypress_state.zoom = keypress_state.zoom + 0.2
					schedule_redraw()
				end,
				zoom_out = function()
					keypress_state.zoom = keypress_state.zoom - 0.2
					schedule_redraw()
				end,
				rotate_clockwise = function()
					keypress_state.rotation = keypress_state.rotation + 30
					schedule_redraw()
				end,
				rotate_counterclockwise = function()
					keypress_state.rotation = keypress_state.rotation - 30
					schedule_redraw()
				end,
				reset = function()
					local image = vim.b.img
					image.properties.o_x = 0
					image.properties.o_y = 0
					image.properties.rotation = 0
					vim.b.img = image
					redraw()
				end,
				rerender = function()
					redraw()
				end,
			}
			for action, default_keys in pairs(keymaps) do
				local keys = opts.keymap and opts.keymap[action] or default_keys
				if type(keys) ~= "table" then
					keys = { keys }
				end
				for _, key in ipairs(keys) do
					vim.keymap.set("n", key, actions[action], { buffer = buf, noremap = true, silent = true })
				end
			end
			vim.b.no_git_diff = true
			redraw()
		end,
	})
	vim.api.nvim_create_autocmd("VimResized", {
		pattern = formatted,
		callback = function()
			if not vim.b.img then
				vim.b.img = Image:new(vim.fn.expand("%:p"))
			end
			local image = vim.b.img
			if image then
				setmetatable(image, Image)
			end
			local win_id = vim.api.nvim_get_current_win()
			local cursor = vim.api.nvim_win_get_position(win_id)
			local x, y = cursor[1], cursor[2]
			local win = vim.api.nvim_get_current_win()
			local window_height = vim.api.nvim_win_get_height(win)
			local window_width = vim.api.nvim_win_get_width(win)
			image:draw(x, y, window_width - 6, window_height - 1)
			vim.b.img = image
		end,
	})
	vim.api.nvim_create_autocmd("BufLeave", {
		pattern = "*",
		callback = function()
			local image = vim.b.img
			if image then
				setmetatable(image, Image)
			end
			if image and image.unload then
				image:unload()
			end
		end,
	})
end

return M
