---------------------------------------------------------------------------
--- A progressbar widget.
--
-- To add text on top of the progressbar, a `wibox.layout.stack` can be used:
--
--
--
--![Usage example](../images/AUTOGEN_wibox_widget_progressbar_text.svg)
--
-- 
--     wibox.widget {
--         {
--             max_value     = 1,
--             value         = 0.5,
--             forced_height = 20,
--             forced_width  = 100,
--             paddings      = 1,
--             border_width  = 1,
--             border_color  = beautiful.border_color,
--             widget        = wibox.widget.progressbar,
--         },
--         {
--             text   = &#3450%&#34,
--             widget = wibox.widget.textbox,
--         },
--         layout = wibox.layout.stack
--     }
--
-- To display the progressbar vertically, use a `wibox.container.rotate` widget:
--
--
--
--![Usage example](../images/AUTOGEN_wibox_widget_progressbar_vertical.svg)
--
-- 
--     wibox.widget {
--         {
--             max_value     = 1,
--             value         = 0.33,
--             widget        = wibox.widget.progressbar,
--         },
--         forced_height = 100,
--         forced_width  = 20,
--         direction     = &#34east&#34,
--         layout        = wibox.container.rotate,
--     }
--
-- By default, this widget will take all the available size. To prevent this,
-- a `wibox.container.constraint` widget or the `forced_width`/`forced_height`
-- properties have to be used.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_widget_defaults_progressbar.svg)
--
-- @usage
-- wibox.widget {
--     max_value     = 1,
--     value         = 0.33,
--     forced_height = 20,
--     forced_width  = 100,
--     shape         = gears.shape.rounded_bar,
--     border_width  = 2,
--     border_color  = beautiful.border_color,
--     widget        = wibox.widget.progressbar,
-- }
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @widgetmod wibox.widget.progressbar
-- @supermodule wibox.widget.base
---------------------------------------------------------------------------

local setmetatable = setmetatable
local ipairs = ipairs
local math = math
local gdebug =  require("gears.debug")
local base = require("wibox.widget.base")
local color = require("gears.color")
local beautiful = require("beautiful")
local shape = require("gears.shape")
local gtable = require("gears.table")

local progressbar = { mt = {} }

--- The progressbar border color.
--
-- If the value is nil, no border will be drawn.
--
-- @property border_color
-- @tparam color color The border color to set.
-- @propemits true false
-- @propbeautiful
-- @see gears.color

--- The progressbar border width.
--
-- @property border_width
-- @tparam number border_width
-- @propemits true false
-- @propbeautiful

--- The progressbar inner border color.
--
-- If the value is nil, no border will be drawn.
--
-- @property bar_border_color
-- @tparam color color The border color to set.
-- @propemits true false
-- @propbeautiful
-- @see gears.color

--- The progressbar inner border width.
--
-- @property bar_border_width
-- @tparam number bar_border_width
-- @propbeautiful
-- @propemits true false

--- The progressbar foreground color.
--
-- @property color
-- @tparam color color The progressbar color.
-- @propemits true false
-- @usebeautiful beautiful.progressbar_fg
-- @see gears.color

--- The progressbar background color.
--
-- @property background_color
-- @tparam color color The progressbar background color.
-- @propemits true false
-- @usebeautiful beautiful.progressbar_bg
-- @see gears.color

