--- *mini.statusline* Statusline
---
--- MIT License Copyright (c) 2021 Evgeni Chasnovski

--- Features:
--- - Define own custom statusline structure for active and inactive windows.
---   This is done with a function which should return string appropriate for
---   |'statusline'|. Its code should be similar to default one with structure:
---     - Compute string data for every section you want to be displayed.
---     - Combine them in groups with |MiniStatusline.combine_groups()|.
---
--- - Built-in active mode indicator with colors.
---
--- - Sections can hide information when window is too narrow (specific window
---   width is configurable per section).
---
--- # Dependencies ~
---
--- Suggested dependencies (provide extra functionality, will work without them):
---
--- - Nerd font (to support extra icons).
---
--- - Enabled |mini.icons| module for |MiniStatusline.section_fileinfo()|.
---   Falls back to using 'nvim-tree/nvim-web-devicons' plugin or shows nothing.
---
--- - Enabled |mini.git| module for |MiniStatusline.section_git()|.
---   Falls back to using 'lewis6991/gitsigns.nvim' plugin or shows nothing.
---
--- - Enabled |mini.diff| module for |MiniStatusline.section_diff()|.
---   Falls back to using 'lewis6991/gitsigns.nvim' plugin or shows nothing.
---
--- # Setup ~
---
--- This module needs a setup with `require('mini.statusline').setup({})`
--- (replace `{}` with your `config` table). It will create global Lua table
--- `MiniStatusline` which you can use for scripting or manually (with
--- `:lua MiniStatusline.*`).
---
--- See |MiniStatusline.config| for `config` structure and default values. For
--- some content examples, see |MiniStatusline-example-content|.
---
--- You can override runtime config settings locally to buffer inside
--- `vim.b.ministatusline_config` which should have same structure as
--- `MiniStatusline.config`. See |mini.nvim-buffer-local-config| for more details.
---
--- # Highlight groups ~
---
--- Highlight depending on mode (second |MiniStatusline.section_mode()| output):
--- - `MiniStatuslineModeNormal` - Normal mode.
--- - `MiniStatuslineModeInsert` - Insert mode.
--- - `MiniStatuslineModeVisual` - Visual mode.
--- - `MiniStatuslineModeReplace` - Replace mode.
--- - `MiniStatuslineModeCommand` - Command mode.
--- - `MiniStatuslineModeOther` - other modes (like Terminal, etc.).
---
--- Highlight used in default statusline:
--- - `MiniStatuslineDevinfo` - for default |MiniStatusline.section_lsp()|
---   output.
--- - `MiniStatuslineDiff` - for default |MiniStatusline.section_diff()|
---   output.
--- - `MiniStatuslineDiagnostics` - for default
---   |MiniStatusline.section_diagnostics()| output.
--- - `MiniStatuslineFilename` - for default |MiniStatusline.section_git()|
---   output.
--- - `MiniStatuslineFileinfo` - for default
---   |MiniStatusline.section_fileinfo()| and
---   |MiniStatusline.section_filename()| output.
--- - `MiniStatuslineLspProgress` - for active LSP progress inside
---   |MiniStatusline.section_lsp()|.
--- - `MiniStatuslineLspProgressDone` - for recently completed LSP progress
---   inside |MiniStatusline.section_lsp()|.
--- - `MiniStatuslineDiffAdded` - for added diff count inside
---   |MiniStatusline.section_diff()|.
--- - `MiniStatuslineDiffModified` - for modified diff count inside
---   |MiniStatusline.section_diff()|.
--- - `MiniStatuslineDiffRemoved` - for removed diff count inside
---   |MiniStatusline.section_diff()|.
--- - `MiniStatuslineDiagnosticError` - for error diagnostics inside
---   |MiniStatusline.section_diagnostics()|.
--- - `MiniStatuslineDiagnosticWarn` - for warning diagnostics inside
---   |MiniStatusline.section_diagnostics()|.
--- - `MiniStatuslineDiagnosticInfo` - for info diagnostics inside
---   |MiniStatusline.section_diagnostics()|.
--- - `MiniStatuslineDiagnosticHint` - for hint diagnostics inside
---   |MiniStatusline.section_diagnostics()|.
---
--- Other groups:
--- - `MiniStatuslineInactive` - highlighting in not focused window.
---
--- To change any highlight group, set it directly with |nvim_set_hl()|.
---
--- # Disabling ~
---
--- To disable (show empty statusline), set `vim.g.ministatusline_disable`
--- (globally) or `vim.b.ministatusline_disable` (for a buffer) to `true`.
--- Considering high number of different scenarios and customization
--- intentions, writing exact rules for disabling module's functionality is
--- left to user. See |mini.nvim-disabling-recipes| for common recipes.
---@tag MiniStatusline

--- Example content
---
--- # Default content ~
---
--- This function is used as default value for active content: >lua
---
---   function()
---     local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
---     local git           = MiniStatusline.section_git({ trunc_width = 40 })
---     local diff          = MiniStatusline.section_diff({ trunc_width = 40 })
---     local diagnostics   = MiniStatusline.section_diagnostics({ trunc_width = 40 })
---     local lsp           = MiniStatusline.section_lsp({ trunc_width = 75 })
---     local filename      = MiniStatusline.section_filename({ trunc_width = 120 })
---     local fileinfo      = MiniStatusline.section_fileinfo({ trunc_width = 120 })
---     local location      = MiniStatusline.section_location({ trunc_width = 75 })
---     local search        = MiniStatusline.section_searchcount({ trunc_width = 75 })
---
---     return MiniStatusline.combine_groups({
---       { hl = mode_hl,                     strings = { mode } },
---       { hl = 'MiniStatuslineFilename',    strings = { git } },
---       { hl = 'MiniStatuslineDiff',        strings = { diff } },
---       '%<', -- Mark general truncate point
---       { hl = 'MiniStatuslineDevinfo',     strings = { lsp } },
---       { hl = 'MiniStatuslineDiagnostics', strings = { diagnostics } },
---       '%=', -- End left alignment
---       { hl = 'MiniStatuslineFileinfo',    strings = { fileinfo, filename } },
---       { hl = mode_hl,                     strings = { search, location } },
---     })
---   end
--- <
--- # Show boolean options ~
---
--- To compute section string for boolean option use variation of this code
--- snippet inside content function (you can modify option itself, truncation
--- width, short and long displayed names): >lua
---
---   local spell = vim.wo.spell and (MiniStatusline.is_truncated(120) and 'S' or 'SPELL') or ''
--- <
--- Here `x and y or z` is a common Lua way of doing ternary operator: if `x`
--- is `true`-ish then return `y`, if not - return `z`.
---@tag MiniStatusline-example-content

