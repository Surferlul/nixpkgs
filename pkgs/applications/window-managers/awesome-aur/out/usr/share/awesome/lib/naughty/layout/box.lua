----------------------------------------------------------------------------
--- A notification popup widget.
--
-- By default, the box is composed of many other widgets:
--
--
--
--![Usage example](../images/AUTOGEN_wibox_nwidget_default.svg)
--
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2017 Emmanuel Lepage Vallee
-- @popupmod naughty.layout.box
-- @supermodule awful.popup
----------------------------------------------------------------------------

local capi       = {screen=screen}
local beautiful  = require("beautiful")
local gtimer     = require("gears.timer")
local gtable     = require("gears.table")
local wibox      = require("wibox")
local popup      = require("awful.popup")
local awcommon   = require("awful.widget.common")
local placement  = require("awful.placement")
local abutton    = require("awful.button")
local ascreen    = require("awful.screen")
local gpcall     = require("gears.protected_call")
local dpi        = require("beautiful").xresources.apply_dpi

local default_widget = require("naughty.widget._default")

local box, by_position = {}, {}

-- Init the weak tables for each positions. It is done ahead of time rather
-- than when notifications are added to simplify the code.

local function init_screen(s)
    if not s.valid then return end

    if by_position[s] then return by_position[s] end

    by_position[s] = setmetatable({},{__mode = "k"})

    for _, pos in ipairs { "top_left"   , "top_middle"   , "top_right",
                           "bottom_left", "bottom_middle", "bottom_right" } do
        by_position[s][pos] = setmetatable({},{__mode = "v"})
    end

    return by_position[s]
end

ascreen.connect_for_each_screen(init_screen)

-- Manually cleanup to help the GC.
capi.screen.connect_signal("removed", function(scr)
    -- By that time, all direct events should have been handled. Cleanup the
    -- leftover. Being a weak table doesn't help Lua 5.1.
    gtimer.delayed_call(function()
        by_position[scr] = nil
    end)
end)

local function get_spacing()
    local margin = beautiful.notification_spacing or dpi(2)
    return {top = margin, bottom = margin}
end

local function get_offset(position, preset)
    preset = preset or {}
    local margin = preset.padding or beautiful.notification_spacing or dpi(4)
    if position:match('_right') then
        return {x = -margin}
    elseif position:match('_left') then
        return {x = margin}
    end
    return {}
end

-- Leverage `awful.placement` to create the stacks.
local function update_position(position, preset)
    local pref  = position:match("top_") and "bottom" or "top"
    local align = position:match("_(.*)")
        :gsub("left", "front"):gsub("right", "back")

    for _, pos in pairs(by_position) do
        for k, wdg in ipairs(pos[position]) do
            local args = {
                geometry            = pos[position][k-1],
                preferred_positions = {pref },
                preferred_anchors   = {align},
                margins             = get_spacing(),
                honor_workarea      = true,
            }
            if k == 1 then
                args.offset              = get_offset(position, preset)
            end

            -- The first entry is aligned to the workarea, then the following to the
            -- previous widget.
            placement[k==1 and position:gsub("_middle", "") or "next_to"](wdg, args)

            wdg.visible = true
        end
    end
end

local function finish(self)
    self.visible = false
    assert(init_screen(self.screen)[self.position])

    for k, v in ipairs(init_screen(self.screen)[self.position]) do
        if v == self then
            table.remove(init_screen(self.screen)[self.position], k)
            break
        end
    end

    local preset
    if self.private and self.private.args and self.private.args.notification then
        preset = self.private.args.notification.preset
    end

    update_position(self.position, preset)
end

-- It isn't a good idea to use the `attach` `awful.placement` property. If the
-- screen is resized or the notification is moved, it causes side effects.
-- Better listen to geometry changes and reflow.
capi.screen.connect_signal("property::geometry", function(s)
    for pos, notifs in pairs(by_position[s]) do
        if #notifs > 0 then
            update_position(pos, notifs[1].preset)
        end
    end
end)

--- The maximum notification width.
-- @beautiful beautiful.notification_max_width
-- @tparam[opt=500] number notification_max_width

--- The maximum notification position.
--
-- Valid values are:
--
-- * top_left
-- * top_middle
-- * top_right
-- * bottom_left
-- * bottom_middle
-- * bottom_right
--
-- @beautiful beautiful.notification_position
-- @tparam[opt="top_right"] string notification_position

--- The widget notification object.
--
-- @property notification
-- @tparam naughty.notification notification
-- @propemits true false

