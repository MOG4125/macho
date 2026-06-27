$Source = @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class KeyboardHook {
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
    private static IntPtr _hookID = IntPtr.Zero;
    
    // State tracking variables
    private static bool _isEnabled = true;
    private static bool _ctrlWasJustPressed = false;

    public static void Start() { _hookID = SetHook(_proc); Application.Run(); }
    public static void Stop() { UnhookWindowsHookEx(_hookID); }

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

            // Check if # (VK_OEM_2 or Shift+3 depending on keyboard layout, using standard US OEM_3 / key code 51 for hashtag detection)
            // To ensure compatibility across layouts, we check for standard Shift + 3 sequence or direct hashtag input.
            // Virtual key code 51 is the '3' key.
            if (_ctrlWasJustPressed && (vkCode == 51 || vkCode == 222)) {
                _isEnabled = !_isEnabled; // Toggle state
                _ctrlWasJustPressed = false;
                return (IntPtr)1; // Block the hashtag key press from typing
            }

            // 162 is Left Control, 163 is Right Control
            if (vkCode == 162 || vkCode == 163) {
                if (_isEnabled) {
                    SendKeys.SendWait("C:\\");
                    _ctrlWasJustPressed = true;
                    return (IntPtr)1; // Block native Ctrl
                } else {
                    _ctrlWasJustPressed = true; // Still track it so they can toggle it back ON
                    return CallNextHookEx(_hookID, nCode, wParam, lParam);
                }
            }
            
            // Any other key clears the shortcut sequence memory
            _ctrlWasJustPressed = false;
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }
}
"@

Add-Type -TypeDefinition $Source -ReferencedAssemblies "System.Windows.Forms"
[KeyboardHook]::Start()