---@alias __statusline_args table Section arguments.
---@alias __statusline_section string Section string.

-- Module definition ==========================================================
local MiniStatusline = {}
local H = {}

--- Module setup
---
---@param config table|nil Module config table. See |MiniStatusline.config|.
---
---@usage >lua
---   require('mini.statusline').setup() -- use default config
---   -- OR
---   require('mini.statusline').setup({}) -- replace {} with your config table
--- <
MiniStatusline.setup = function(config)
	-- TODO: Remove after Neovim=0.9 support is dropped
	if vim.fn.has("nvim-0.10") == 0 then
		vim.notify(
			"(mini.statusline) Neovim<0.10 is soft deprecated (module works but is not supported)."
				.. " It will be deprecated after the next 'mini.nvim' release (module might not work)."
				.. " Please update your Neovim version."
		)
	end

	-- Export module
	_G.MiniStatusline = MiniStatusline

	-- Setup config
	config = H.setup_config(config)

	-- Apply config
	H.apply_config(config)

	-- Define behavior
	H.create_autocommands()

	-- - Disable built-in statusline in Quickfix window
	vim.g.qf_disable_statusline = 1

	-- Create default highlighting
	H.create_default_hl()
end

--- Defaults ~
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
MiniStatusline.config = {
	-- Content of statusline as functions which return statusline string. See
	-- `:h statusline` and code of default contents (used instead of `nil`).
	content = {
		-- Content for active window
		active = nil,
		-- Content for inactive window(s)
		inactive = nil,
	},

	-- Whether to use icons by default
	use_icons = true,

	-- Git section defaults
	git = {
		-- Icon used before Git summary.
		icon = "",
	},

	-- Diff section defaults
	diff = {
		-- Icon used before diff summary. If `nil`, no icon is shown.
		icon = nil,
		-- Signs shown for each diff type
		signs = {
			added = "+",
			modified = "~",
			removed = "-",
		},
	},

	-- Diagnostics section defaults
	diagnostics = {
		-- Icon used before diagnostics summary. If `nil`, no icon is shown.
		icon = nil,
		-- Signs shown for each severity level
		signs = {
			ERROR = "E",
			WARN = "W",
			INFO = "I",
			HINT = "H",
		},
	},

	-- Highlight groups used by default content and built-in sections
	highlight_groups = {
		devinfo = "MiniStatuslineDevinfo",
		filename = "MiniStatuslineFilename",
		fileinfo = "MiniStatuslineFileinfo",
		inactive = "MiniStatuslineInactive",
		lsp_progress = "MiniStatuslineLspProgress",
		lsp_progress_done = "MiniStatuslineLspProgressDone",
		diff = {
			group = "MiniStatuslineDiff",
			added = "MiniStatuslineDiffAdded",
			modified = "MiniStatuslineDiffModified",
			removed = "MiniStatuslineDiffRemoved",
		},
		diagnostics = {
			group = "MiniStatuslineDiagnostics",
			ERROR = "MiniStatuslineDiagnosticError",
			WARN = "MiniStatuslineDiagnosticWarn",
			INFO = "MiniStatuslineDiagnosticInfo",
			HINT = "MiniStatuslineDiagnosticHint",
		},
	},

	-- Whether to show diagnostics from all buffers instead of current buffer
	show_workspace_diagnostics = false,
}
--minidoc_afterlines_end

-- Module functionality =======================================================
--- Compute content for active window
MiniStatusline.active = function()
	if H.is_disabled() then
		return ""
	end
	return (H.get_config().content.active or H.default_content_active)()
end

--- Compute content for inactive window
MiniStatusline.inactive = function()
	if H.is_disabled() then
		return ""
	end
	return (H.get_config().content.inactive or H.default_content_inactive)()
end

--- Combine groups of sections
---
--- Each group can be either a string or a table with fields `hl` (group's
--- highlight group) and `strings` (strings representing sections).
---
--- General idea of this function is as follows;
--- - String group is used as is (useful for special strings like `%<` or `%=`).
--- - Each table group has own highlighting in `hl` field (if missing, the
---   previous one is used) and string parts in `strings` field. Non-empty
---   strings from `strings` are separated by one space. Non-empty groups are
---   separated by two spaces (one for each highlighting).
---
---@param groups table Array of groups.
---
---@return string String suitable for 'statusline'.
MiniStatusline.combine_groups = function(groups)
	local parts = vim.tbl_map(function(s)
		if type(s) == "string" then
			return s
		end
		if type(s) ~= "table" then
			return ""
		end

		local string_arr = vim.tbl_filter(function(x)
			return type(x) == "string" and x ~= ""
		end, s.strings or {})
		local str = table.concat(string_arr, " ")

		-- Use previous highlight group
		if s.hl == nil then
			return " " .. str .. " "
		end

		-- Allow using this highlight group later
		if str:len() == 0 then
			return "%#" .. s.hl .. "#"
		end

		return string.format("%%#%s# %s ", s.hl, str)
	end, groups)

	return table.concat(parts, "")
end

--- Decide whether to truncate
---
--- This basically computes window width and compares it to `trunc_width`: if
--- window is smaller then truncate; otherwise don't. Don't truncate by
--- default.
---
--- Use this to manually decide if section needs truncation or not.
---
---@param trunc_width number|nil Truncation width. If `nil`, output is `false`.
---
---@return boolean Whether to truncate.
MiniStatusline.is_truncated = function(trunc_width)
	-- Use -1 to default to 'not truncated'
	local cur_width = vim.o.laststatus == 3 and vim.o.columns or vim.api.nvim_win_get_width(0)
	return cur_width < (trunc_width or -1)