--- The progressbar inner shape.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_widget_progressbar_bar_shape.svg)
--
-- @usage
-- for _, shape in ipairs {&#34rounded_bar&#34, &#34octogon&#34, &#34hexagon&#34, &#34powerline&#34 } do
--     l:add(wibox.widget {
--           value            = 0.33,
--           bar_shape        = gears.shape[shape],
--           bar_border_color = beautiful.border_color,
--           bar_border_width = 1,
--           border_width     = 2,
--           border_color     = beautiful.border_color,
--           paddings         = 1,
--           widget           = wibox.widget.progressbar,
--       })
-- end
--
-- @property bar_shape
-- @tparam[opt=gears.shape.rectangle] gears.shape shape
-- @propemits true false
-- @propbeautiful
-- @see gears.shape

--- The progressbar shape.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_widget_progressbar_shape.svg)
--
-- @usage
-- for _, shape in ipairs {&#34rounded_bar&#34, &#34octogon&#34, &#34hexagon&#34, &#34powerline&#34 } do
--     l:add(wibox.widget {
--           value         = 0.33,
--           shape         = gears.shape[shape],
--           border_width  = 2,
--           border_color  = beautiful.border_color,
--           widget        = wibox.widget.progressbar,
--       })
-- end
--
-- @property shape
-- @tparam[opt=gears.shape.rectangle] gears.shape shape
-- @propemits true false
-- @propbeautiful
-- @see gears.shape

--- Set the progressbar to draw vertically.
--
-- This doesn't do anything anymore, use a `wibox.container.rotate` widget.
--
-- @deprecated set_vertical
-- @tparam boolean vertical
-- @deprecatedin 4.0

--- Force the inner part (the bar) to fit in the background shape.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_widget_progressbar_clip.svg)
--
-- @usage
--     wibox.widget {
--         value            = 75,
--         max_value        = 100,
--         border_width     = 2,
--         border_color     = beautiful.border_color,
--         color            = beautiful.border_color,
--         shape            = gears.shape.rounded_bar,
--         bar_shape        = gears.shape.rounded_bar,
--         clip             = false,
--         forced_height    = 30,
--         forced_width     = 100,
--         paddings         = 5,
--         margins          = {
--             top    = 12,
--             bottom = 12,
--         },
--         widget = wibox.widget.progressbar,
--     }
--
-- @property clip
-- @tparam[opt=true] boolean clip
-- @propemits true false

--- The progressbar to draw ticks. Default is false.
--
-- @property ticks
-- @tparam boolean ticks
-- @propemits true false

--- The progressbar ticks gap.
--
-- @property ticks_gap
-- @tparam number ticks_gap
-- @propemits true false

--- The progressbar ticks size.
--
-- @property ticks_size
-- @tparam number ticks_size
-- @propemits true false

--- The maximum value the progressbar should handle.
--
-- @property max_value
-- @tparam number max_value
-- @propemits true false

--- The progressbar background color.
--
-- @beautiful beautiful.progressbar_bg
-- @param color

--- The progressbar foreground color.
--
-- @beautiful beautiful.progressbar_fg
-- @param color

--- The progressbar shape.
--
-- @beautiful beautiful.progressbar_shape
-- @tparam gears.shape shape
-- @see gears.shape

--- The progressbar border color.
--
-- @beautiful beautiful.progressbar_border_color
-- @param color

--- The progressbar outer border width.
--
-- @beautiful beautiful.progressbar_border_width
-- @param number

--- The progressbar inner shape.
--
-- @beautiful beautiful.progressbar_bar_shape
-- @tparam gears.shape shape
-- @see gears.shape

--- The progressbar bar border width.
--
-- @beautiful beautiful.progressbar_bar_border_width
-- @param number

--- The progressbar bar border color.
--
-- @beautiful beautiful.progressbar_bar_border_color
-- @param color

--- The progressbar margins.
--
-- Note that if the `clip` is disabled, this allows the background to be smaller
-- than the bar.
--
-- See the `clip` example.
--
-- @property margins
-- @tparam[opt=0] (table|number|nil) margins A table for each side or a number
-- @tparam[opt=0] number margins.top
-- @tparam[opt=0] number margins.bottom
-- @tparam[opt=0] number margins.left
-- @tparam[opt=0] number margins.right
-- @propemits false false
-- @propbeautiful
-- @see clip

--- The progressbar padding.
--
-- Note that if the `clip` is disabled, this allows the bar to be taller
-- than the background.
--
-- See the `clip` example.
--
-- @property paddings
-- @tparam[opt=0] (table|number|nil) padding A table for each side or a number
-- @tparam[opt=0] number padding.top
-- @tparam[opt=0] number padding.bottom
-- @tparam[opt=0] number padding.left
-- @tparam[opt=0] number padding.right
-- @propemits false false
-- @propbeautiful
-- @see clip

--- The progressbar margins.
--
-- Note that if the `clip` is disabled, this allows the background to be smaller
-- than the bar.
-- @tparam[opt=0] (table|number|nil) margins A table for each side or a number
-- @tparam[opt=0] number margins.top
-- @tparam[opt=0] number margins.bottom
-- @tparam[opt=0] number margins.left
-- @tparam[opt=0] number margins.right
-- @beautiful beautiful.progressbar_margins
-- @see clip

