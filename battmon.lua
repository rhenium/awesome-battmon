local base = require("wibox.widget.base")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local awful = require("awful")
local color = require("gears.color")
local lgi = require("lgi")
local Pango = lgi.Pango
local PangoCairo = lgi.PangoCairo

local battmon = { mt = {} }

local config = setmetatable({}, { __mode = "k" })

local fetch_battery_status = function(adapter)
    local file = io.open("/sys/class/power_supply/" .. adapter .. "/uevent")
    if file == nil then return {} end

    local ob = {}
    for line in file:lines() do
        local name, value = line:match("^([%w_]+)=(.*)$")
        if name then
            if tonumber(value) then
                value = tonumber(value)
            end
            ob[name] = value
        end
    end
    file:close()

    local let = {
        name =       ob["POWER_SUPPLY_NAME"],
        status =     ob["POWER_SUPPLY_STATUS"], -- drivers/power/power_supply_sysfs.c: Unknown, Charging, Discharging, Not charging, Full
        capacity =   ob["POWER_SUPPLY_CAPACITY"],
        present =    ob["POWER_SUPPLY_PRESENT"] == 1,
        energe_now = ob["POWER_SUPPLY_ENERGY_NOW"],
        power_now =  ob["POWER_SUPPLY_POWER_NOW"],
        online =     ob["POWER_SUPPLY_ONLINE"] == 1, -- AC adapter
    }

    return let
end

function draw_charging(cr, width, height)
    cr:move_to(width * 0.8, height * 0.0)
    cr:line_to(width * 0.0, height * 0.6)
    cr:line_to(width * 0.4, height * 0.6)
    cr:line_to(width * 0.2, height * 1.0)
    cr:line_to(width * 1.0, height * 0.4)
    cr:line_to(width * 0.6, height * 0.4)
    cr:line_to(width * 0.8, height * 0.0)
end

function battmon.draw(widget, wibox, cr, width, height)
    local ac_status = config[widget].ac_status
    local status = config[widget].battery_status

    local ctx = PangoCairo.font_map_get_default():create_context()
    ctx:set_resolution(beautiful.xresources.get_dpi())
    local capacity_layout = Pango.Layout.new(ctx)
    capacity_layout:set_text(status.capacity)
    capacity_layout:set_font_description(beautiful.get_font(beautiful.font))

    local _, logical = capacity_layout:get_pixel_extents()
    local text_width = logical.width
    local text_height = logical.height

    local draw_color = color(config[widget].normal_color)
    if status.present then
        if status.status == "Charging" then
            draw_color = color(config[widget].charging_color)
        elseif status.capacity <= config[widget].critical then
            draw_color = color(config[widget].critical_color)
        elseif status.capacity <= config[widget].warning then
            draw_color = color(config[widget].warning_color)
        end
    end
    cr:set_source(draw_color)
    cr.fill_rule = "EVEN_ODD"

    -- draw border ( margin-top: 2, margin-left: 1 )
    cr:rectangle(1, 2, width - 2, height - 4)
    cr:rectangle(2, 3, width - 4, height - 6)

    local inner_width = width - 4
    local inner_height = height - 6
    cr:translate(2, 3)

    -- fill remaining
    cr:rectangle(0, 0, inner_width * status.capacity / 100, inner_height)

    if ac_status.online then
        local charging_height = inner_height - dpi(inner_height * 0.05)
        local charging_width = charging_height / 2.0
        local offset_x_text = (inner_width - charging_width - text_width + dpi(2)) / 2.0 -- 2 is padding
        local offset_y_text = (inner_height - text_height) / 2.0
        local offset_y_charging = (inner_height - charging_height) / 2.0
        local offset_x_charging = offset_x_text + text_width + dpi(2) -- 2 is padding

        -- draw remaining percent
        cr:save()
        cr:move_to(offset_x_text, offset_y_text)
        cr:layout_path(capacity_layout)
        cr:restore()

        -- draw charging icon
        cr:save()
        cr:translate(offset_x_charging, offset_y_charging)
        draw_charging(cr, charging_width, charging_height)
        cr:restore()
    else
        local offset_x_text = (inner_width - text_width) / 2.0
        local offset_y_text = (inner_height - text_height) / 2.0

        -- draw remaining percent
        cr:save()
        cr:move_to(offset_x_text, offset_y_text)
        cr:layout_path(capacity_layout)
        cr:restore()
    end

    cr:fill()

    -- set tooltip
    local tooltip_text
    if status.status == "Discharging" then
        local hours = math.floor(status.energe_now / status.power_now)
        local minutes = math.floor(60 * (status.energe_now / status.power_now - hours))
        local watts = math.floor(status.power_now / 1000 / 10) / 100 -- a.bc watts
        tooltip_text =
            status.name .. ": " .. status.capacity .. "%, Discharging (" .. watts .. " W)\n" ..
            "estimated remaining: " .. hours .. " hours, " .. minutes .. " minutes"
    else
        tooltip_text =
            status.name .. ": " .. status.capacity .. "%, " .. status.status
    end
    config[widget].tooltip:set_text(tooltip_text)
end

function battmon.fit(widget, width, height)
    return config[widget].width, height
end

function battmon.new(args)
    local args = args or {}
    local widget = base.make_widget()

    config[widget] = {
        battery = args.battery or "BAT0",
        ac_adapter = args.ac_adapter or "AC",
        width = args.width or dpi(48),
        warning = args.warning or dpi(30),
        critical = args.critical or dpi(10),
        normal_color = args.normal_color or "#ffffff",
        charging_color = args.charging_color or "#00ff00",
        warning_color = args.warning_color or "#ffff00",
        critical_color = args.critical_color or "#ff0000",
        update_interval = args.update_interval or 10,

        tooltip = awful.tooltip({ objects = { widget } }),
        battery_status = nil,
        ac_status = nil,
    }

    widget.draw = battmon.draw
    widget.fit = battmon.fit

    -- setup timer
    local bm_timer = timer { timeout = config[widget].update_interval }
    local bm_cb = function()
        config[widget].ac_status = fetch_battery_status(config[widget].ac_adapter)
        config[widget].battery_status = fetch_battery_status(config[widget].battery)
        bm_timer:again()
    end
    bm_cb() -- initial update
    bm_timer:connect_signal("timeout", bm_cb)
    bm_timer:start()

    return widget
end

function battmon.all()
    local list = {}
    for bname in io.popen("find /sys/class/power_supply/ -name 'BAT*' -printf '%f\\n'"):lines() do
        list[#list+1] = battmon.new({ battery = bname })
    end
    return list
end

function battmon.mt:__call(...)
    return battmon.new(...)
end

return setmetatable(battmon, battmon.mt)