end

-- Sections ===================================================================
-- Functions should return output text without whitespace on sides.
-- Return empty string to omit section.

--- Section for Vim |mode()|
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args __statusline_args
---
---@return ... Section string and mode's highlight group.
MiniStatusline.section_mode = function(args)
	local mode_info = H.modes[vim.fn.mode()]

	local mode = MiniStatusline.is_truncated(args.trunc_width) and mode_info.short or mode_info.long

	return mode, mode_info.hl
end

--- Section for Git information
---
--- Shows Git summary from |mini.git| (should be set up; recommended). To tweak
--- formatting of what data is shown, modify buffer-local summary string directly
--- as described in |MiniGit-examples|.
---
--- If 'mini.git' is not set up, section falls back on 'lewis6991/gitsigns' data
--- or showing empty string.
---
--- Empty string is returned if window width is lower than `args.trunc_width`.
---
---@param args __statusline_args Use `args.icon` to supply your own icon.
---@return __statusline_section
MiniStatusline.section_git = function(args)
	args = args or {}
	if MiniStatusline.is_truncated(args.trunc_width) then
		return ""
	end

	local summary = vim.b.minigit_summary_string or vim.b.gitsigns_head
	if summary == nil then
		return ""
	end

	local icon = args.icon or H.get_config().git.icon
	return H.with_prefix(icon, summary == "" and "-" or summary)
end

--- Section for diff information
---
--- Shows diff summary from |mini.diff| (should be set up; recommended). To tweak
--- formatting of what data is shown, modify buffer-local summary string directly
--- as described in |MiniDiff-diff-summary|.
---
--- If 'mini.diff' is not set up, section falls back on 'lewis6991/gitsigns' data
--- or showing empty string.
---
--- Empty string is returned if window width is lower than `args.trunc_width`.
---
---@param args __statusline_args Use `args.icon` to supply your own icon.
---   Use `args.signs` to use custom signs per diff type. Supported keys are
---   `added`, `modified`, and `removed`. For example: >lua
---
---   { added = '', modified = '', removed = '' }
--- <
---   Use `args.highlights` to use custom highlight groups per diff type. For
---   example: >lua
---
---   { added = 'DiffAdd', modified = 'DiffChange', removed = 'DiffDelete' }
--- <
---   Use `args.reset_highlight` to restore statusline highlighting after each
---   highlighted diff entry.
---@return __statusline_section
MiniStatusline.section_diff = function(args)
	args = args or {}
	if MiniStatusline.is_truncated(args.trunc_width) then
		return ""
	end

	local summary = vim.b.minidiff_summary_string or vim.b.gitsigns_status
	if summary == nil then
		return ""
	end

	local config = H.get_config()
	local signs = vim.tbl_deep_extend("force", vim.deepcopy(config.diff.signs), args.signs or {})
	local highlights = vim.tbl_deep_extend("force", vim.deepcopy(config.highlight_groups.diff), args.highlights or {})
	local reset_highlight = args.reset_highlight or config.highlight_groups.diff.group
	local icon = args.icon or config.diff.icon
	return H.with_prefix(icon, H.format_diff_summary(summary, signs, highlights, reset_highlight))
end

--- Section for Neovim's builtin diagnostics
---
--- Shows nothing if diagnostics is disabled, no diagnostic is set, or for short
--- output. Otherwise uses |vim.diagnostic.get()| to compute and show number of
--- errors ('E'), warnings ('W'), information ('I'), and hints ('H'). When
--- `config.show_workspace_diagnostics` is `true`, count diagnostics from all
--- buffers instead of only current buffer.
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args __statusline_args Use `args.icon` to supply your own icon.
---   Use `args.signs` to use custom signs per severity level name. For example: >lua
---
---   { ERROR = '!', WARN = '?', INFO = '@', HINT = '*' }
--- <
---   Use `args.highlights` to use custom highlight groups per severity level
---   name. For example: >lua
---
---   { ERROR = 'ErrorMsg', WARN = 'WarningMsg' }
--- <
---   Use `args.reset_highlight` to restore statusline highlighting after each
---   highlighted diagnostic entry.
---@return __statusline_section
MiniStatusline.section_diagnostics = function(args)
	args = args or {}
	if MiniStatusline.is_truncated(args.trunc_width) then
		return ""
	end

	local config = H.get_config()
	local signs = vim.tbl_deep_extend("force", vim.deepcopy(config.diagnostics.signs), args.signs or {})
	local highlights =
		vim.tbl_deep_extend("force", vim.deepcopy(config.highlight_groups.diagnostics), args.highlights or {})
	local reset_highlight = args.reset_highlight or config.highlight_groups.diagnostics.group

	-- Construct string parts. NOTE: call `diagnostic_is_disabled()` *after*
	-- check for present `count` to not source `vim.diagnostic` on startup.
	local count = config.show_workspace_diagnostics and H.get_workspace_diagnostic_count()
		or H.diagnostic_counts[vim.api.nvim_get_current_buf()]
	if count == nil or H.diagnostic_is_disabled() then
		return ""
	end

	local severity, t = vim.diagnostic.severity, {}
	for _, level in ipairs(H.diagnostic_levels) do
		local n = count[severity[level.name]] or 0
		-- Add level info only if diagnostic is present
		if n > 0 then
			local sign = signs[level.name]
			local hl = highlights[level.name]
			if type(hl) == "string" and hl ~= "" then
				table.insert(t, string.format("%%#%s#%s%d%%#%s#", hl, sign, n, reset_highlight))
			else
				table.insert(t, sign .. n)
			end
		end
	end
	if #t == 0 then
		return ""
	end

	local icon = args.icon or config.diagnostics.icon
	return H.with_prefix(icon, table.concat(t, ""))
end