--- The widget template to construct the box content.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_nwidget_default.svg)
--
--
-- The default template is (less or more):
--
--    {
--        {
--            {
--                {
--                    {
--                        naughty.widget.icon,
--                        {
--                            naughty.widget.title,
--                            naughty.widget.message,
--                            spacing = 4,
--                            layout  = wibox.layout.fixed.vertical,
--                        },
--                        fill_space = true,
--                        spacing    = 4,
--                        layout     = wibox.layout.fixed.horizontal,
--                    },
--                    naughty.list.actions,
--                    spacing = 10,
--                    layout  = wibox.layout.fixed.vertical,
--                },
--                margins = beautiful.notification_margin,
--                widget  = wibox.container.margin,
--            },
--            id     = "background_role",
--            widget = naughty.container.background,
--        },
--        strategy = "max",
--        width    = width(beautiful.notification_max_width
--            or beautiful.xresources.apply_dpi(500)),
--        widget   = wibox.container.constraint,
--    }
--
-- @property widget_template
-- @param widget
-- @usebeautiful beautiful.notification_max_width The maximum width for the
--  resulting widget.

local function generate_widget(args, n)
    local w = gpcall(wibox.widget.base.make_widget_from_value,
        args.widget_template or (n and n.widget_template) or default_widget
    )

    -- This will happen if the user-provided widget_template is invalid and/or
    -- got unexpected notifications.
    if not w then
        w = gpcall(wibox.widget.base.make_widget_from_value, default_widget)

        -- In case this happens in an error message itself, make sure the
        -- private error popup code knowns it and can revert to the fallback
        -- popup.
        if not w then
            n._private.widget_template_failed = true
        end

        return nil
    end

    if w.set_width then
        w:set_width(n.max_width or beautiful.notification_max_width or dpi(500))
    end

    -- Call `:set_notification` on all children
    awcommon._set_common_property(w, "notification", n or args.notification)

    return w
end

local function init(self, notification)
    local args = self._private.args

    local preset = notification.preset or {}

    local position = args.position or notification.position or
        preset.position or beautiful.notification_position or "top_right"

    if not self.widget then
        self.widget = generate_widget(self._private.args, notification)
    end

    local bg = self._private.widget:get_children_by_id( "background_role" )[1]

    -- Make sure the border isn't set twice, favor the widget one since it is
    -- shared by the notification list and the notification box.
    if bg then
        if bg.set_notification then
            bg:set_notification(notification)
            self.border_width = 0
        else
            bg:set_bg(notification.bg)
            self.border_width = notification.border_width
        end
    end

    local s = notification.screen
    assert(s)

    -- Add the notification to the active list
    assert(init_screen(s)[position], "Invalid position "..position)

    self:_apply_size_now()

    table.insert(init_screen(s)[position], self)

    local function update() update_position(position, preset) end

    self:connect_signal("property::geometry", update)
    notification:connect_signal("property::margin", update)
    notification:connect_signal("destroyed", self._private.destroy_callback)

    update_position(position, preset)

end

function box:set_notification(notif)
    if self._private.notification == notif then return end

    if self._private.notification then
        self._private.notification:disconnect_signal("destroyed",
            self._private.destroy_callback)
    end

    init(self, notif)

    self._private.notification = notif

    self:emit_signal("property::notification", notif)
end

function box:get_position()
    if self._private.notification then
        return self._private.notification:get_position()
    end

    return "top_right"
end

--- Create a notification popup box.
--
-- @constructorfct naughty.layout.box
-- @tparam[opt=nil] table args
-- @tparam table args.widget_template A widget definition template which will
--  be instantiated for each box.
-- @tparam naughty.notification args.notification The notification object.
-- @tparam string args.position The position. See `naughty.notification.position`.
-- @tparam integer args.border_width Border width.
-- @tparam string args.border_color Border color.
-- @tparam[opt=false] boolean args.ontop On top of other windows.
-- @tparam string args.cursor The mouse cursor.
-- @tparam boolean args.visible Visibility.
-- @tparam[opt=1] number args.opacity The opacity, between 0 and 1.
-- @tparam string args.type The window type (desktop, normal, dock, …).
-- @tparam integer args.x The x coordinates.
-- @tparam integer args.y The y coordinates.
-- @tparam integer args.width The width.
-- @tparam integer args.height The height.
-- @tparam screen args.screen The wibox screen.
-- @tparam wibox.widget args.widget The widget that the wibox displays.
-- @param args.shape_bounding The wibox’s bounding shape as a (native) cairo surface.
-- @param args.shape_clip The wibox’s clip shape as a (native) cairo surface.
-- @param args.shape_input The wibox’s input shape as a (native) cairo surface.
-- @tparam color args.bg The background.
-- @tparam surface args.bgimage The background image of the drawable.
-- @tparam color args.fg The foreground (text) color.
-- @tparam gears.shape args.shape The shape.
-- @tparam[opt=false] boolean args.input_passthrough If the inputs are
--  forward to the element below.
-- @usebeautiful beautiful.notification_position If `position` is not defined
-- in the notification object (or in this constructor).

