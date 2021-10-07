---------------------------------------------------------------------------
--- Watch widget.
-- Here is an example of simple temperature widget which will update each 15
-- seconds implemented in two different ways.
-- The first, simpler one, will just display the return command output
-- (so output is stripped by shell commands).
-- In the other example `sensors` returns to the widget its full output
-- and it's trimmed in the widget callback function:
--
--     211             mytextclock,
--     212             wibox.widget.textbox('  |  '),
--     213             -- one way to do that:
--     214             awful.widget.watch('bash -c "sensors | grep temp1"', 15),
--     215             -- another way:
--     216             awful.widget.watch('sensors', 15, function(widget, stdout)
--     217               for line in stdout:gmatch("[^\r\n]+") do
--     218                 if line:match("temp1") then
--     219                   widget:set_text(line)
--     220                   return
--     221                 end
--     222               end
--     223             end),
--     224             s.mylayoutbox,
--
-- ![Example screenshot](../images/awful_widget_watch.png)
--
-- Here is the most basic usage:
--
-- 
--DOC_HIDE --DOC_GEN_IMAGE
--
--![Usage example](../images/AUTOGEN_wibox_awidget_defaults_watch.svg)
--
-- 
--     awful.widget.watch('bash -c &#34echo Hello world! | grep Hello&#34', 15)
--
-- @author Benjamin Petrenko
-- @author Yauheni Kirylau
-- @copyright 2015, 2016 Benjamin Petrenko, Yauheni Kirylau
-- @widgetmod awful.widget.watch
---------------------------------------------------------------------------

local setmetatable = setmetatable
local textbox = require("wibox.widget.textbox")
local timer = require("gears.timer")
local spawn = require("awful.spawn")

local watch = { mt = {} }

--- Create a textbox that shows the output of a command
-- and updates it at a given time interval.
--
-- @tparam string|table command The command.
--
-- @tparam[opt=5] integer timeout The time interval at which the textbox
-- will be updated.
--
-- @tparam[opt] function callback The function that will be called after
-- the command output will be received. it is shown in the textbox.
-- Defaults to:
--     function(widget, stdout, stderr, exitreason, exitcode)
--         widget:set_text(stdout)
--     end
-- @param callback.widget Base widget instance.
-- @tparam string callback.stdout Output on stdout.
-- @tparam string callback.stderr Output on stderr.
-- @tparam string callback.exitreason Exit Reason.
-- The reason can be "exit" or "signal".
-- @tparam integer callback.exitcode Exit code.
-- For "exit" reason it's the exit code.
-- For "signal" reason — the signal causing process termination.
--
-- @param[opt=wibox.widget.textbox()] base_widget Base widget.
--
-- @return The widget used by this watch.
-- @return Its gears.timer.
-- @constructorfct awful.widget.watch
function watch.new(command, timeout, callback, base_widget)
    timeout = timeout or 5
    base_widget = base_widget or textbox()
    callback = callback or function(widget, stdout, stderr, exitreason, exitcode) -- luacheck: no unused args
        widget:set_text(stdout)
    end
    local t = timer { timeout = timeout }
    t:connect_signal("timeout", function()
        t:stop()
        spawn.easy_async(command, function(stdout, stderr, exitreason, exitcode)
          callback(base_widget, stdout, stderr, exitreason, exitcode)
          t:again()
        end)
    end)
    t:start()
    t:emit_signal("timeout")
    return base_widget, t
end

function watch.mt.__call(_, ...)
    return watch.new(...)
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

return setmetatable(watch, watch.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