--- The progressbar padding.
--
-- Note that if the `clip` is disabled, this allows the bar to be taller
-- than the background.
-- @tparam[opt=0] (table|number|nil) padding A table for each side or a number
-- @tparam[opt=0] number padding.top
-- @tparam[opt=0] number padding.bottom
-- @tparam[opt=0] number padding.left
-- @tparam[opt=0] number padding.right
-- @beautiful beautiful.progressbar_paddings
-- @see clip

local properties = { "border_color", "color"     , "background_color",
                     "value"       , "max_value" , "ticks",
                     "ticks_gap"   , "ticks_size", "border_width",
                     "shape"       , "bar_shape" , "bar_border_width",
                     "clip"        , "margins"   , "bar_border_color",
                     "paddings",
                   }

function progressbar.draw(pbar, _, cr, width, height)
    local ticks_gap = pbar._private.ticks_gap or 1
    local ticks_size = pbar._private.ticks_size or 4

    -- We want one pixel wide lines
    cr:set_line_width(1)

    local max_value = pbar._private.max_value

    local value = math.min(max_value, math.max(0, pbar._private.value))

    if value >= 0 then
        value = value / max_value
    end
    local border_width = pbar._private.border_width
        or beautiful.progressbar_border_width or 0

    local bcol = pbar._private.border_color or beautiful.progressbar_border_color

    border_width = bcol and border_width or 0

    local bg = pbar._private.background_color or
        beautiful.progressbar_bg or "#ff0000aa"

    local bg_width, bg_height = width, height

    local clip = pbar._private.clip ~= false and beautiful.progressbar_clip ~= false

    -- Apply the margins
    local margin = pbar._private.margins or beautiful.progressbar_margins

    if margin then
        if type(margin) == "number" then
            cr:translate(margin, margin)
            bg_width, bg_height = bg_width - 2*margin, bg_height - 2*margin
        else
            cr:translate(margin.left or 0, margin.top or 0)
            bg_height = bg_height -
                (margin.top  or 0) - (margin.bottom or 0)
            bg_width = bg_width   -
                (margin.left or 0) - (margin.right  or 0)
        end
    end

    -- Draw the background shape
    if border_width > 0 then
        -- Cairo draw half of the border outside of the path area
        cr:translate(border_width/2, border_width/2)
        bg_width, bg_height = bg_width - border_width, bg_height - border_width
        cr:set_line_width(border_width)
    end

    local background_shape = pbar._private.shape or
        beautiful.progressbar_shape or shape.rectangle

    background_shape(cr, bg_width, bg_height)

    cr:set_source(color(bg))

    local over_drawn_width  = bg_width  + border_width
    local over_drawn_height = bg_height + border_width

    if border_width > 0 then
        cr:fill_preserve()

        -- Draw the border
        cr:set_source(color(bcol))

        cr:stroke()

        over_drawn_width  = over_drawn_width  - 2*border_width
        over_drawn_height = over_drawn_height - 2*border_width
    else
        cr:fill()
    end

    -- Undo the translation
    cr:translate(-border_width/2, -border_width/2)

    -- Make sure the bar stay in the shape
    if clip then
        background_shape(cr, bg_width, bg_height)
        cr:clip()
        cr:translate(border_width, border_width)
    else
        -- Assume the background size is irrelevant to the bar itself
        if type(margin) == "number" then
            cr:translate(-margin, -margin)
        else
            cr:translate(-(margin.left or 0), -(margin.top or 0))
        end

        over_drawn_height = height
        over_drawn_width  = width
    end

    -- Apply the padding
    local padding = pbar._private.paddings or beautiful.progressbar_paddings

    if padding then
        if type(padding) == "number" then
            cr:translate(padding, padding)
            over_drawn_height = over_drawn_height - 2*padding
            over_drawn_width  = over_drawn_width  - 2*padding
        else
            cr:translate(padding.left or 0, padding.top or 0)

            over_drawn_height = over_drawn_height -
                (padding.top  or 0) - (padding.bottom or 0)
            over_drawn_width = over_drawn_width   -
                (padding.left or 0) - (padding.right  or 0)
        end
    end

    over_drawn_width  = math.max(over_drawn_width , 0)
    over_drawn_height = math.max(over_drawn_height, 0)

    local rel_x = over_drawn_width * value


    -- Draw the progressbar shape

    local bar_shape = pbar._private.bar_shape or
        beautiful.progressbar_bar_shape or shape.rectangle

    local bar_border_width = pbar._private.bar_border_width or
        beautiful.progressbar_bar_border_width or pbar._private.border_width or
        beautiful.progressbar_border_width or 0

    local bar_border_color = pbar._private.bar_border_color or
        beautiful.progressbar_bar_border_color

    bar_border_width = bar_border_color and bar_border_width or 0

    over_drawn_width  = over_drawn_width  - bar_border_width
    over_drawn_height = over_drawn_height - bar_border_width
    cr:translate(bar_border_width/2, bar_border_width/2)

    bar_shape(cr, rel_x, over_drawn_height)

    cr:set_source(color(pbar._private.color or beautiful.progressbar_fg or "#ff0000"))

    if bar_border_width > 0 then
        cr:fill_preserve()
        cr:set_source(color(bar_border_color))
        cr:set_line_width(bar_border_width)
        cr:stroke()
    else
        cr:fill()
    end

    if pbar._private.ticks then
        for i=0, width / (ticks_size+ticks_gap)-border_width do
            local rel_offset = over_drawn_width / 1 - (ticks_size+ticks_gap) * i

            if rel_offset <= rel_x then
                cr:rectangle(rel_offset,
                                border_width,
                                ticks_gap,
                                over_drawn_height)
            end
        end
        cr:set_source(color(pbar._private.background_color or "#000000aa"))
        cr:fill()
    end