--- Section for attached LSP servers
---
--- Shows names of LSP servers attached to current buffer, separated by commas.
--- If there is ongoing LSP work progress from a client attached to current
--- buffer, append its compact status with dedicated highlighting.
--- Nothing is shown if window width is lower than `args.trunc_width`.
---
---@param args __statusline_args Use `args.icon` to supply your own icon.
---
---@return __statusline_section
MiniStatusline.section_lsp = function(args)
	if MiniStatusline.is_truncated(args.trunc_width) then
		return ""
	end

	local buf_id = vim.api.nvim_get_current_buf()
	local attached = H.attached_lsp[buf_id] or ""
	local progress, progress_hl, progress_client, progress_kind = H.get_lsp_progress(buf_id)
	if attached == "" and progress == "" then
		return ""
	end

	local use_icons = H.use_icons or H.get_config().use_icons
	local icon = args.icon or (use_icons and "󰰎" or "LSP")
	local progress_part = ""
	if progress ~= "" then
		local hl_groups = H.get_config().highlight_groups
		progress_part =
			string.format(" %%#%s#%s%%#%s#", progress_hl or hl_groups.lsp_progress, progress, hl_groups.devinfo)
	end

	local name = attached
	if progress ~= "" and progress_kind ~= "end" and type(progress_client) == "string" and progress_client ~= "" then
		name = progress_client
	end

	if name == "" then
		return icon .. progress_part
	end

	return string.format("%s %s%s", icon, name, progress_part)
end

--- Section for file name
---
--- Show full file name or shortened relative path in short output.
--- Long paths are shortened in the middle to leave room for other sections.
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args __statusline_args
---
---@return __statusline_section
MiniStatusline.section_filename = function(args)
	args = args or {}
	-- In terminal always use plain name
	if vim.bo.buftype == "terminal" then
		return "%t"
	end

	local bufname = vim.api.nvim_buf_get_name(0)
	local relpath = bufname == "" and "[No Name]" or vim.fn.fnamemodify(bufname, ":.")
	local fullpath = bufname == "" and "[No Name]" or bufname
	local is_truncated = MiniStatusline.is_truncated(args.trunc_width)
	local compact_path = is_truncated and vim.fn.pathshorten(relpath) or relpath
	local path = is_truncated and compact_path or fullpath
	local max_width = is_truncated and H.filename_max_width.truncated or H.filename_max_width.default

	if vim.fn.strdisplaywidth(path) > max_width then
		-- Prefer compact relative path when shortening so more of the useful
		-- directory and file name stays visible.
		path = H.shorten_middle(compact_path, max_width)
	end

	return path:gsub("%%", "%%%%") .. "%m%r"
end

--- Section for file information
---
--- Shows 'filetype', 'fileencoding' / 'encoding', 'fileformat', and buffer size.
--- Short output has only non-empty 'filetype' and is returned if window width is
--- lower than `args.trunc_width` or buffer is not normal (as per 'buftype').
---
--- Buffer size is computed based on current text, not file's saved version.
---
--- If `config.use_icons` is true and icon provider is present (see
--- "Dependencies" section in |mini.statusline|), shows icon near the filetype.
---
---@param args __statusline_args
---
---@return __statusline_section
MiniStatusline.section_fileinfo = function(args)
	local filetype = vim.bo.filetype

	-- Add filetype icon
	H.ensure_get_icon()
	if H.get_icon ~= nil and filetype ~= "" then
		filetype = H.get_icon(filetype) .. " " .. filetype
	end

	-- Construct output string if truncated or buffer is not normal
	if MiniStatusline.is_truncated(args.trunc_width) or vim.bo.buftype ~= "" then
		return filetype
	end

	-- Construct output string with extra file info
	local encoding = vim.bo.fileencoding or vim.bo.encoding
	local format = vim.bo.fileformat
	local size = H.get_filesize()

	return string.format("%s%s%s[%s] %s", filetype, filetype == "" and "" or " ", encoding, format, size)
end

--- Section for location inside buffer
---
--- Show location inside buffer in the form:
--- - Normal: `'<cursor line>|<total lines>│<cursor column>|<total columns>'`
--- - Short: `'<cursor line>│<cursor column>'`
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args __statusline_args
---
---@return __statusline_section
MiniStatusline.section_location = function(args)
	-- Use virtual column number to allow update when past last column
	if MiniStatusline.is_truncated(args.trunc_width) then
		return "%l│%2v"
	end

	-- Use `virtcol()` to correctly handle multi-byte characters
	return '%l|%L│%2v|%-2{virtcol("$") - 1}'
end

--- Section for current search count
---
--- Show the current status of |searchcount()|. Empty output is returned if
--- window width is lower than `args.trunc_width`, search highlighting is not
--- on (see |v:hlsearch|), or if number of search result is 0.
---
--- `args.options` is forwarded to |searchcount()|. By default it recomputes
--- data on every call which can be computationally expensive (although still
--- usually on 0.1 ms order of magnitude). To prevent this, supply
--- `args.options = { recompute = false }`.
---
---@param args __statusline_args
---
---@return __statusline_section
MiniStatusline.section_searchcount = function(args)
	if vim.v.hlsearch == 0 or MiniStatusline.is_truncated(args.trunc_width) then
		return ""
	end
	-- `searchcount()` can return errors because it is evaluated very often in
	-- statusline. For example, when typing `/` followed by `\(`, it gives E54.
	local ok, s_count = pcall(vim.fn.searchcount, (args or {}).options or { recompute = true })
	if not ok or s_count.current == nil or s_count.total == 0 then
		return ""
	end

	if s_count.incomplete == 1 then
		return "?/?"
	end

	local too_many = ">" .. s_count.maxcount
	local current = s_count.current > s_count.maxcount and too_many or s_count.current
	local total = s_count.total > s_count.maxcount and too_many or s_count.total
	return current .. "/" .. total
end

-- Helper data ================================================================
-- Module default config
H.default_config = vim.deepcopy(MiniStatusline.config)

-- Showed diagnostic levels
H.diagnostic_levels = {
	{ name = "ERROR" },
	{ name = "WARN" },
	{ name = "INFO" },
	{ name = "HINT" },
}