local function new(args)
    args = args or {}

    -- Set the default wibox values
    local new_args = {
        ontop        = true,
        visible      = false,
        bg           = args.bg or beautiful.notification_bg,
        fg           = args.fg or beautiful.notification_fg,
        shape        = args.shape or beautiful.notification_shape,
        border_width = args.border_width or beautiful.notification_border_width or 1,
        border_color = args.border_color or beautiful.notification_border_color,
    }

    -- The C code needs `pairs` to work, so a full copy is required.
    gtable.crush(new_args, args, true)

    -- Add a weak-table layer for the screen.
    local weak_args = setmetatable({
        screen = args.notification and args.notification.screen or nil
    }, {__mode="v"})

    setmetatable(new_args, {__index = weak_args})

    -- Generate the box before the popup is created to avoid the size changing
    new_args.widget = generate_widget(new_args, new_args.notification)

    -- It failed, request::fallback will be used, there is nothing left to do.
    if not new_args.widget then return nil end

    local ret = popup(new_args)
    ret._private.args = new_args

    gtable.crush(ret, box, true)

    function ret._private.destroy_callback()
        finish(ret)
    end

    if new_args.notification then
        ret:set_notification(new_args.notification)
    end

    --TODO remove
    local function hide()
        if ret._private.notification then
            ret._private.notification:destroy()
        end
    end

    --FIXME there's another pull request for this
    ret:buttons(gtable.join(
        abutton({ }, 1, hide),
        abutton({ }, 3, hide)
    ))

    gtable.crush(ret, box, false)

    return ret
end

----- Border width.
--
-- @baseclass wibox
-- @property border_width
-- @param integer
-- @propemits false false

--- Border color.
--
-- Please note that this property only support string based 24 bit or 32 bit
-- colors:
--
--    Red Blue
--     _|  _|
--    #FF00FF
--       T‾
--     Green
--
--
--    Red Blue
--     _|  _|
--    #FF00FF00
--       T‾  ‾T
--    Green   Alpha
--
-- @baseclass wibox
-- @property border_color
-- @param string
-- @propemits false false

--- On top of other windows.
--
-- @baseclass wibox
-- @property ontop
-- @param boolean
-- @propemits false false

--- The mouse cursor.
--
-- @baseclass wibox
-- @property cursor
-- @param string
-- @see mouse
-- @propemits false false

--- Visibility.
--
-- @baseclass wibox
-- @property visible
-- @param boolean
-- @propemits false false

--- The opacity of the wibox, between 0 and 1.
--
-- @baseclass wibox
-- @property opacity
-- @tparam number opacity (between 0 and 1)
-- @propemits false false

--- The window type (desktop, normal, dock, ...).
--
-- @baseclass wibox
-- @property type
-- @param string
-- @see client.type
-- @propemits false false

--- The x coordinates.
--
-- @baseclass wibox
-- @property x
-- @param integer
-- @propemits false false

--- The y coordinates.
--
-- @baseclass wibox
-- @property y
-- @param integer
-- @propemits false false

--- The width of the wibox.
--
-- @baseclass wibox
-- @property width
-- @param width
-- @propemits false false

--- The height of the wibox.
--
-- @baseclass wibox
-- @property height
-- @param height
-- @propemits false false

--- The wibox screen.
--
-- @baseclass wibox
-- @property screen
-- @param screen
-- @propemits true false

---  The wibox's `drawable`.
--
-- @baseclass wibox
-- @property drawable
-- @tparam drawable drawable
-- @propemits false false

--- The widget that the `wibox` displays.
-- @baseclass wibox
-- @property widget
-- @param widget
-- @propemits true false

--- The X window id.
--
-- @baseclass wibox
-- @property window
-- @param string
-- @see client.window
-- @propemits false false

--- The wibox's bounding shape as a (native) cairo surface.
--
-- If you want to set a shape, let say some rounded corners, use
-- the `shape` property rather than this. If you want something
-- very complex, for example, holes, then use this.
--
-- @baseclass wibox
-- @property shape_bounding
-- @param surface._native
-- @propemits false false
-- @see shape

