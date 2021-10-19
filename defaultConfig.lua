return {
    palette = {
        default = "src/palette/duel-1x.png"
    },
    color = {
        text_default = {255, 255, 255},
        text_alt = {200, 200, 200},
        background_global = {32, 32, 32},
        background_alt = {20, 20, 20},
        editor_cursor_color = {20, 126, 255},
        debug_text = {255, 0, 255},
        debug_background = {0, 0, 0, 100},
        selection = {255, 0, 255},
        mirror = {91, 156, 222},
        prompt_shade = {0, 0, 0, 255}
    },
    font = {
        file = "src/font/monogram.ttf"
    },
    keys = {
        cursor_left = "left",
        cursor_right = "right",
        cursor_up = "up",
        cursor_down = "down",
        cursor_draw = "d",
        cursor_erase = "x",
        cursor_fill = "f",
        cursor_pick = "t",
        cursor_jump = "lshift",

        zoom_in = "zup",
        zoom_out = "zdown",

        cursor_line_left = "wdleft",
        cursor_line_right = "wdright",
        cursor_line_up = "wdup",
        cursor_line_down = "wddown",
        
        cursor_line_color_left = "dcleft",
        cursor_line_color_right = "dcright",
        cursor_line_color_up = "dcup",
        cursor_line_color_down = "dcdown",

        cursor_warp_left = "wwleft",
        cursor_warp_down = "wwdown",
        cursor_warp_up = "wwup",
        cursor_warp_right = "wwright",

        cursor_warp_color_left = "wcleft",
        cursor_warp_color_right = "wcright",
        cursor_warp_color_up = "wcup",
        cursor_warp_color_down = "wcdown",

        horizontal_mirror = "mh",
        vertical_mirror = "mv",
        clear_mirror = "mm",
        
        toggle_command_box = "tab",
        select_mode = "s",
        copy_mode = "g",
        cut_mode = "lshiftg",
        toggle_grid = "f1",
        toggle_fullscreen = "f2",
        select_palette_color = "cc",
        move_palette_cursor = "lctrl",
        undo = "u",
        redo = "y"
    },
    settings = {
        use_history = true,
        max_undo_steps = 100,

        jump_length = 10,
        
        command_timeout = 0.3,

        default_mode = "drawMode",
        editor_border_width = 4,
        empty_pixel = {0, 0, 0, 0},
        
        show_grid = false,
        debug = false,

        max_palette_columns = 8,
        max_palette_rows = 32,
        
        window_width = 800,
        window_height = 600,
        window_fullscreen = false,
        window_resizable = true,
        file_drop_action = "region" -- prompt, region, image, palette
    }
}