-- Diagnostic counts per buffer id
H.diagnostic_counts = {}

-- Keep filename compact enough to leave room for diff and diagnostics sections
-- in common statusline layouts while still showing useful path context.
H.filename_max_width = {
	default = 60,
	truncated = 30,
}

-- String representation of attached LSP clients per buffer id
H.attached_lsp = {}

-- Active LSP progress per client id and progress token
H.lsp_progress = {}

-- Timer used to animate LSP progress spinner
H.lsp_progress_timer = nil

-- Helper functionality =======================================================
-- Settings -------------------------------------------------------------------
H.setup_config = function(config)
	H.check_type("config", config, "table", true)
	config = vim.tbl_deep_extend("force", vim.deepcopy(H.default_config), config or {})

	H.check_type("content", config.content, "table")
	H.check_type("content.active", config.content.active, "function", true)
	H.check_type("content.inactive", config.content.inactive, "function", true)

	H.check_type("use_icons", config.use_icons, "boolean")
	H.check_type("git", config.git, "table")
	H.check_type("git.icon", config.git.icon, "string", true)
	H.check_type("diff", config.diff, "table")
	H.check_type("diff.icon", config.diff.icon, "string", true)
	H.check_type("diff.signs", config.diff.signs, "table")
	H.check_diff_map("diff.signs", config.diff.signs)
	H.check_type("diagnostics", config.diagnostics, "table")
	H.check_type("diagnostics.icon", config.diagnostics.icon, "string", true)
	H.check_type("diagnostics.signs", config.diagnostics.signs, "table")
	H.check_severity_map("diagnostics.signs", config.diagnostics.signs)
	H.check_type("highlight_groups", config.highlight_groups, "table")
	H.check_type("highlight_groups.devinfo", config.highlight_groups.devinfo, "string")
	H.check_type("highlight_groups.filename", config.highlight_groups.filename, "string")
	H.check_type("highlight_groups.fileinfo", config.highlight_groups.fileinfo, "string")
	H.check_type("highlight_groups.inactive", config.highlight_groups.inactive, "string")
	H.check_type("highlight_groups.lsp_progress", config.highlight_groups.lsp_progress, "string")
	H.check_type("highlight_groups.lsp_progress_done", config.highlight_groups.lsp_progress_done, "string")
	H.check_type("highlight_groups.diff", config.highlight_groups.diff, "table")
	H.check_type("highlight_groups.diff.group", config.highlight_groups.diff.group, "string")
	H.check_diff_map("highlight_groups.diff", config.highlight_groups.diff)
	H.check_type("highlight_groups.diagnostics", config.highlight_groups.diagnostics, "table")
	H.check_type("highlight_groups.diagnostics.group", config.highlight_groups.diagnostics.group, "string")
	H.check_severity_map("highlight_groups.diagnostics", config.highlight_groups.diagnostics)
	H.check_type("show_workspace_diagnostics", config.show_workspace_diagnostics, "boolean")

	return config
end

H.apply_config = function(config)
	MiniStatusline.config = config

	-- Set statusline globally and dynamically decide which content to use
	vim.go.statusline =
		"%{%(nvim_get_current_win()==#g:actual_curwin || &laststatus==3) ? v:lua.MiniStatusline.active() : v:lua.MiniStatusline.inactive()%}"
end

H.create_autocommands = function()
	local gr = vim.api.nvim_create_augroup("MiniStatusline", {})

	local au = function(event, pattern, callback, desc)
		vim.api.nvim_create_autocmd(event, { group = gr, pattern = pattern, callback = callback, desc = desc })
	end

	-- Use `schedule_wrap()` because at `LspDetach` server is still present
	local track_lsp = vim.schedule_wrap(function(data)
		H.attached_lsp[data.buf] = vim.api.nvim_buf_is_valid(data.buf) and H.compute_attached_lsp(data.buf) or nil
		H.prune_lsp_progress()
		H.refresh_lsp_progress_timer()
		vim.cmd("redrawstatus")
	end)
	au({ "LspAttach", "LspDetach" }, "*", track_lsp, "Track LSP clients")

	if vim.fn.has("nvim-0.10") == 1 then
		local track_lsp_progress = vim.schedule_wrap(function(data)
			H.update_lsp_progress(data.data)
			H.refresh_lsp_progress_timer()
			vim.cmd("redrawstatus")
		end)
		au("LspProgress", "*", track_lsp_progress, "Track LSP progress")
	end

	-- Use `schedule_wrap()` because `redrawstatus` might error on `:bwipeout`
	-- See: https://github.com/neovim/neovim/issues/32349
	local track_diagnostics = vim.schedule_wrap(function(data)
		H.diagnostic_counts[data.buf] = vim.api.nvim_buf_is_valid(data.buf) and H.get_diagnostic_count(data.buf) or nil
		vim.cmd("redrawstatus")
	end)
	au("DiagnosticChanged", "*", track_diagnostics, "Track diagnostics")

	au("ColorScheme", "*", H.create_default_hl, "Ensure colors")
end

