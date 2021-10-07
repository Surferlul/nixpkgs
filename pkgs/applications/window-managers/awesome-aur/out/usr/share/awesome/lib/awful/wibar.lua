---------------------------------------------------------------------------
--- The main AwesomeWM "bar" module.
--
-- This module allows you to easily create wibox and attach them to the edge of
-- a screen.
--
--
--
--![Usage example](../images/AUTOGEN_awful_wibar_default.svg)
--
-- 
--     local wb = awful.wibar { position = &#34top&#34 }
--     wb:setup {
--         layout = wibox.layout.align.horizontal,
--         {
--             mytaglist,
--             layout = wibox.layout.fixed.horizontal,
--         },
--         mytasklist,
--         {
--             layout = wibox.layout.fixed.horizontal,
--             mykeyboardlayout,
--             mytextclock,
--         },
--     }
--
-- You can even have vertical bars too.
--
--
--
--![Usage example](../images/AUTOGEN_awful_wibar_left.svg)
--
-- 
--     local wb = awful.wibar { position = &#34left&#34 }
--     wb:setup {
--         layout = wibox.layout.align.vertical,
--         {
--             -- Rotate the widgets with the container
--             {
--                 mytaglist,
--                 direction = 'west',
--                 widget = wibox.container.rotate
--             },
--             layout = wibox.layout.fixed.vertical,
--         },
--         mytasklist,
--         {
--             layout = wibox.layout.fixed.vertical,
--             {
--                 -- Rotate the widgets with the container
--                 {
--                     mykeyboardlayout,
--                     mytextclock,
--                     layout = wibox.layout.fixed.horizontal
--                 },
--                 direction = 'west',
--                 widget = wibox.container.rotate
--             }
--         },
--     }
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2016 Emmanuel Lepage Vallee
-- @popupmod awful.wibar
-- @supermodule awful.popup
---------------------------------------------------------------------------

-- Grab environment we need
local capi =
{
    screen = screen,
    client = client
}
local setmetatable = setmetatable
local tostring = tostring
local ipairs = ipairs
local error = error
local wibox = require("wibox")
local beautiful = require("beautiful")
local gdebug = require("gears.debug")
local placement = require("awful.placement")
local gtable = require("gears.table")

local function get_screen(s)
    return s and capi.screen[s]
end

local awfulwibar = { mt = {} }

--- Array of table with wiboxes inside.
-- It's an array so it is ordered.
local wiboxes = setmetatable({}, {__mode = "v"})

local opposite_margin = {
    top    = "bottom",
    bottom = "top",
    left   = "right",
    right  = "left"
}

local align_map = {
    top      = "left",
    left     = "top",
    bottom   = "right",
    right    = "bottom",
    centered = "centered"
}

--- If the wibar needs to be stretched to fill the screen.
--
-- 
--
--![Usage example](../images/AUTOGEN_awful_wibar_stretch.svg)
--
-- @usage
-- awful.wibar {
--     position = &#34top&#34,
--     screen   = screen[1],
--     stretch  = true,
--     width    = 196,
--     widget   = {
--         text   = &#34stretched&#34,
--         align  = &#34center&#34,
--         widget = wibox.widget.textbox
--     },
-- }
--  
-- awful.wibar {
--     position = &#34top&#34,
--     screen   = screen[2],
--     stretch  = false,
--     width    = 196,
--     widget   = {
--         text   = &#34not stretched&#34,
--         align  = &#34center&#34,
--         widget = wibox.widget.textbox
--     },
-- }
--
-- @property stretch
-- @tparam boolean stretch
-- @propbeautiful
-- @propemits true false
-- @see align

--- How to align non-stretched wibars.
--
-- Values are:
--
--  * `"top"`
--  * `"bottom"`
--  * `"left"`
--  * `"right"`
--  * `"centered"`
--
--  
--
--![Usage example](../images/AUTOGEN_awful_wibar_align.svg)
--
-- @usage
-- for s, align in ipairs { &#34left&#34, &#34centered&#34, &#34right&#34 } do
--     awful.wibar {
--         position = &#34top&#34,
--         screen   = screen[s],
--         stretch  = false,
--         width    = 196,
--         align    = align,
--         widget   = {
--             text   = align,
--             align  = &#34center&#34,
--             widget = wibox.widget.textbox
--         },
--     }
-- end
--  
-- for s, align in ipairs { &#34top&#34, &#34centered&#34, &#34bottom&#34 } do
--     awful.wibar {
--         position = &#34left&#34,
--         screen   = screen[s+3],
--         stretch  = false,
--         height   = 128,
--         align    = align,
--         widget   = {
--             {
--                 text   = align,
--                 align  = &#34center&#34,
--                 widget = wibox.widget.textbox
--             },
--             direction = &#34east&#34,
--             widget    = wibox.container.rotate
--         },
--     }
-- end
--
-- @property align
-- @tparam string align
-- @propbeautiful
-- @propemits true false
-- @see stretch

--- Margins on each side of the wibar.
--
-- It can either be a table with `top`, `bottom`, `left` and `right`
-- properties, or a single number that applies to all four sides.
--
-- 
--
--![Usage example](../images/AUTOGEN_awful_wibar_margins.svg)
--
-- @usage
-- awful.wibar {
--     position = &#34top&#34,
--     screen   = screen[1],
--     stretch  = false,
--     width    = 196,
--     margins  = 24,
--     widget   = {
--         align  = &#34center&#34,
--         text   = &#34unform margins&#34,
--         widget = wibox.widget.textbox
--     }
-- }
--  
-- awful.wibar {
--     position = &#34top&#34,
--     screen   = screen[2],
--     stretch  = false,
--     width    = 196,
--     margins = {
--         top    = 12,
--         bottom = 5
--     },
--     widget   = {
--         align  = &#34center&#34,
--         text   = &#34non unform margins&#34,
--         widget = wibox.widget.textbox
--     }
-- }
--
-- @property margins
-- @tparam number|table margins
-- @propbeautiful
-- @propemits true false

--- If the wibar needs to be stretched to fill the screen.
--
-- @beautiful beautiful.wibar_stretch
-- @tparam boolean stretch

--- Allow or deny the tiled clients to cover the wibar.
--
-- In the example below, we can see that the first screen workarea
-- shrunk by the height of the wibar while the second screen is
-- unchanged.
--
-- 
--
--![Usage example](../images/AUTOGEN_screen_wibar_workarea.svg)
--
-- @usage
-- local screen1_wibar = awful.wibar {
--     position          = &#34top&#34,
--     restrict_workarea = true,
--     height            = 24,
--     screen            = screen[1],
-- }
--  
-- local screen2_wibar = awful.wibar {
--     position          = &#34top&#34,
--     restrict_workarea = false,
--     height            = 24,
--     screen            = screen[2],
-- }
--
-- @property restrict_workarea
-- @tparam[opt=true] boolean restrict_workarea
-- @propemits true false
-- @see client.struts
-- @see screen.workarea

--- If there is both vertical and horizontal wibar, give more space to vertical ones.
--
-- By default, if multiple wibars risk overlapping, it will be resolved
-- by giving more space to the horizontal one:
--
-- ![wibar position](../images/AUTOGEN_awful_wibar_position.svg)
--
-- If this variable is to to `true`, it will behave like:
--
-- 
--
--![Usage example](../images/AUTOGEN_awful_wibar_position2.svg)
--
--
-- @beautiful beautiful.wibar_favor_vertical
-- @tparam[opt=false] boolean favor_vertical

--- The wibar border width.
-- @beautiful beautiful.wibar_border_width
-- @tparam integer border_width

--- The wibar border color.
-- @beautiful beautiful.wibar_border_color
-- @tparam string border_color

--- If the wibar is to be on top of other windows.
-- @beautiful beautiful.wibar_ontop
-- @tparam boolean ontop

--- The wibar's mouse cursor.
-- @beautiful beautiful.wibar_cursor
-- @tparam string cursor

--- The wibar opacity, between 0 and 1.
-- @beautiful beautiful.wibar_opacity
-- @tparam number opacity

--- The window type (desktop, normal, dock, …).
-- @beautiful beautiful.wibar_type
-- @tparam string type

--- The wibar's width.
-- @beautiful beautiful.wibar_width
-- @tparam integer width

--- The wibar's height.
-- @beautiful beautiful.wibar_height
-- @tparam integer height

--- The wibar's background color.
-- @beautiful beautiful.wibar_bg
-- @tparam color bg

--- The wibar's background image.
-- @beautiful beautiful.wibar_bgimage
-- @tparam surface bgimage

--- The wibar's foreground (text) color.
-- @beautiful beautiful.wibar_fg
-- @tparam color fg

--- The wibar's shape.
-- @beautiful beautiful.wibar_shape
-- @tparam gears.shape shape

--- The wibar's margins.
-- @beautiful beautiful.wibar_margins
-- @tparam number|table margins

--- The wibar's alignments.
-- @beautiful beautiful.wibar_align
-- @tparam string align


-- Compute the margin on one side
local function get_margin(w, position, auto_stop)
    local h_or_w = (position == "top" or position == "bottom") and "height" or "width"
    local ret = 0

    for _, v in ipairs(wiboxes) do
        -- Ignore the wibars placed after this one
        if auto_stop and v == w then break end

        if v.position == position and v.screen == w.screen and v.visible then
            ret = ret + v[h_or_w]

            local wb_margins = v.margins

            if wb_margins then
                ret = ret + wb_margins[position] + wb_margins[opposite_margin[position]]
            end

        end

    end

    return ret
end

-- `honor_workarea` cannot be used as it does modify the workarea itself.
-- a manual padding has to be generated.
local function get_margins(w)
    local position = w.position
    assert(position)

    local margins = gtable.clone(w._private.margins)

    margins[position] =  margins[position] + get_margin(w, position, true)

    -- Avoid overlapping wibars
    if (position == "left" or position == "right") and not beautiful.wibar_favor_vertical then
        margins.top    = get_margin(w, "top"   )
        margins.bottom = get_margin(w, "bottom")
    elseif (position == "top" or position == "bottom") and beautiful.wibar_favor_vertical then
        margins.left  = get_margin(w, "left" )
        margins.right = get_margin(w, "right")
    end

    return margins
end

-- Create the placement function
local function gen_placement(position, align, stretch)
    local maximize = (position == "right" or position == "left") and
        "maximize_vertically" or "maximize_horizontally"

    local corner = nil

    if align ~= "centered" then
        if position == "right" or position == "left" then
            corner = placement[align .. "_" .. position]
                or placement[align_map[align] .. "_" .. position]
        else
            corner = placement[position .. "_" .. align]
                or placement[position .. "_" .. align_map[align]]
        end
    end

    corner = corner or placement[position]

    return corner + (stretch and placement[maximize] or nil)
end

-- Attach the placement function.
local function attach(wb, position)
    gen_placement(position, wb._private.align, wb._stretch)(wb, {
        attach          = true,
        update_workarea = wb._private.restrict_workarea,
        margins         = get_margins(wb)
    })
end

-- Re-attach all wibars on a given wibar screen
local function reattach(wb)
    local s = wb.screen
    for _, w in ipairs(wiboxes) do
        if w ~= wb and w.screen == s then
            if w.detach_callback then
                w.detach_callback()
                w.detach_callback = nil
            end
            attach(w, w.position)
        end
    end
end

--- The wibox position.
--
-- The valid values are:
--
-- * left
-- * right
-- * top
-- * bottom
--
-- 
--
--![Usage example](../images/AUTOGEN_awful_wibar_position.svg)
--
-- 
--    local colors = {
--        top    = &#34#ffff00&#34,
--        bottom = &#34#ff00ff&#34,
--        left   = &#34#00ffff&#34,
--        right  = &#34#ffcc00&#34
--    }
--     
--    for _, position in ipairs { &#34top&#34, &#34bottom&#34, &#34left&#34, &#34right&#34 } do
--        awful.wibar {
--            position = position,
--            bg       = colors[position],
--            widget   = {
--                {
--                    text   = position,
--                    align  = &#34center&#34,
--                    widget = wibox.widget.textbox
--                },
--                direction = (position == &#34left&#34 or position == &#34right&#34) and
--                    &#34east&#34 or &#34north&#34,
--                widget    = wibox.container.rotate
--            },
--        }
--    end
--
-- @property position
-- @tparam string position Either "left", right", "top" or "bottom"
-- @propemits true false

function awfulwibar.get_position(wb)
    return wb._position or "top"
end

function awfulwibar.set_position(wb, position, screen)
    if position == wb._position then return end

    if screen then
        gdebug.deprecate("Use `wb.screen = screen` instead of awful.wibar.set_position", {deprecated_in=4})
    end

    -- Detach first to avoid any unneeded callbacks
    if wb.detach_callback then
        wb.detach_callback()

        -- Avoid disconnecting twice, this produces a lot of warnings
        wb.detach_callback = nil
    end

    -- Move the wibar to the end of the list to avoid messing up the others in
    -- case there is stacked wibars on one side.
    for k, w in ipairs(wiboxes) do
        if w == wb then
            table.remove(wiboxes, k)
        end
    end
    table.insert(wiboxes, wb)

    -- In case the position changed, it may be necessary to reset the size
    if (wb._position == "left" or wb._position == "right")
      and (position == "top" or position == "bottom") then
        wb.height = math.ceil(beautiful.get_font_height(wb.font) * 1.5)
    elseif (wb._position == "top" or wb._position == "bottom")
      and (position == "left" or position == "right") then
        wb.width = math.ceil(beautiful.get_font_height(wb.font) * 1.5)
    end

    -- Set the new position
    wb._position = position

    -- Attach to the new position
    attach(wb, position)

    -- A way to skip reattach is required when first adding a wibar as it's not
    -- in the `wiboxes` table yet and can't be added until it's attached.
    if not wb._private.skip_reattach then
        -- Changing the position will also cause the other margins to be invalidated.
        -- For example, adding a wibar to the top will change the margins of any left
        -- or right wibars. To solve, this, they need to be re-attached.
        reattach(wb)
    end

    wb:emit_signal("property::position", position)
end

function awfulwibar.get_stretch(w)
    return w._stretch
end

function awfulwibar.set_stretch(w, value)
    w._stretch = value

    attach(w, w.position)

    w:emit_signal("property::stretch", value)
end


function awfulwibar.get_restrict_workarea(w)
    return w._private.restrict_workarea
end

function awfulwibar.set_restrict_workarea(w, value)
    w._private.restrict_workarea = value

    attach(w, w.position)

    w:emit_signal("property::restrict_workarea", value)
end


function awfulwibar.set_margins(w, value)
    if type(value) == "number" then
        value = {
            top = value,
            bottom = value,
            right = value,
            left = value,
        }
    end

    local old = gtable.crush({
        left   = 0,
        right  = 0,
        top    = 0,
        bottom = 0
    }, w._private.margins or {}, true)

   value = gtable.crush(old, value or {}, true)

    w._private.margins = value

    attach(w, w.position)

    w:emit_signal("property::margins", value)
end

-- Allow each margins to be set individually.
local function meta_margins(self)
    return setmetatable({}, {
        __index = self._private.margins,
        __newindex = function(_, k, v)
            self._private.margins[k] = v
            awfulwibar.set_margins(self, self._private.margins)
        end
    })
end

function awfulwibar.get_margins(self)
    return self._private.meta_margins
end


function awfulwibar.get_align(self)
    return self._private.align
end

function awfulwibar.set_align(self, value, screen)
    if value == "center" then
        gdebug.deprecate("awful.wibar.align(wb, 'center' is deprecated, use 'centered'", {deprecated_in=4})
        value = "centered"
    end

    if screen then
        gdebug.deprecate("awful.wibar.align 'screen' argument is deprecated", {deprecated_in=4})
    end

    assert(align_map[value])

    self._private.align = value

    attach(self, self.position)

    self:emit_signal("property::align", value)
end

--- Remove a wibar.
-- @method remove

function awfulwibar.remove(self)
    self.visible = false

    if self.detach_callback then
        self.detach_callback()
        self.detach_callback = nil
    end

    for k, w in ipairs(wiboxes) do
        if w == self then
            table.remove(wiboxes, k)
        end
    end

    self._screen = nil
end

--- Attach a wibox to a screen.
--
-- This function has been moved to the `awful.placement` module. Calling this
-- no longer does anything.
--
-- @param wb The wibox to attach.
-- @param position The position of the wibox: top, bottom, left or right.
-- @param screen The screen to attach to
-- @see awful.placement
-- @deprecated awful.wibar.attach
local function legacy_attach(wb, position, screen) --luacheck: no unused args
    gdebug.deprecate("awful.wibar.attach is deprecated, use the 'attach' property"..
        " of awful.placement. This method doesn't do anything anymore",
        {deprecated_in=4}
    )
end

--- Align a wibox.
--
-- Supported alignment are:
--
-- * top_left
-- * top_right
-- * bottom_left
-- * bottom_right
-- * left
-- * right
-- * top
-- * bottom
-- * centered
-- * center_vertical
-- * center_horizontal
--
-- @param wb The wibox.
-- @param align The alignment
-- @param screen This argument is deprecated. It is not used. Use wb.screen
--  directly.
-- @deprecated awful.wibar.align
-- @see awful.placement.align
local function legacy_align(wb, align, screen) --luacheck: no unused args
    if align == "center" then
        gdebug.deprecate("awful.wibar.align(wb, 'center' is deprecated, use 'centered'", {deprecated_in=4})
        align = "centered"
    end

    if screen then
        gdebug.deprecate("awful.wibar.align 'screen' argument is deprecated", {deprecated_in=4})
    end

    if placement[align] then
        return placement[align](wb)
    end
end

--- Stretch a wibox so it takes all screen width or height.
--
-- **This function has been removed.**
--
-- @deprecated awful.wibox.stretch
-- @see awful.placement
-- @see awful.wibar.stretch

--- Create a new wibox and attach it to a screen edge.
-- You can add also position key with value top, bottom, left or right.
-- You can also use width or height in % and set align to center, right or left.
-- You can also set the screen key with a screen number to attach the wibox.
-- If not specified, the primary screen is assumed.
-- @see wibox
-- @tparam[opt=nil] table args
-- @tparam string args.position The position.
-- @tparam string args.stretch If the wibar need to be stretched to fill the screen.
-- @tparam boolean args.restrict_workarea Allow or deny the tiled clients to cover the wibar.
-- @tparam string args.align How to align non-stretched wibars.
-- @tparam table|number args.margins The wibar margins.
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
-- @return The new wibar
-- @constructorfct awful.wibar
function awfulwibar.new(args)
    args = args or {}
    local position = args.position or "top"
    local has_to_stretch = true
    local screen = get_screen(args.screen or 1)

    args.type = args.type or "dock"

    if position ~= "top" and position ~="bottom"
            and position ~= "left" and position ~= "right" then
        error("Invalid position in awful.wibar(), you may only use"
            .. " 'top', 'bottom', 'left' and 'right'")
    end

    -- Set default size
    if position == "left" or position == "right" then
        args.width = args.width or beautiful["wibar_width"]
            or math.ceil(beautiful.get_font_height(args.font) * 1.5)
        if args.height then
            has_to_stretch = false
            if args.screen then
                local hp = tostring(args.height):match("(%d+)%%")
                if hp then
                    args.height = math.ceil(screen.geometry.height * hp / 100)
                end
            end
        end
    else
        args.height = args.height or beautiful["wibar_height"]
            or math.ceil(beautiful.get_font_height(args.font) * 1.5)
        if args.width then
            has_to_stretch = false
            if args.screen then
                local wp = tostring(args.width):match("(%d+)%%")
                if wp then
                    args.width = math.ceil(screen.geometry.width * wp / 100)
                end
            end
        end
    end

    args.screen = nil

    -- The C code scans the table directly, so metatable magic cannot be used.
    for _, prop in ipairs {
        "border_width", "border_color", "font", "opacity", "ontop", "cursor",
        "bgimage", "bg", "fg", "type", "stretch", "shape", "margins", "align"
    } do
        if (args[prop] == nil) and beautiful["wibar_"..prop] ~= nil then
            args[prop] = beautiful["wibar_"..prop]
        end
    end

    local w = wibox(args)

    w._private.align = (args.align and align_map[args.align]) and args.align or "centered"

    w._private.margins = {
        left   = 0,
        right  = 0,
        top    = 0,
        bottom = 0
    }
    w._private.meta_margins = meta_margins(w)

    w._private.restrict_workarea = true

    -- `w` needs to be inserted in `wiboxes` before reattach or its own offset
    -- will not be taken into account by the "older" wibars when `reattach` is
    -- called. `skip_reattach` is required.
    w._private.skip_reattach = true


    w.screen   = screen
    w._screen  = screen --HACK When a screen is removed, then getbycoords won't work
    w._stretch = args.stretch == nil and has_to_stretch or args.stretch

    if args.visible == nil then w.visible = true end

    gtable.crush(w, awfulwibar, true)
    gtable.crush(w, args, false)

    -- Now, let set_position behave normally.
    w._private.skip_reattach = false

    awfulwibar.set_margins(w, args.margins)

    -- Force all the wibars to be moved
    reattach(w)

    w:connect_signal("property::visible", function() reattach(w) end)

    assert(w.buttons)

    return w
end

capi.screen.connect_signal("removed", function(s)
    local wibars = {}
    for _, wibar in ipairs(wiboxes) do
        if wibar._screen == s then
            table.insert(wibars, wibar)
        end
    end
    for _, wibar in ipairs(wibars) do
        wibar:remove()
    end
end)

function awfulwibar.mt:__call(...)
    return awfulwibar.new(...)
end

function awfulwibar.mt:__index(_, k)
    if k == "align" then
        return legacy_align
    elseif k == "attach" then
        return legacy_attach
    end
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

return setmetatable(awfulwibar, awfulwibar.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
