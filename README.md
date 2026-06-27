<img width="2160" alt="Machologo" src="https://github.com/user-attachments/assets/4d6b63c0-5ff1-4439-ab12-eb3795171703" />
# Macho - Universal Key Mapping Engine

Macho is a lightweight, local, installation-free keyboard customization platform. It allows users to write simple, human-readable logic profiles via its own custom scripting language extension (.macm) and map any physical key on their keyboard to output custom text sequences or launch websites.

The application natively defaults to routing keys to output the ത character icon layout.

---

## The .macm Scripting Language Tutorial

Writing configuration profiles in the Macho layout language is straightforward. The file structure utilizes a clear key-to-payload association syntax model:

```text
[PHYSICAL_KEY] => [YOUR_TARGET_PAYLOAD]
```

### Rule 1: Custom Text Output
To make a key type text instantly whenever you press it, specify the token, add the assignment arrow (=>), and provide your text payload.
```text
LeftCtrl => ത
CapsLock => hello.world@domain.com
F12      => Dynamic Macro Triggered!
```

### Rule 2: Web Forwarding Macros
If your target payload string starts with http:// or https://, Macho automatically intercepts the keypress and opens that web link inside your system's default browser window instead of typing text.
```text
RightCtrl => https://github.com
F1        => https://google.com
```

### Rule 3: Comments & Space Buffers
You can leave developer notes or organize your code using the hashtag symbol (#) at the very beginning of any line. The compiler engine will safely ignore these lines.
```text
# This profile maps my utility deck
LeftCtrl => ത
```

### Reference Table: Mappable Keys
Type these exact tokens on the left side of the => separator inside your .macm documents:
* System Modifiers: LeftCtrl, RightCtrl, CapsLock, Shift, Alt, Space, Tab, Enter, Escape, Insert, Delete
* Function Keys: F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12
* Alphanumerics: Capital letters A through Z and numbers 0 through 9

---

## Operational Guide

### Live Layout Toggling (The Hashtag Switch)
If you need to briefly use the normal, native function of a mapped key without closing the application, use the live memory toggle:
1. Press your active mapped key once.
2. Press the # (Hashtag) key immediately after.
3. Result: The parsing hook goes dormant, restoring standard key behaviors. Repeating this identical loop re-enables your .macm mapping payload layer.

### Launch Instructions
1. Right-click macho.ps1 and select Run with PowerShell.
2. Type or paste your structural parameters into the integrated configuration UI workspace, or press Load File to import an existing .macm profile.
3. Click Apply Layout Configuration to make your modifications active.

### Compiling into a Hidden Background EXE
To run Macho silently as a true native program with all background PowerShell command line console boxes completely invisible:
1. Right-click build-exe.ps1 and choose Run with PowerShell.
2. A standalone program called MachoApp.exe will compile into your folder layout.
3. Launch MachoApp.exe directly to run your configuration seamlessly.

### Uninstallation
Run uninstall.ps1 via PowerShell to break the hook and clear the processes from system RAM, then delete the folder from your storage workspace.
