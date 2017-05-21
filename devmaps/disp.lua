local calc_target;
local calc_sources = {};
local refresh_timer = 0;
local refresh_base = 3;
local switch_slow = 16;
local switch_fast = 32;

-- used for interpolating color changes
local cur_table = {};
local step_table = {};
for i=1,32 do
	cur_table[i] = {0, 0, 0};
	step_table[i] = {0, 0, 0};
end

--
-- to go with slices of the edges instead of just downscale + sample where
-- the LEDs are positioned relative to the monitor, this was sortof the way:
--	calc_sources[1] = null_surface(8, 1);
--	calc_sources[2] = null_surface(8, 1);
--	calc_sources[3] = null_surface(8, 1);
--	calc_sources[4] = null_surface(8, 1);
--	move_image(calc_sources[2], 0, 1);
--	move_image(calc_sources[3], 0, 2);
--	move_image(calc_sources[4], 0, 3);
--	show_image({calc_sources[1], calc_sources[2], calc_sources[3], calc_sources[4]});
-- slice top
-- 	image_set_txcos(calc_sources[1], {0.0,  0.0, 1.0, 0.0,  1.0, 0.01, 0.0, 0.01});
-- bottom
--	image_set_txcos(calc_sources[2], {0.0, 0.99, 1.0, 0.99, 1.0, 1.0, 0.0, 1.0});
-- left
--	image_set_txcos(calc_sources[3], {0.0, 0.0, 0.01, 0.0, 0.01, 1.0, 0.0, 1.0});
-- right
--	image_set_txcos(calc_sources[4], {0.99, 0.0, 1.0, 0.0, 1.0, 1.0, 0.99, 1.0});
-- + different :get coordinates
--

-- slices source into rows, where each row = one group of leds
local function build_ct()
	calc_target = alloc_surface(64, 32);
-- create a manually triggered rendertarget with a readback into a callback
-- function. in this function, sample each row and map into the respective
-- groups of leds (1..8 top, 9..16 left, 17..24 down, 25..32 right)
	local ofs_t = 0;
	local ofs_l = 8;
	local ofs_b = 16;
	local ofs_r = 24;
	calc_sources[1] = null_surface(64, 32);
	show_image(calc_sources[1]);

	define_calctarget(calc_target, calc_sources,
		RENDERTARGET_DETACH, RENDERTARGET_NOSCALE, 0,
		function(tbl, w, h)
			for x=1,8 do
				local r, g, b = tbl:get(27 + x, 0, 3);
				step_table[x+ofs_t][1] = r - cur_table[x+ofs_t][1];
				step_table[x+ofs_t][2] = g - cur_table[x+ofs_t][2];
				step_table[x+ofs_t][3] = b - cur_table[x+ofs_t][3];

				r, g, b = tbl:get(27 + x, 31, 3);
				step_table[x+ofs_b][1] = r - cur_table[x+ofs_b][1];
				step_table[x+ofs_b][2] = g - cur_table[x+ofs_b][2];
				step_table[x+ofs_b][3] = b - cur_table[x+ofs_b][3];

				r, g, b = tbl:get(0, 12 + x, 3);
				step_table[x+ofs_l][1] = r - cur_table[x+ofs_l][1];
				step_table[x+ofs_l][2] = g - cur_table[x+ofs_l][2];
				step_table[x+ofs_l][3] = b - cur_table[x+ofs_l][3];

				r, g, b = tbl:get(63, 12 + x, 3);
				step_table[x+ofs_r][1] = r - cur_table[x+ofs_r][1];
				step_table[x+ofs_r][2] = g - cur_table[x+ofs_r][2];
				step_table[x+ofs_r][3] = b - cur_table[x+ofs_r][3];
			end
		end
	);
end

local function update_source(vid)
	for i, v in ipairs(calc_sources) do
		image_sharestorage(vid, v);
	end
	rendertarget_forceupdate(calc_target);
	stepframe_target(calc_target);
end

return {
	label = "(FIFO2)",
	name = "fifo2",
	role = "custom",
	matchlbl = "(led-fifo 2)",
	tickrate = 1,
	clock = function(devid)
-- 1. prepare intermediate buffer for scaling and readback, manual updates,
--    set to sample display by default (will be triggered to something else
--    next clock+wnd_creation, but there's likely no window right now)
		if (not valid_vid(calc_target)) then
			build_ct();
			local vid = active_display(true);
			update_source(vid);
		end

-- only reflect the contents of the selected window
		local switch = active_display().selected and
			last_canvas ~= active_display().selected.canvas;

		if (switch) then
			last_canvas = active_display().selected.canvas;
			update_source(last_canvas);
		end

-- do we have something in the stepping table?
		local dirty = false;
		for i=1,32 do
			if (step_table[i][1] ~= 0 or
				step_table[i][2] ~= 0 or step_table[i][3] ~= 0) then
					dirty = true;
			end
		end

-- no? then just issue a new readback request
		if (not dirty) then
			refresh_timer = refresh_timer - 1;
			if (refresh_timer <= 0) then
				rendertarget_forceupdate(calc_target);
				stepframe_target(calc_target);
				refresh_timer = refresh_base;
			end
			return;
		end

		local lim = switch and switch_slow or switch_fast;

		for i=1,32 do
			if (step_table[i][1] ~= 0 or
				step_table[i][2] ~= 0 or step_table[i][3] ~= 0) then
				local sr = step_table[i][1];
				local sg = step_table[i][2];
				local sb = step_table[i][3];

				if (math.abs(sr) > lim) then
					sr = lim * (sr > 0 and 1 or -1);
				end

				if (math.abs(sg) > lim) then
					sg = lim * (sg > 0 and 1 or -1);
				end

				if (math.abs(sb) > lim) then
					sb = lim * (sb > 0 and 1 or -1);
				end

				step_table[i][1] = step_table[i][1] - sr;
				step_table[i][2] = step_table[i][2] - sg;
				step_table[i][3] = step_table[i][3] - sb;
				cur_table[i][1] = cur_table[i][1] + sr;
				cur_table[i][2] = cur_table[i][2] + sg;
				cur_table[i][3] = cur_table[i][3] + sb;
				set_led_rgb(devid,
					i-1, cur_table[i][1], cur_table[i][2], cur_table[i][3], true);
			end
		end

-- flush/commit
		set_led_rgb(devid, 255, 0, 0, 0);
	end
};
