# Macho - Universal Key Mapping Engine

Macho is a highly customizable, installation-free keyboard macro platform. It translates key inputs directly into designated text snippets or scripts using a simple, human-readable structural parsing layout language (`.macm`).

By default, the platform routes keyboard mappings to output the **ത** character layout.

## The `.macm` Custom Programming Language
Configurations use a dead-simple mapping pointer layout syntax:
```text
[KEY_NAME] => [OUTPUT_PAYLOAD]
```

### Supported Mapping Tokens:
- **Control Keys:** `LeftCtrl`, `RightCtrl`
- **Modifiers & Toggles:** `CapsLock`, `Space`, `Tab`, `Enter`, `Shift`, `Alt`, `Escape`, `Insert`, `Delete`
- **Function Keys:** `F1` through `F12`
- **Standard Alphanumerics:** Letters `A` to `Z` and Numbers `0` to `9`

### Live Layout Toggling
If you ever need to use the native function of a mapped key without killing the utility engine, press the mapped key followed immediately by the hashtag symbol (`#`). 
- **First Sequence:** `[Mapped Key]` then `#` $\rightarrow$ Disables mapping (normal key functions return).
- **Second Sequence:** `[Mapped Key]` then `#` $\rightarrow$ Re-enables the custom configuration payload.

## Launch Instructions
1. Right-click `macho.ps1` and select **Run with PowerShell**.
2. Write your custom parameters inside the textbox or click **Load File** to mount an external `.macm` configuration document.
3. Click **Apply Layout Configuration** to make the mapping profiles go live.

## Uninstallation
Run the included `uninstall.ps1` script to shut down all running utility layers from memory, then delete the folder from your computer.