--stylua: ignore
H.create_default_hl = function()
  local set_default_hl = function(name, data)
    data.default = true
    vim.api.nvim_set_hl(0, name, data)
  end

  set_default_hl('MiniStatuslineModeNormal',     { link = 'Cursor' })
  set_default_hl('MiniStatuslineModeInsert',     { link = 'DiffChange' })
  set_default_hl('MiniStatuslineModeVisual',     { link = 'DiffAdd' })
  set_default_hl('MiniStatuslineModeReplace',    { link = 'DiffDelete' })
  set_default_hl('MiniStatuslineModeCommand',    { link = 'DiffText' })
  set_default_hl('MiniStatuslineModeOther',      { link = 'IncSearch' })

  set_default_hl('MiniStatuslineDevinfo',          { link = 'StatusLine' })
  set_default_hl('MiniStatuslineDiff',             { link = 'StatusLine' })
  set_default_hl('MiniStatuslineDiagnostics',      { link = 'StatusLine' })
  set_default_hl('MiniStatuslineFilename',         { link = 'StatusLineNC' })
  set_default_hl('MiniStatuslineFileinfo',         { link = 'StatusLine' })
  set_default_hl('MiniStatuslineLspProgress',      { link = 'DiagnosticInfo' })
  set_default_hl('MiniStatuslineLspProgressDone',  { link = 'DiffAdd' })
  set_default_hl('MiniStatuslineDiffAdded',        { link = 'DiffAdd' })
  set_default_hl('MiniStatuslineDiffModified',     { link = 'DiffChange' })
  set_default_hl('MiniStatuslineDiffRemoved',      { link = 'DiffDelete' })
  set_default_hl('MiniStatuslineDiagnosticError',  { link = 'DiagnosticError' })
  set_default_hl('MiniStatuslineDiagnosticWarn',   { link = 'DiagnosticWarn' })
  set_default_hl('MiniStatuslineDiagnosticInfo',   { link = 'DiagnosticInfo' })
  set_default_hl('MiniStatuslineDiagnosticHint',   { link = 'DiagnosticHint' })
  set_default_hl('MiniStatuslineInactive',         { link = 'StatusLineNC' })
end

H.is_disabled = function()
	return vim.g.ministatusline_disable == true or vim.b.ministatusline_disable == true
end

H.get_config = function(config)
	return vim.tbl_deep_extend("force", MiniStatusline.config, vim.b.ministatusline_config or {}, config or {})
end

-- Mode -----------------------------------------------------------------------
-- Custom `^V` and `^S` symbols to make this file appropriate for copy-paste
-- (otherwise those symbols are not displayed).
local CTRL_S = vim.api.nvim_replace_termcodes("<C-S>", true, true, true)
local CTRL_V = vim.api.nvim_replace_termcodes("<C-V>", true, true, true)

-- stylua: ignore start
H.modes = setmetatable({
  ['n']    = { long = 'Normal',   short = 'N',   hl = 'MiniStatuslineModeNormal' },
  ['v']    = { long = 'Visual',   short = 'V',   hl = 'MiniStatuslineModeVisual' },
  ['V']    = { long = 'V-Line',   short = 'V-L', hl = 'MiniStatuslineModeVisual' },
  [CTRL_V] = { long = 'V-Block',  short = 'V-B', hl = 'MiniStatuslineModeVisual' },
  ['s']    = { long = 'Select',   short = 'S',   hl = 'MiniStatuslineModeVisual' },
  ['S']    = { long = 'S-Line',   short = 'S-L', hl = 'MiniStatuslineModeVisual' },
  [CTRL_S] = { long = 'S-Block',  short = 'S-B', hl = 'MiniStatuslineModeVisual' },
  ['i']    = { long = 'Insert',   short = 'I',   hl = 'MiniStatuslineModeInsert' },
  ['R']    = { long = 'Replace',  short = 'R',   hl = 'MiniStatuslineModeReplace' },
  ['c']    = { long = 'Command',  short = 'C',   hl = 'MiniStatuslineModeCommand' },
  ['r']    = { long = 'Prompt',   short = 'P',   hl = 'MiniStatuslineModeOther' },
  ['!']    = { long = 'Shell',    short = 'Sh',  hl = 'MiniStatuslineModeOther' },
  ['t']    = { long = 'Terminal', short = 'T',   hl = 'MiniStatuslineModeOther' },
}, {
  -- By default return 'Unknown' but this shouldn't be needed
  __index = function()
    return   { long = 'Unknown',  short = 'U',   hl = '%#MiniStatuslineModeOther#' }
  end,
})
-- stylua: ignore end

-- Default content ------------------------------------------------------------
--stylua: ignore
H.default_content_active = function()
  local hl_groups = H.get_config().highlight_groups
  H.use_icons = H.get_config().use_icons
  local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
  local git           = MiniStatusline.section_git({ trunc_width = 40 })
  local diff          = MiniStatusline.section_diff({ trunc_width = 40, reset_highlight = hl_groups.diff.group })
  local diagnostics   = MiniStatusline.section_diagnostics({ trunc_width = 40, reset_highlight = hl_groups.diagnostics.group })
  local lsp           = MiniStatusline.section_lsp({ trunc_width = 75 })
  local filename      = MiniStatusline.section_filename({ trunc_width = 120 })
  local fileinfo      = MiniStatusline.section_fileinfo({ trunc_width = 120 })
  local location      = MiniStatusline.section_location({ trunc_width = 75 })
  local search        = MiniStatusline.section_searchcount({ trunc_width = 75 })
  H.use_icons = nil

  -- Usage of `MiniStatusline.combine_groups()` ensures highlighting and
  -- correct padding with spaces between groups (accounts for 'missing'
  -- sections, etc.)
  return MiniStatusline.combine_groups({
        { hl = mode_hl,                      strings = { mode } },
    { hl = hl_groups.filename,             strings = { git } },
    { hl = hl_groups.diff.group,           strings = { diff } },
        '%<', -- Mark general truncate point
    { hl = hl_groups.devinfo,              strings = { lsp } },
    { hl = hl_groups.diagnostics.group,    strings = { diagnostics } },
        '%=', -- End left alignment
    { hl = hl_groups.fileinfo,            strings = { fileinfo, filename } },
    { hl = mode_hl,                       strings = { search, location } },
  })
end

H.default_content_inactive = function()
	return string.format("%%#%s#%%F%%=", H.get_config().highlight_groups.inactive)
end

-- LSP ------------------------------------------------------------------------
H.compute_attached_lsp = function(buf_id)
	local clients = H.get_buf_lsp_clients(buf_id)
	local names = {}

	for _, client in pairs(clients) do
		if type(client) == "table" and type(client.name) == "string" and client.name ~= "" then
			table.insert(names, client.name)
		end
	end

	table.sort(names)
	return table.concat(names, ",")
end

H.get_buf_lsp_clients = function(buf_id)
	return vim.lsp.get_clients({ bufnr = buf_id })
end

H.lsp_progress_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
H.lsp_progress_done_ms = 1000

