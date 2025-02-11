# 🖼️ PicVim

> ⚠️ **Note:** This project is still early in development, so it may be a bit buggy. If you find any bugs, please let me know!


PicVim is a Neovim plugin that allows you to view and interact with images directly in Neovim. It supports various image formats such as PNG, JPG, GIF, BMP, and more, offering basic functionality like zooming, rotating, and panning.

---

### Key Features:
- 🚀 **Quick Image Viewing:** View images directly in Neovim.
- 🔄 **Basic Image Interaction:** Zoom, rotate, and pan.
- 🌐 **Multi-format Support:** Works with PNG, JPG, GIF, BMP, and more.


## Demo


https://github.com/user-attachments/assets/b8279faa-4e91-4fda-880b-4d4d7cab117d


### ⚠️  Notes:
- 🔧 **Early Development:** This is a work in progress, so expect some bugs. Contributions are welcome!
- **Only support for kitty:** Only supports kitty graphics protocol (so should work with kitty and wezterm).


## 📖 Usage

To use PicVim, simply open an image file in Neovim and the image will be displayed in the buffer. You can interact with the image using the provided keybindings.


## ✨ Features

- View images in Neovim.
- Zoom in and out using keybindings.
- Rotate the image with configurable keybindings.
- Pan the image using arrow keys or specific keybindings.
- Automatically scale and adjust images for optimal viewing.
- Configure keybindings and image types to work with your liking.


## ⚙️  Installation

Use your prefferred package manager to install PicVim.


### Eg. Using lazy.nvim

If you use [lazy.nvim](https://github.com/folke/lazy.nvim), you can install PicVim by adding the following to your configuration:


```lua
{
    "Toprun123/PicVim",
    config = function()
        require'picvim'.setup()
    end,
},
```

## 🔧 Setup and Configuration

To configure the plugin, add the following to your init.lua or any other configuration file:
You can set custom keymaps using the `keymap` option.

```lua
require'picvim'.setup({
    filetypes = {                         -- Default filetypes
        "png",                            -- For now only these are supported:
        "jpg",                            -- >   PNG, JPG, JPEG, GIF, BMP
        "jpeg",
        "gif",                            -- No need to set these if you want to
        "bmp",                            -- support all of these image formats.
    }
    keymap = {                            -- Default keymaps
        move_left = { "<Left>", "h" },    -- Pan left
        move_right = { "<Right>", "l" },  -- Pan right
        move_down = { "<Down>", "j" },    -- Pan down
        move_up = { "<Up>", "k" },        -- Pan up
        zoom_in = { "=", "+" },           -- Zoom in
        zoom_out = { "-", "_" },          -- Zoom out
        rotate_clockwise = "t",           -- Rotate clockwise by 30 degrees
        rotate_counterclockwise = "T",    -- Rotate counterclockwise by 30 degrees
        reset = "o",                      -- Reset image
        rerender = "r",                   -- Rerender image
    }
})
```

## 🛠️ Autocommands

The plugin automatically activates for image files (.png, .jpg, .jpeg, .gif, .bmp) (configured in the `filetypes` option) upon opening. It sets the buffer to a "non-file" type to display the image correctly.

## ⌨️  Default Keymaps

| Options within `keymap`     | Default Value         | Description              |
|-----------------------------|-----------------------|--------------------------|
| `move_left`                 | `{"<Left>", "h"}`     | Moves the image left     |
| `move_right`                | `{"<Right>", "l"}`    | Moves the image right    |
| `move_down`                 | `{"<Down>", "j"}`     | Moves the image down     |
| `move_up`                   | `{"<Up>", "k"}`       | Moves the image up       |
| `zoom_in`                   | `{"=", "+"}`          | Zooms into the image     |
| `zoom_out`                  | `{"-", "_"}`          | Zooms out of the image   |
| `rotate_clockwise`          | `"t"`                 | Rotates clockwise        |
| `rotate_counterclockwise`   | `"T"`                 | Rotates counterclockwise |
| `reset`                     | `"o"`                 | Resets the image         |
| `rerender`                  | `"r"`                 | Rerenders the image      |

## Filetypes

Defaults to:
- `{ "png", "jpg", "jpeg", "gif", "bmp" }`

- You can set custom filetypes using the `filetypes` option.
    - The value must be a table of strings that includes the file extension for the image.
    - Filetypes not in the default list will not work (They'll be ignored).

## 📦 Dependencies

- `ImageMagick` for image manipulation.
- `Neovim` (Obviously).
- `Kitty` for displaying the image.

##  TODO:

- [x] Allow zooming image.
- [x] Allow panning across the image.
- [x] Support image rotation.
- [x] Add support for non-png raster images.
- [x] Make Keybinds configurable.
- [x] Add config for filetypes to work with.
- [ ] Add support for svg files.
- [ ] Add PDF viewer.
- [ ] Add support for gif animations.
- [ ] Expose functions to handle the images.

