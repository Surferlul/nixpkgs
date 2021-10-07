----------------------------------------------------------------------------
--- A notification square icon.
--
-- This widget is a specialized `wibox.widget.imagebox` with the following extra
-- features:
--
-- * Honor the `beautiful` notification variables.
-- * Restrict the size avoid huge notifications
-- * Provides some strategies to handle small icons
-- * React to the `naughty.notification` object icon changes.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_nwidget_icon_simple.svg)
--
-- @usage
--     local notif = naughty.notification {
--         title   = &#34A notification&#34,
--         message = &#34This notification has actions!&#34,
--         icon    = beautiful.awesome_icon,
--     }
--  
--     wibox.widget {
--         notification = notif,
--         widget       = naughty.widget.icon,
--     }
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2017 Emmanuel Lepage Vallee
-- @widgetmod naughty.widget.icon
-- @see wibox.widget.imagebox
----------------------------------------------------------------------------
local imagebox = require("wibox.widget.imagebox")
local gtable  = require("gears.table")
local beautiful = require("beautiful")
local gsurface = require("gears.surface")
local dpi = require("beautiful.xresources").apply_dpi

local icon = {}

-- The default way to resize the icon.
-- @beautiful beautiful.notification_icon_resize_strategy
-- @param number

function icon:fit(_, width, height)
    -- Until someone complains, adding a "leave blank space" isn't supported
    if not self._private.image then return 0, 0 end

    local maximum  = math.min(width, height)
    local strategy = self._private.resize_strategy or "resize"
    local optimal  = math.min(beautiful.notification_icon_size or dpi(48), maximum)

    local w = self._private.image:get_width()
    local h = self._private.image:get_height()

    if strategy == "resize" then
        return math.min(w, optimal, maximum), math.min(h, optimal, maximum)
    else
        return optimal, optimal
    end
end

function icon:draw(_, cr, width, height)
    if not self._private.image then return end
    if width == 0 or height == 0 then return end

    -- Let's scale the image so that it fits into (width, height)
    local strategy = self._private.resize_strategy or "resize"
    local w = self._private.image:get_width()
    local h = self._private.image:get_height()
    local aspect = width / w
    local aspect_h = height / h

    if aspect > aspect_h then aspect = aspect_h end

    if aspect < 1 or (strategy == "scale" and (w < width or h < height)) then
        cr:scale(aspect, aspect)
    end

    local x, y = 0, 0

    if (strategy == "center" and aspect < 1) or strategy == "resize" then
        x = math.floor((width  - w*aspect) / 2)
        y = math.floor((height - h*aspect) / 2)
    elseif strategy == "center" and aspect > 1 then
        x = math.floor((width  - w) / 2)
        y = math.floor((height - h) / 2)
    end

    cr:set_source_surface(self._private.image, x, y)
    cr:paint()
end

--- The attached notification.
-- @property notification
-- @tparam naughty.notification notification
-- @propemits true false

function icon:set_notification(notif)
    if self._private.notification == notif then return end

    if self._private.notification then
        self._private.notification:disconnect_signal("destroyed",
            self._private.icon_changed_callback)
    end

    local icn = gsurface.load_silently(notif.icon)

    if icn then
        self:set_image(icn)
    end

    self._private.notification = notif

    notif:connect_signal("property::icon", self._private.icon_changed_callback)
    self:emit_signal("property::notification", notif)
end

local valid_strategies = {
    scale  = true,
    center = true,
    resize = true,
}

--- How small icons are handled.
--
-- Valid values are:
--
-- * **scale**: Scale the icon up to the optimal size.
-- * **center**: Keep the icon size and draw it in the center
-- * **resize**: Change the size of the widget itself (*default*).
--
-- Note that the size upper bound is defined by
-- `beautiful.notification_icon_size`.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_nwidget_icon_strategy.svg)
--
--
-- @property resize_strategy
-- @tparam string resize_strategy
-- @propemits true false
-- @usebeautiful beautiful.notification_icon_resize_strategy The fallback when
--  there is no specified strategy.
-- @usebeautiful beautiful.notification_icon_size  The size upper bound.

function icon:set_resize_strategy(strategy)
    assert(valid_strategies[strategy], "Invalid strategy")

    self._private.resize_strategy = strategy

    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::resize_strategy", strategy)
end