H.get_lsp_progress_spinner = function()
	local frame = math.floor(vim.loop.hrtime() / 1e8) % #H.lsp_progress_frames + 1
	return H.lsp_progress_frames[frame]
end

H.get_time_ms = function()
	return vim.uv and vim.uv.now() or vim.loop.now()
end

H.shorten_lsp_progress_text = function(text, max_width)
	text = vim.trim((text or ""):gsub("%s+", " "))
	if text == "" then
		return ""
	end

	max_width = max_width or 24
	if vim.fn.strdisplaywidth(text) <= max_width then
		return text
	end

	local width, chars = 0, {}
	for _, ch in ipairs(vim.fn.split(text, "\\zs")) do
		local ch_width = vim.fn.strdisplaywidth(ch)
		if width + ch_width > max_width - 1 then
			break
		end
		table.insert(chars, ch)
		width = width + ch_width
	end

	return table.concat(chars, "") .. "…"
end

H.shorten_middle = function(text, max_width)
	text = text or ""
	max_width = max_width or 0
	if text == "" or max_width <= 0 or vim.fn.strdisplaywidth(text) <= max_width then
		return text
	end
	if max_width == 1 then
		return "…"
	end

	-- Split into individual characters while keeping multi-byte glyphs intact.
	local chars = vim.fn.split(text, "\\zs")
	local left_max = math.floor((max_width - 1) / 2)
	local right_max = max_width - 1 - left_max
	local left, right = {}, {}
	local left_width, right_width = 0, 0

	for _, ch in ipairs(chars) do
		local ch_width = vim.fn.strdisplaywidth(ch)
		if left_width + ch_width > left_max then
			break
		end
		table.insert(left, ch)
		left_width = left_width + ch_width
	end

	for i = #chars, 1, -1 do
		local ch = chars[i]
		local ch_width = vim.fn.strdisplaywidth(ch)
		if right_width + ch_width > right_max then
			break
		end
		table.insert(right, 1, ch)
		right_width = right_width + ch_width
	end

	return table.concat(left, "") .. "…" .. table.concat(right, "")
end

H.format_lsp_progress = function(text, percentage, is_done)
	text = H.shorten_lsp_progress_text(text)
	if is_done then
		if text ~= "" then
			return " " .. text
		end
		return type(percentage) == "number" and string.format(" %d%%%%", percentage) or " Done"
	end

	local spinner = H.get_lsp_progress_spinner()
	if type(percentage) == "number" then
		return string.format("%s %d%%%%", spinner, percentage)
	end
	if text == "" then
		return spinner
	end

	return string.format("%s %s", spinner, text)
end

H.prune_lsp_progress = function()
	local now = H.get_time_ms()

	for client_id, tokens in pairs(H.lsp_progress) do
		for token, entry in pairs(tokens) do
			if
				entry.kind == "end"
				and type(entry.done_at) == "number"
				and now - entry.done_at > H.lsp_progress_done_ms
			then
				tokens[token] = nil
			end
		end

		if vim.tbl_isempty(tokens) then
			H.lsp_progress[client_id] = nil
		end
	end
end

H.has_active_lsp_progress = function()
	H.prune_lsp_progress()

	for _, tokens in pairs(H.lsp_progress) do
		for _, entry in pairs(tokens) do
			if entry.kind ~= "end" then
				return true
			end
		end
	end

	return false
end

H.refresh_lsp_progress_timer = function()
	if vim.fn.has("nvim-0.10") == 0 then
		return
	end

	local uv = vim.uv or vim.loop
	if H.has_active_lsp_progress() then
		if H.lsp_progress_timer == nil then
			H.lsp_progress_timer = uv.new_timer()
		end
		if not H.lsp_progress_timer:is_active() then
			H.lsp_progress_timer:start(
				0,
				80,
				vim.schedule_wrap(function()
					H.prune_lsp_progress()
					if not H.has_active_lsp_progress() then
						H.refresh_lsp_progress_timer()
						vim.cmd("redrawstatus")
						return
					end
					vim.cmd("redrawstatus")
				end)
			)
		end
		return
	end

	if H.lsp_progress_timer ~= nil and H.lsp_progress_timer:is_active() then
		H.lsp_progress_timer:stop()
	end
end

H.update_lsp_progress = function(data)
	if type(data) ~= "table" or type(data.client_id) ~= "number" then
		return
	end

	local params = type(data.params) == "table" and data.params or {}
	local value = type(params.value) == "table" and params.value or {}
	local token = params.token
	if token == nil then
		return
	end

	local client_tokens = H.lsp_progress[data.client_id] or {}
	local entry = client_tokens[token] or {}
	entry.kind = value.kind
	entry.title = type(value.title) == "string" and value.title or entry.title or ""
	entry.message = type(value.message) == "string" and value.message or entry.message or ""
	entry.percentage = type(value.percentage) == "number" and math.floor(value.percentage + 0.5) or entry.percentage
	entry.updated_at = H.get_time_ms()

	if entry.kind == "end" then
		entry.done_at = entry.updated_at
		entry.percentage = entry.percentage or 100
	else
		entry.done_at = nil
	end

	client_tokens[token] = entry
	H.lsp_progress[data.client_id] = client_tokens
	H.prune_lsp_progress()
end

H.choose_lsp_progress_entry = function(buf_id)
	H.prune_lsp_progress()

	local best_active, best_done
	for _, client in pairs(H.get_buf_lsp_clients(buf_id)) do
		local tokens = H.lsp_progress[client.id] or {}
		for _, entry in pairs(tokens) do
			local candidate = { client_name = client.name or "", entry = entry }
			if entry.kind == "end" then
				if best_done == nil or (entry.done_at or 0) > (best_done.entry.done_at or 0) then
					best_done = candidate
				end
			else
				if best_active == nil or (entry.updated_at or 0) > (best_active.entry.updated_at or 0) then
					best_active = candidate
				end
			end
		end
	end

	return best_active or best_done
end

