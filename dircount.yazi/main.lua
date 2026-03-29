--- dircount.yazi - Unified linemode: file size for files, file count for dirs
--- Fetcher pre-counts directory children asynchronously

local update = ya.sync(function(st, counts)
	for path, count in pairs(counts) do
		st.counts[path] = count
	end
	ui.render()
end)

local function readable_size(bytes)
	if not bytes or bytes < 0 then return "" end
	if bytes < 1024 then return string.format("%dB", bytes) end
	local units = { "K", "M", "G", "T" }
	local i = 1
	bytes = bytes / 1024
	while bytes >= 1024 and i < #units do
		bytes = bytes / 1024
		i = i + 1
	end
	return string.format("%.1f%s", bytes, units[i])
end

local function setup(st)
	st.counts = {}

	Linemode:children_add(function(self)
		if self._file.cha.is_dir then
			-- Directory: show file count
			local path = tostring(self._file.url)
			local count = st.counts[path]
			if count then
				return ui.Span(string.format(" %d", count)):fg("#bd93f9")
			end
			return ui.Line {}
		else
			-- File: show size
			local size = self._file:size()
			if size then
				return ui.Span(" " .. readable_size(size)):fg("#f8f8f2")
			end
			return ui.Line {}
		end
	end, 400)
end

local function fetch(_, job)
	local counts = {}
	for _, file in ipairs(job.files) do
		if file.cha.is_dir then
			local path = tostring(file.url)
			local output = Command("ls"):arg("-1"):arg(path):stdout(Command.PIPED):stderr(Command.PIPED):output()
			if output and output.status.success then
				local n = 0
				for _ in output.stdout:gmatch("[^\n]+") do
					n = n + 1
				end
				counts[path] = n
			end
		end
	end
	update(counts)
	return true
end

return { setup = setup, fetch = fetch }