function icon:get_resize_strategy()
    return self._private.resize_strategy
        or beautiful.notification_icon_resize_strategy
        or "resize"
end

--- Create a new naughty.widget.icon.
-- @tparam table args
-- @tparam naughty.notification args.notification The notification.
-- @constructorfct naughty.widget.icon

local function new(args)
    args = args or {}
    local tb = imagebox()

    gtable.crush(tb, icon, true)

    function tb._private.icon_changed_callback()

        local icn = gsurface.load_silently(tb._private.notification.icon)

        if icn then
            tb:set_image(icn)
        end
    end

    if args.notification then
        tb:set_notification(args.notification)
    end

    return tb
end

--
--- Get a widget index.
-- @param widget The widget to look for
-- @param[opt] recursive Also check sub-widgets
-- @param[opt] ... Additional widgets to add at the end of the path
-- @return The index
-- @return The parent layout
-- @return The path between self and widget
-- @method index
-- @baseclass wibox.widget

--- Get or set the children elements.
-- @property children
-- @tparam table children The children.
-- @baseclass wibox.widget

--- Get all direct and indirect children widgets.
-- This will scan all containers recursively to find widgets
-- Warning: This method it prone to stack overflow id the widget, or any of its
-- children, contain (directly or indirectly) itself.
-- @property all_children
-- @tparam table children The children.
-- @baseclass wibox.widget

--- Set a declarative widget hierarchy description.
-- See [The declarative layout system](../documentation/03-declarative-layout.md.html)
-- @param args An array containing the widgets disposition
-- @method setup
-- @baseclass wibox.widget

--- Force a widget height.
-- @property forced_height
-- @tparam number|nil height The height (`nil` for automatic)
-- @baseclass wibox.widget

--- Force a widget width.
-- @property forced_width
-- @tparam number|nil width The width (`nil` for automatic)
-- @baseclass wibox.widget

--- The widget opacity (transparency).
-- @property opacity
-- @tparam[opt=1] number opacity The opacity (between 0 and 1)
-- @baseclass wibox.widget

--- The widget visibility.
-- @property visible
-- @param boolean
-- @baseclass wibox.widget

--- The widget buttons.
--
-- The table contains a list of `awful.button` objects.
--
-- @property buttons
-- @param table
-- @see awful.button
-- @baseclass wibox.widget

--- Add a new `awful.button` to this widget.
-- @tparam awful.button button The button to add.
-- @method add_button
-- @baseclass wibox.widget

--- Emit a signal and ensure all parent widgets in the hierarchies also
-- forward the signal. This is useful to track signals when there is a dynamic
-- set of containers and layouts wrapping the widget.
-- @tparam string signal_name
-- @param ... Other arguments
-- @baseclass wibox.widget
-- @method emit_signal_recursive

--- When the layout (size) change.
-- This signal is emitted when the previous results of `:layout()` and `:fit()`
-- are no longer valid.  Unless this signal is emitted, `:layout()` and `:fit()`
-- must return the same result when called with the same arguments.
-- @signal widget::layout_changed
-- @see widget::redraw_needed
-- @baseclass wibox.widget

--- When the widget content changed.
-- This signal is emitted when the content of the widget changes. The widget will
-- be redrawn, it is not re-layouted. Put differently, it is assumed that
-- `:layout()` and `:fit()` would still return the same results as before.
-- @signal widget::redraw_needed
-- @see widget::layout_changed
-- @baseclass wibox.widget

--- When a mouse button is pressed over the widget.
-- @signal button::press
-- @tparam table self The current object instance itself.
-- @tparam number lx The horizontal position relative to the (0,0) position in
-- the widget.
-- @tparam number ly The vertical position relative to the (0,0) position in the
-- widget.
-- @tparam number button The button number.
-- @tparam table mods The modifiers (mod4, mod1 (alt), Control, Shift)
-- @tparam table find_widgets_result The entry from the result of
-- @{wibox.drawable:find_widgets} for the position that the mouse hit.
-- @tparam wibox.drawable find_widgets_result.drawable The drawable containing
-- the widget.
-- @tparam widget find_widgets_result.widget The widget being displayed.
-- @tparam wibox.hierarchy find_widgets_result.hierarchy The hierarchy
-- managing the widget's geometry.
-- @tparam number find_widgets_result.x An approximation of the X position that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.y An approximation of the Y position that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.width An approximation of the width that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.height An approximation of the height that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.widget_width The exact width of the widget
-- in its local coordinate system.
-- @tparam number find_widgets_result.widget_height The exact height of the widget
-- in its local coordinate system.
-- @see mouse
-- @baseclass wibox.widget