H.get_lsp_progress_text = function(entry, client_name)
	local parts = vim.tbl_filter(function(x)
		return type(x) == "string" and x ~= ""
	end, { entry.title, entry.message })
	if not vim.tbl_isempty(parts) then
		return table.concat(parts, ": ")
	end

	return client_name or ""
end

H.get_lsp_progress = function(buf_id)
	local candidate = H.choose_lsp_progress_entry(buf_id)
	if candidate == nil then
		return "", nil, nil, nil
	end

	local entry = candidate.entry
	local text = H.get_lsp_progress_text(entry, candidate.client_name)
	local hl_groups = H.get_config().highlight_groups
	local hl = entry.kind == "end" and hl_groups.lsp_progress_done or hl_groups.lsp_progress
	return H.format_lsp_progress(text, entry.percentage, entry.kind == "end"), hl, candidate.client_name, entry.kind
end

-- NOTE: Use `has('nvim-0.xx')` instead of directly checking presence of target
-- function to avoid loading `vim.xxx` modules at `require('mini.statusline')`.
-- This visibly improves startup time.
if vim.fn.has("nvim-0.10") == 0 then
	H.get_buf_lsp_clients = function(buf_id)
		return vim.lsp.buf_get_clients(buf_id)
	end

	H.get_lsp_progress = function(buf_id)
		local ok, messages = pcall(vim.lsp.util.get_progress_messages)
		if not ok or type(messages) ~= "table" or vim.tbl_isempty(messages) then
			return "", nil, nil, nil
		end

		local attached_names = {}
		for _, client in pairs(H.get_buf_lsp_clients(buf_id)) do
			if type(client.name) == "string" and client.name ~= "" then
				attached_names[client.name] = true
			end
		end

		local percentage, text, client_name
		for _, msg in ipairs(messages) do
			if attached_names[msg.name or ""] then
				client_name = msg.name or client_name
				if type(msg.percentage) == "number" then
					percentage = math.max(percentage or 0, msg.percentage)
				end

				if text == nil or text == "" then
					text = msg.title or msg.message or msg.name or ""
				end
			end
		end

		if percentage == nil and (text == nil or text == "") then
			return "", nil, nil, nil
		end

		return H.format_lsp_progress(text, percentage, false),
			H.get_config().highlight_groups.lsp_progress,
			client_name,
			"report"
	end
end

-- Diagnostics ----------------------------------------------------------------
H.get_diagnostic_count = function(buf_id)
	return vim.diagnostic.count(buf_id)
end

H.get_workspace_diagnostic_count = function()
	return vim.diagnostic.count(nil)
end
if vim.fn.has("nvim-0.10") == 0 then
	H.get_diagnostic_count = function(buf_id)
		local res = {}
		for _, d in ipairs(vim.diagnostic.get(buf_id)) do
			res[d.severity] = (res[d.severity] or 0) + 1
		end
		return res
	end

	H.get_workspace_diagnostic_count = function()
		return H.get_diagnostic_count(nil)
	end
end

H.diagnostic_is_disabled = function()
	return not vim.diagnostic.is_enabled({ bufnr = 0 })
end
if vim.fn.has("nvim-0.10") == 0 then
	H.diagnostic_is_disabled = function()
		return vim.diagnostic.is_disabled(0)
	end
end

-- Utilities ------------------------------------------------------------------
H.error = function(msg)
	error("(mini.statusline) " .. msg, 0)
end

H.check_type = function(name, val, ref, allow_nil)
	if type(val) == ref or (ref == "callable" and vim.is_callable(val)) or (allow_nil and val == nil) then
		return
	end
	H.error(string.format("`%s` should be %s, not %s", name, ref, type(val)))
end

H.check_severity_map = function(name, map)
	for _, level in ipairs(H.diagnostic_levels) do
		H.check_type(string.format("%s.%s", name, level.name), map[level.name], "string", true)
	end
end

H.with_prefix = function(prefix, text)
	if prefix == nil or prefix == "" then
		return text
	end
	return string.format("%s %s", prefix, text)
end

H.check_diff_map = function(name, map)
	for _, key in ipairs({ "added", "modified", "removed" }) do
		H.check_type(string.format("%s.%s", name, key), map[key], "string", true)
	end
end

H.diff_token_types = {
	["+"] = "added",
	["~"] = "modified",
	["-"] = "removed",
}

H.format_diff_summary = function(summary, signs, highlights, reset_highlight)
	if summary == "" then
		return "-"
	end

	local parts = {}
	for token in vim.gsplit(summary, "%s+", { trimempty = true }) do
		local prefix, count = token:match("^([+~-])(%d+)$")
		local diff_type = H.diff_token_types[prefix]
		if diff_type == nil then
			table.insert(parts, token)
		else
			local text = (signs[diff_type] or prefix) .. count
			local hl = highlights[diff_type]
			if type(hl) == "string" and hl ~= "" then
				table.insert(parts, string.format("%%#%s#%s%%#%s#", hl, text, reset_highlight))
			else
				table.insert(parts, text)
			end
		end
	end

	return #parts == 0 and summary or table.concat(parts, "")
end

H.get_filesize = function()
	local size = math.max(vim.fn.line2byte(vim.fn.line("$") + 1) - 1, 0)
	if size < 1024 then
		return string.format("%dB", size)
	elseif size < 1048576 then
		return string.format("%.2fKiB", size / 1024)
	else
		return string.format("%.2fMiB", size / 1048576)
	end
end

H.ensure_get_icon = function()
	if not (H.use_icons or H.get_config().use_icons) then
		-- Show no icon
		H.get_icon = nil
	elseif H.get_icon ~= nil then
		-- Cache only once
		return
	elseif _G.MiniIcons ~= nil then
		-- Prefer 'mini.icons'
		H.get_icon = function(filetype)
			return (_G.MiniIcons.get("filetype", filetype))
		end
	else
		-- Try falling back to 'nvim-web-devicons'
		local has_devicons, devicons = pcall(require, "nvim-web-devicons")
		if not has_devicons then
			return
		end
		H.get_icon = function()
			return (devicons.get_icon(vim.fn.expand("%:t"), nil, { default = true }))
		end
	end
end

return MiniStatusline
