--- statusinfo.yazi - Git status + commit info + disk free space for status bar
--- Style: Starship icons + Ranger layout + Dracula colors

local save = ya.sync(function(st, cwd, data)
	if tostring(cx.active.current.cwd) == cwd then
		st.branch = data.branch
		st.commit_msg = data.commit_msg
		st.commit_date = data.commit_date
		st.staged = data.staged
		st.modified = data.modified
		st.untracked = data.untracked
		st.conflicted = data.conflicted
		st.disk_free = data.disk_free
		ui.render()
	end
end)

return {
	setup = function(st)
		st.branch = nil
		st.commit_msg = nil
		st.commit_date = nil
		st.staged = 0
		st.modified = 0
		st.untracked = 0
		st.conflicted = 0
		st.disk_free = nil

		-- Git info (status bar left, AFTER file mtime)
		-- Format: (git: master) ✓ 2026-02-13 01:39 fix: commit message
		-- Or:     (git: master) +2 !3 ?1 2026-02-13 01:39 fix: commit message
		Status:children_add(function()
			if not st.branch then
				return ui.Line {}
			end

			local parts = {}

			-- Branch: (git: master) in cyan
			table.insert(parts, ui.Span(" (git: " .. st.branch .. ")"):fg("#8be9fd"))

			-- VCS status (Starship style with Dracula colors)
			local is_clean = (st.staged == 0 and st.modified == 0
				and st.untracked == 0 and st.conflicted == 0)

			if is_clean then
				-- Clean: green checkmark
				table.insert(parts, ui.Span(" ✓"):fg("#50fa7b"))
			else
				-- Dirty: show counts with standard icons
				if st.staged > 0 then
					table.insert(parts, ui.Span(" +" .. st.staged):fg("#50fa7b"))
				end
				if st.modified > 0 then
					table.insert(parts, ui.Span(" !" .. st.modified):fg("#f1fa8c"))
				end
				if st.untracked > 0 then
					table.insert(parts, ui.Span(" ?" .. st.untracked):fg("#ff5555"))
				end
				if st.conflicted > 0 then
					table.insert(parts, ui.Span(" =" .. st.conflicted):fg("#ff5555"))
				end
			end

			-- Commit date (white)
			if st.commit_date and st.commit_date ~= "" then
				table.insert(parts, ui.Span(" " .. st.commit_date):fg("#f8f8f2"))
			end

			-- Commit message (comment gray)
			if st.commit_msg and st.commit_msg ~= "" then
				local msg = st.commit_msg
				if #msg > 55 then
					msg = msg:sub(1, 52) .. "..."
				end
				table.insert(parts, ui.Span(" " .. msg):fg("#bd93f9"))
			end

			return ui.Line(parts)
		end, 3600, Status.LEFT)

		-- Disk free space (status bar right, AFTER sum)
		Status:children_add(function()
			if not st.disk_free or st.disk_free == "" then
				return ui.Line {}
			end
			return ui.Span(" " .. st.disk_free .. " free "):fg("#8be9fd")
		end, 510, Status.RIGHT)

		-- Refresh on directory/tab changes
		local function refresh()
			local cwd = tostring(cx.active.current.cwd)
			ya.emit("plugin", { st._id, ya.quote(cwd, true) })
		end

		ps.sub("cd", refresh)
		ps.sub("tab", refresh)
	end,

	entry = function(_, job)
		local args = job.args or job
		local cwd = args[1]
		local data = {}

		-- Git branch name
		local branch_out = Command("git")
			:arg({ "branch", "--show-current" })
			:cwd(cwd)
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()

		if branch_out and branch_out.status and branch_out.status.success then
			local branch = branch_out.stdout:gsub("[\r\n]+$", "")
			if branch ~= "" then
				data.branch = branch
			end
		end

		-- Git commit subject + date (single command)
		local git_out = Command("git")
			:arg({ "log", "-1", "--format=%s%n%ci" })
			:cwd(cwd)
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()

		if git_out and git_out.status and git_out.status.success then
			local lines = {}
			for line in git_out.stdout:gmatch("[^\n]+") do
				lines[#lines + 1] = line
			end
			data.commit_msg = lines[1] or ""
			if lines[2] then
				data.commit_date = lines[2]:match("^(%d+-%d+-%d+ %d+:%d+)")
			end
		end

		-- Parse git status --porcelain for detailed counts
		local status_out = Command("git")
			:arg({ "status", "--porcelain" })
			:cwd(cwd)
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()

		if status_out and status_out.status and status_out.status.success then
			local staged, modified, untracked, conflicted = 0, 0, 0, 0
			for line in status_out.stdout:gmatch("[^\n]+") do
				local x = line:sub(1, 1) -- index (staged) status
				local y = line:sub(2, 2) -- worktree status

				-- Conflicts: UU, AA, DD, etc.
				if x == "U" or y == "U" or (x == "A" and y == "A") or (x == "D" and y == "D") then
					conflicted = conflicted + 1
				else
					-- Staged: any non-space, non-? in first column
					if x ~= " " and x ~= "?" then
						staged = staged + 1
					end
					-- Modified: any non-space in second column
					if y ~= " " and y ~= "?" then
						modified = modified + 1
					end
					-- Untracked: ??
					if x == "?" and y == "?" then
						untracked = untracked + 1
					end
				end
			end
			data.staged = staged
			data.modified = modified
			data.untracked = untracked
			data.conflicted = conflicted
		end

		-- Disk free space via df
		local df_out = Command("df")
			:arg({ "-h", cwd })
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()

		if df_out and df_out.status and df_out.status.success then
			for line in df_out.stdout:gmatch("[^\n]+") do
				if not line:match("^Filesystem") then
					local fields = {}
					for field in line:gmatch("%S+") do
						fields[#fields + 1] = field
					end
					if #fields >= 4 then
						data.disk_free = fields[4]:gsub("i$", "")
					end
					break
				end
			end
		end

		save(cwd, data)
	end,
}