end

function progressbar:fit(_, width, height)
    return width, height
end

--- Set the progressbar value.
--
-- @property value
-- @tparam number value The progress bar value between 0 and 1.
-- @propemits true false

function progressbar:set_value(value)
    value = value or 0

    self._private.value = value

    self:emit_signal("widget::redraw_needed")
    return self
end

function progressbar:set_max_value(max_value)

    self._private.max_value = max_value

    self:emit_signal("widget::redraw_needed")
end

--- Set the progressbar height.
--
-- This method is deprecated.  Use a `wibox.container.constraint` widget or
-- `forced_height`.
--
-- @tparam number height The height to set.
-- @deprecated set_height
-- @renamedin 4.0
function progressbar:set_height(height)
    gdebug.deprecate("Use a `wibox.container.constraint` widget or `forced_height`", {deprecated_in=4})
    self:set_forced_height(height)
end

--- Set the progressbar width.
--
-- This method is deprecated.  Use a `wibox.container.constraint` widget or
-- `forced_width`.
--
-- @tparam number width The width to set.
-- @deprecated set_width
-- @renamedin 4.0
function progressbar:set_width(width)
    gdebug.deprecate("Use a `wibox.container.constraint` widget or `forced_width`", {deprecated_in=4})
    self:set_forced_width(width)
end

-- Build properties function
for _, prop in ipairs(properties) do
    if not progressbar["set_" .. prop] then
        progressbar["set_" .. prop] = function(pbar, value)
            pbar._private[prop] = value
            pbar:emit_signal("widget::redraw_needed")
            pbar:emit_signal("property::"..prop, value)
            return pbar
        end
    end
    if not progressbar["get_"..prop] then
        progressbar["get_" .. prop] = function(pbar)
            return pbar._private[prop]
        end
    end
end

function progressbar:set_vertical(value) --luacheck: no unused_args
    gdebug.deprecate("Use a `wibox.container.rotate` widget", {deprecated_in=4})
end


--- Create a progressbar widget.
--
-- @tparam table args Standard widget() arguments. You should add width and
--  height constructor parameters to set progressbar geometry.
-- @tparam number args.width The width.
-- @tparam number args.height The height.
-- @treturn wibox.widget.progressbar A progressbar widget.
-- @constructorfct wibox.widget.progressbar
function progressbar.new(args)
    args = args or {}

    local pbar = base.make_widget(nil, nil, {
        enable_properties = true,
    })

    pbar._private.width     = args.width or 100
    pbar._private.height    = args.height or 20
    pbar._private.value     = 0
    pbar._private.max_value = 1

    gtable.crush(pbar, progressbar, true)

    return pbar
end

function progressbar.mt:__call(...)
    return progressbar.new(...)
end

return setmetatable(progressbar, progressbar.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
