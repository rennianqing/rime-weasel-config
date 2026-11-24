using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace WeaselFix {
    static class Program {
        [DllImport("imm32.dll", SetLastError = true)]
        static extern bool ImmSetHotKey(uint dwHotKeyID, uint uModifiers, uint uVKey, IntPtr hKL);

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        static extern IntPtr SendMessageTimeout(
            IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
            uint fuFlags, uint uTimeout, out UIntPtr lpdwResult
        );

        [STAThread]
        static void Main() {
            try {
                // 1. Unregister Windows IME Hotkeys 0x10 and 0x70 from memory
                ImmSetHotKey(0x10, 0, 0, IntPtr.Zero);
                ImmSetHotKey(0x70, 0, 0, IntPtr.Zero);

                // 2. Write disabled registry keys
                byte[] km = new byte[] { 0x00, 0xc0, 0x00, 0x00 };
                byte[] vk = new byte[] { 0xff, 0x00, 0x00, 0x00 };
                byte[] ti = new byte[] { 0x00, 0x00, 0x00, 0x00 };

                string[] subKeys = new string[] { "00000010", "00000070" };
                foreach (var sk in subKeys) {
                    using (var key = Registry.CurrentUser.CreateSubKey(@"Control Panel\Input Method\Hot Keys\" + sk)) {
                        if (key != null) {
                            key.SetValue("Key Modifiers", km, RegistryValueKind.Binary);
                            key.SetValue("Virtual Key", vk, RegistryValueKind.Binary);
                            key.SetValue("Target IME", ti, RegistryValueKind.Binary);
                        }
                    }
                }

                // 3. Ensure Weasel ToggleImeOnOpenClose is 'no'
                using (var rimeKey = Registry.CurrentUser.CreateSubKey(@"Software\Rime\weasel")) {
                    if (rimeKey != null) {
                        rimeKey.SetValue("ToggleImeOnOpenClose", "no", RegistryValueKind.String);
                    }
                }

                // 4. Notify system of change
                UIntPtr res;
                SendMessageTimeout((IntPtr)0xffff, 0x001A, UIntPtr.Zero, "Environment", 0x0002, 500, out res);
            } catch {}
        }
    }
}
