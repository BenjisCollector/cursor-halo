# Cursor Halo

![icon](assets/icon.png)

A glowing halo that follows your mouse cursor on Windows 10/11. Set size, opacity, colour, and filled or ring style from a small settings window.

![preview](assets/preview.png)

## Download
https://github.com/BenjisCollector/cursor-halo/releases/download/latest/CursorHalo.exe

Double-click to run. If SmartScreen warns, click **More info > Run anyway** (the exe is unsigned). Close the settings window to quit. Settings are saved in `%APPDATA%\CursorHalo\settings.json`.

## Recording with OBS
- **Display Capture:** works with the normal halo.
- **Window Capture:** OBS only captures the chosen window, so a separate halo window is never included. Tick **OBS mode** in Cursor Halo. It draws the halo (and optionally a cursor arrow) in one transparent full-desktop window. In OBS: *Add source > Window Capture > "[CursorHalo.exe]: Cursor Halo Overlay (OBS)"*, set Capture Method to *Windows 10 (1903 and up)*, and put it above your video. It covers the whole desktop, so for a single-window recording line it up with that window and use a Crop filter.
