# ==============================================================================
# MACHO - The Universal Custom-Language Key Mapper Application
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- Core Universal Keyboard Hook Engine (C# Win32 API) ---
$Source = @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Collections.Generic;

public class MachoEngine {
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")]
    private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);

    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const uint KEYEVENTF_KEYUP = 0x0002;
    
    private static LowLevelKeyboardProc _proc = HookCallback;
    public static IntPtr _hookID = IntPtr.Zero;
    
    // Virtual Key Code to Unicode Output dictionary
    public static Dictionary<int, string> KeyMap = new Dictionary<int, string>();
    private static bool _isEnabled = true;
    private static bool _lastKeyWasMapped = false;

    public static void Start() { if (_hookID == IntPtr.Zero) _hookID = SetHook(_proc); }
    public static void Stop() { if (_hookID != IntPtr.Zero) { UnhookWindowsHookEx(_hookID); _hookID = IntPtr.Zero; } }

    private static IntPtr SetHook(LowLevelKeyboardProc proc) {
        using (var curProcess = System.Diagnostics.Process.GetCurrentProcess())
        using (var curModule = curProcess.MainModule) {
            return SetWindowsHookEx(WH_KEYBOARD_LL, proc, IntPtr.Zero, 0);
        }
    }

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    // Dynamic hardware-independent input rendering engine 
    private static void SendUnicodeString(string text) {
        foreach (char c in text) {
            // Generates synchronous KeyDown and KeyUp events for raw Unicode data
            keybd_event(0, (byte)c, 4, 0); // 4 = KEYEVENTF_UNICODE
            keybd_event(0, (byte)c, 4 | KEYEVENTF_KEYUP, 0);
        }
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
            int vkCode = Marshal.ReadInt32(lParam);

            // Hashtag Toggle sequence handling (# key code: 51)
            if (_lastKeyWasMapped && vkCode == 51) {
                _isEnabled = !_isEnabled;
                _lastKeyWasMapped = false;
                return (IntPtr)1; // Consume the keypress
            }

            if (KeyMap.ContainsKey(vkCode)) {
                if (_isEnabled) {
                    SendUnicodeString(KeyMap[vkCode]);
                    _lastKeyWasMapped = true;
                    return (IntPtr)1; // Suppress system execution of intercepted key
                } else {
                    _lastKeyWasMapped = true;
                    return CallNextHookEx(_hookID, nCode, wParam, lParam);
                }
            }
            _lastKeyWasMapped = false;
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }
}
"@
Add-Type -TypeDefinition $Source -ReferencedAssemblies "System.Windows.Forms"

# --- Full Comprehensive Universal Virtual Key Translation Map ---
$VKLookup = @{
    "LeftCtrl"=[int]162; "RightCtrl"=[int]163; "CapsLock"=[int]20; "Space"=[int]32; "Tab"=[int]9; 
    "Enter"=[int]13; "Shift"=[int]16; "Alt"=[int]18; "Escape"=[int]27; "Insert"=[int]45; "Delete"=[int]46;
    "F1"=[int]112; "F2"=[int]113; "F3"=[int]114; "F4"=[int]115; "F5"=[int]116; "F6"=[int]117; 
    "F7"=[int]118; "F8"=[int]119; "F9"=[int]120; "F10"=[int]121; "F11"=[int]122; "F12"=[int]123;
    "A"=[int]65; "B"=[int]66; "C"=[int]67; "D"=[int]68; "E"=[int]69; "F"=[int]70; "G"=[int]71; 
    "H"=[int]72; "I"=[int]73; "J"=[int]74; "K"=[int]75; "L"=[int]76; "M"=[int]77; "N"=[int]78; 
    "O"=[int]79; "P"=[int]80; "Q"=[int]81; "R"=[int]82; "S"=[int]83; "T"=[int]84; "U"=[int]85; 
    "V"=[int]86; "W"=[int]87; "X"=[int]88; "Y"=[int]89; "Z"=[int]90;
    "0"=[int]48; "1"=[int]49; "2"=[int]50; "3"=[int]51; "4"=[int]52; "5"=[int]53; "6"=[int]54; 
    "7"=[int]55; "8"=[int]56; "9"=[int]57
}

