# ==============================================================================
# MACHO - The Ultimate Native Key Mapper Application
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- Core Keyboard Hook C# Payload ---
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

    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
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

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
            int vkCode = Marshal.ReadInt32(lParam);

            // Global Hashtag Toggle Functionality
            if (_lastKeyWasMapped && (vkCode == 51 || vkCode == 222)) {
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
                        SendKeys.SendWait(action);
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

# --- Key Parser Translation Map ---
$VKLookup = @{
    "LeftCtrl"  = 162; "RightCtrl" = 163; "F1" = 112; "F2" = 113; "F3" = 114;
    "F4"        = 115; "F5" = 116; "F6" = 117; "F7" = 118; "F8" = 119;
    "F9"        = 120; "F10" = 121; "F11" = 122; "F12" = 123; "CapsLock" = 20;
    "Space"     = 32; "Tab" = 9; "Insert" = 45; "Delete" = 46
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

# --- Graphical User Interface (UI) Window ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "MACHO - Key Mapper Configuration"
$Form.Size = New-Object System.Drawing.Size(500,450)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"

$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Edit your Macho configuration language (.macm) below:"
$Label.Location = New-Object System.Drawing.Point(15,15)
$Label.Size = New-Object System.Drawing.Size(400,20)
$Form.Controls.Add($Label)

$TextBox = New-Object System.Windows.Forms.TextBox
$TextBox.Multiline = $true
$TextBox.ScrollBars = "Vertical"
$TextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$TextBox.Location = New-Object System.Drawing.Point(15,40)
$TextBox.Size = New-Object System.Drawing.Size(450,280)
$TextBox.Text = "# Macho Config`r`nLeftCtrl => C:\`r`nRightCtrl => https://github.com`r`nF12 => Made with Macho Engine!"
$Form.Controls.Add($TextBox)

$BtnLoad = New-Object System.Windows.Forms.Button
$BtnLoad.Text = "Load .macm File"
$BtnLoad.Location = New-Object System.Drawing.Point(15,335)
$BtnLoad.Size = New-Object System.Drawing.Size(120,30)
$BtnLoad.Add_Click({
    $OD = New-Object System.Windows.Forms.OpenFileDialog
    $OD.Filter = "Macho Files (*.macm)|*.macm|All Files (*.*)|*.*"
    if ($OD.ShowDialog() -eq "OK") {
        $TextBox.Text = Get-Content $OD.FileName -Raw
    }
})
$Form.Controls.Add($BtnLoad)

$BtnSave = New-Object System.Windows.Forms.Button
$BtnSave.Text = "Save .macm File"
$BtnSave.Location = New-Object System.Drawing.Point(145,335)
$BtnSave.Size = New-Object System.Drawing.Size(120,30)
$BtnSave.Add_Click({
    $SD = New-Object System.Windows.Forms.SaveFileDialog
    $SD.Filter = "Macho Files (*.macm)|*.macm"
    if ($SD.ShowDialog() -eq "OK") {
        Set-Content $SD.FileName $TextBox.Text
    }
})
$Form.Controls.Add($BtnSave)

$BtnStart = New-Object System.Windows.Forms.Button
$BtnStart.Text = "Apply & Start Engine"
$BtnStart.Location = New-Object System.Drawing.Point(280,335)
$BtnStart.Size = New-Object System.Drawing.Size(185,30)
$BtnStart.BackColor = "LightGreen"
$BtnStart.Add_Click({
    Parse-Macm $TextBox.Text
    [MachoEngine]::Start()
    [System.Windows.Forms.MessageBox]::Show("Macho Engine Started! Active configurations are live.", "Macho Engine")
})
$Form.Controls.Add($BtnStart)

$Form.Add_FormClosing({ [MachoEngine]::Stop() })
$Form.ShowDialog() | Out-Null
