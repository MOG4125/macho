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

    private static void SendUnicodeString(string text) {
        foreach (char c in text) {
            keybd_event(0, (byte)c, 4, 0); // KEYEVENTF_UNICODE
            keybd_event(0, (byte)c, 4 | KEYEVENTF_KEYUP, 0);
        }
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
            int vkCode = Marshal.ReadInt32(lParam);

            if (_lastKeyWasMapped && vkCode == 51) {
                _isEnabled = !_isEnabled;
                _lastKeyWasMapped = false;
                return (IntPtr)1;
            }

            if (KeyMap.ContainsKey(vkCode)) {
                if (_isEnabled) {
                    string action = KeyMap[vkCode];
                    if (action.StartsWith("http://") || action.StartsWith("https://")) {
                        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(action) { UseShellExecute = true });
                    } else {
                        SendUnicodeString(action);
                    }
                    _lastKeyWasMapped = true;
                    return (IntPtr)1;
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

$VKLookup = @{
    "LeftCtrl"=162; "RightCtrl"=163; "CapsLock"=20; "Space"=32; "Tab"=9; 
    "Enter"=13; "Shift"=16; "Alt"=18; "Escape"=27; "Insert"=45; "Delete"=46;
    "F1"=112; "F2"=113; "F3"=114; "F4"=115; "F5"=116; "F6"=117; 
    "F7"=118; "F8"=119; "F9"=120; "F10"=121; "F11"=122; "F12"=123;
    "A"=65; "B"=66; "C"=67; "D"=68; "E"=69; "F"=70; "G"=71; "H"=72; "I"=73; "J"=74; 
    "K"=75; "L"=76; "M"=77; "N"=78; "O"=79; "P"=80; "Q"=81; "R"=82; "S"=83; "T"=84; 
    "U"=85; "V"=86; "W"=87; "X"=88; "Y"=89; "Z"=90;
    "0"=48; "1"=49; "2"=50; "3"=51; "4"=52; "5"=53; "6"=54; "7"=55; "8"=56; "9"=57
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
$TextBox.Text = "# Macho Translation Profile`r`nLeftCtrl => ത`r`nRightCtrl => https://github.com"
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