function Parse-Macm ($content) {
    [MachoEngine]::KeyMap.Clear()
    $lines = $content -split "`r?`n"
    foreach ($line in $lines) {
        $line = $line.Trim()
        if ($line.StartsWith("#") -or $line -eq "") { continue }
        if ($line -match "(.+)=>(.+)") {
            $keyName = $Matches[1].Trim()
            $action = $Matches[2].Trim()
            
            if ($VKLookup.ContainsKey($keyName)) {
                [MachoEngine]::KeyMap[$VKLookup[$keyName]] = $action
            }
        }
    }
}

# --- Graphical User Interface Structure ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "MACHO - Dynamic Keyboard Customization Platform"
$Form.Size = New-Object System.Drawing.Size(520,460)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"

$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Configure layouts via the Macho Language (.macm):"
$Label.Location = New-Object System.Drawing.Point(15,15)
$Label.Size = New-Object System.Drawing.Size(400,20)
$Form.Controls.Add($Label)

$TextBox = New-Object System.Windows.Forms.TextBox
$TextBox.Multiline = $true
$TextBox.ScrollBars = "Vertical"
$TextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$TextBox.Location = New-Object System.Drawing.Point(15,40)
$TextBox.Size = New-Object System.Drawing.Size(475,280)
# Default template updated with target character configuration layout
$TextBox.Text = "# Macho Translation Profile`r`nLeftCtrl => ത`r`nRightCtrl => ത`r`nCapsLock => Custom Output"
$Form.Controls.Add($TextBox)

$BtnLoad = New-Object System.Windows.Forms.Button
$BtnLoad.Text = "Load File"
$BtnLoad.Location = New-Object System.Drawing.Point(15,335)
$BtnLoad.Size = New-Object System.Drawing.Size(110,35)
$BtnLoad.Add_Click({
    $OD = New-Object System.Windows.Forms.OpenFileDialog
    $OD.Filter = "Macho Profiles (*.macm)|*.macm"
    if ($OD.ShowDialog() -eq "OK") { $TextBox.Text = Get-Content $OD.FileName -Raw }
})
$Form.Controls.Add($BtnLoad)

$BtnSave = New-Object System.Windows.Forms.Button
$BtnSave.Text = "Save File"
$BtnSave.Location = New-Object System.Drawing.Point(135,335)
$BtnSave.Size = New-Object System.Drawing.Size(110,35)
$BtnSave.Add_Click({
    $SD = New-Object System.Windows.Forms.SaveFileDialog
    $SD.Filter = "Macho Profiles (*.macm)|*.macm"
    if ($SD.ShowDialog() -eq "OK") { Set-Content $SD.FileName $TextBox.Text }
})
$Form.Controls.Add($BtnSave)

$BtnStart = New-Object System.Windows.Forms.Button
$BtnStart.Text = "Apply Layout Configuration"
$BtnStart.Location = New-Object System.Drawing.Point(255,335)
$BtnStart.Size = New-Object System.Drawing.Size(235,35)
$BtnStart.BackColor = "LightGreen"
$BtnStart.Font = New-Object System.Drawing.Font($Form.Font, [System.Drawing.FontStyle]::Bold)
$BtnStart.Add_Click({
    Parse-Macm $TextBox.Text
    [MachoEngine]::Start()
    [System.Windows.Forms.MessageBox]::Show("Macho structural layout is active!", "Macho Platform Engine")
})
$Form.Controls.Add($BtnStart)

$Form.Add_FormClosing({ [MachoEngine]::Stop() })
$Form.ShowDialog() | Out-Null