--- When a mouse button is released over the widget.
-- @signal button::release
-- @tparam table self The current object instance itself.
-- @tparam number lx The horizontal position relative to the (0,0) position in
-- the widget.
-- @tparam number ly The vertical position relative to the (0,0) position in the
-- widget.
-- @tparam number button The button number.
-- @tparam table mods The modifiers (mod4, mod1 (alt), Control, Shift)
-- @tparam table find_widgets_result The entry from the result of
-- @{wibox.drawable:find_widgets} for the position that the mouse hit.
-- @tparam wibox.drawable find_widgets_result.drawable The drawable containing
-- the widget.
-- @tparam widget find_widgets_result.widget The widget being displayed.
-- @tparam wibox.hierarchy find_widgets_result.hierarchy The hierarchy
-- managing the widget's geometry.
-- @tparam number find_widgets_result.x An approximation of the X position that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.y An approximation of the Y position that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.width An approximation of the width that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.height An approximation of the height that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.widget_width The exact width of the widget
-- in its local coordinate system.
-- @tparam number find_widgets_result.widget_height The exact height of the widget
-- in its local coordinate system.
-- @see mouse
-- @baseclass wibox.widget

--- When the mouse enter a widget.
-- @signal mouse::enter
-- @tparam table self The current object instance itself.
-- @tparam table find_widgets_result The entry from the result of
-- @{wibox.drawable:find_widgets} for the position that the mouse hit.
-- @tparam wibox.drawable find_widgets_result.drawable The drawable containing
-- the widget.
-- @tparam widget find_widgets_result.widget The widget being displayed.
-- @tparam wibox.hierarchy find_widgets_result.hierarchy The hierarchy
-- managing the widget's geometry.
-- @tparam number find_widgets_result.x An approximation of the X position that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.y An approximation of the Y position that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.width An approximation of the width that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.height An approximation of the height that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.widget_width The exact width of the widget
-- in its local coordinate system.
-- @tparam number find_widgets_result.widget_height The exact height of the widget
-- in its local coordinate system.
-- @see mouse
-- @baseclass wibox.widget

--- When the mouse leave a widget.
-- @signal mouse::leave
-- @tparam table self The current object instance itself.
-- @tparam table find_widgets_result The entry from the result of
-- @{wibox.drawable:find_widgets} for the position that the mouse hit.
-- @tparam wibox.drawable find_widgets_result.drawable The drawable containing
-- the widget.
-- @tparam widget find_widgets_result.widget The widget being displayed.
-- @tparam wibox.hierarchy find_widgets_result.hierarchy The hierarchy
-- managing the widget's geometry.
-- @tparam number find_widgets_result.x An approximation of the X position that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.y An approximation of the Y position that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.width An approximation of the width that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.height An approximation of the height that
-- the widget is visible at on the surface.
-- @tparam number find_widgets_result.widget_width The exact width of the widget
-- in its local coordinate system.
-- @tparam number find_widgets_result.widget_height The exact height of the widget
-- in its local coordinate system.
-- @see mouse
-- @baseclass wibox.widget

--
--- Disconnect from a signal.
-- @tparam string name The name of the signal.
-- @tparam function func The callback that should be disconnected.
-- @method disconnect_signal
-- @baseclass gears.object

--- Emit a signal.
--
-- @tparam string name The name of the signal.
-- @param ... Extra arguments for the callback functions. Each connected
--   function receives the object as first argument and then any extra
--   arguments that are given to emit_signal().
-- @method emit_signal
-- @baseclass gears.object

--- Connect to a signal.
-- @tparam string name The name of the signal.
-- @tparam function func The callback to call when the signal is emitted.
-- @method connect_signal
-- @baseclass gears.object

--- Connect to a signal weakly.
--
-- This allows the callback function to be garbage collected and
-- automatically disconnects the signal when that happens.
--
-- **Warning:**
-- Only use this function if you really, really, really know what you
-- are doing.
-- @tparam string name The name of the signal.
-- @tparam function func The callback to call when the signal is emitted.
-- @method weak_connect_signal
-- @baseclass gears.object

return setmetatable(icon, {__call = function(_, ...) return new(...) end})