--- The wibox's clip shape as a (native) cairo surface.
--
-- The clip shape is the shape of the window *content* rather
-- than the outer window shape.
--
-- @baseclass wibox
-- @property shape_clip
-- @param surface._native
-- @propemits false false
-- @see shape

--- The wibox's input shape as a (native) cairo surface.
--
-- The input shape allows to disable clicks and mouse events
-- on part of the window. This is how `input_passthrough` is
-- implemented.
--
-- @baseclass wibox
-- @property shape_input
-- @param surface._native
-- @propemits false false
-- @see input_passthrough

--- The wibar's shape.
--
-- @baseclass wibox
-- @property shape
-- @tparam gears.shape shape
-- @propemits true false
-- @see gears.shape

--- Forward the inputs to the client below the wibox.
--
-- This replace the `shape_input` mask with an empty area. All mouse and
-- keyboard events are sent to the object (such as a client) positioned below
-- this wibox. When used alongside compositing, it allows, for example, to have
-- a subtle transparent wibox on top a fullscreen client to display important
-- data such as a low battery warning.
--
-- @baseclass wibox
-- @property input_passthrough
-- @param[opt=false] boolean
-- @see shape_input
-- @propemits true false

--- Get or set mouse buttons bindings to a wibox.
--
-- @baseclass wibox
-- @property buttons
-- @param buttons_table A table of buttons objects, or nothing.
-- @propemits false false

--- Get or set wibox geometry. That's the same as accessing or setting the x,
-- y, width or height properties of a wibox.
--
-- @baseclass wibox
-- @param A table with coordinates to modify.
-- @return A table with wibox coordinates and geometry.
-- @method geometry
-- @emits property::geometry When the geometry change.
-- @emitstparam property::geometry table geo The geometry table.

--- Get or set wibox struts.
--
-- Struts are the area which should be reserved on each side of
-- the screen for this wibox. This is used to make bars and
-- docked displays. Note that `awful.wibar` implements all the
-- required boilerplate code to make bar. Only use this if you
-- want special type of bars (like bars not fully attached to
-- the side of the screen).
--
-- @baseclass wibox
-- @param strut A table with new strut, or nothing
-- @return The wibox strut in a table.
-- @method struts
-- @see client.struts
-- @emits property::struts

--- The default background color.
--
-- The background color can be transparent. If there is a
-- compositing manager such as compton, then it will be
-- real transparency and may include blur (provided by the
-- compositor). When there is no compositor, it will take
-- a picture of the wallpaper and blend it.
--
-- @baseclass wibox
-- @beautiful beautiful.bg_normal
-- @param color
-- @see bg

--- The default foreground (text) color.
-- @baseclass wibox
-- @beautiful beautiful.fg_normal
-- @param color
-- @see fg

--- Set a declarative widget hierarchy description.
-- See [The declarative layout system](../documentation/03-declarative-layout.md.html)
-- @param args An array containing the widgets disposition
-- @baseclass wibox
-- @method setup

--- The background of the wibox.
--
-- The background color can be transparent. If there is a
-- compositing manager such as compton, then it will be
-- real transparency and may include blur (provided by the
-- compositor). When there is no compositor, it will take
-- a picture of the wallpaper and blend it.
--
-- @baseclass wibox
-- @property bg
-- @tparam c The background to use. This must either be a cairo pattern object,
--   nil or a string that gears.color() understands.
-- @see gears.color
-- @propemits true false
-- @usebeautiful beautiful.bg_normal The default (fallback) bg color.

--- The background image of the drawable.
--
-- If `image` is a function, it will be called with `(context, cr, width, height)`
-- as arguments. Any other arguments passed to this method will be appended.
--
-- @tparam gears.suface|string|function image A background image or a function.
-- @baseclass wibox
-- @property bgimage
-- @see gears.surface
-- @propemits true false

--- The foreground (text) of the wibox.
-- @tparam color c The foreground to use. This must either be a cairo pattern object,
--   nil or a string that gears.color() understands.
-- @baseclass wibox
-- @property fg
-- @param color
-- @see gears.color
-- @propemits true false
-- @usebeautiful beautiful.fg_normal The default (fallback) fg color.

--- Find a widget by a point.
-- The wibox must have drawn itself at least once for this to work.
-- @tparam number x X coordinate of the point
-- @tparam number y Y coordinate of the point
-- @treturn table A sorted table of widgets positions. The first element is the biggest
-- container while the last is the topmost widget. The table contains *x*, *y*,
-- *width*, *height* and *widget*.
-- @baseclass wibox
-- @method find_widgets

return setmetatable(box, {__call = function(_, args) return new(args) end})
