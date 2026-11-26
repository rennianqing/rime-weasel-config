using System;
using System.Runtime.InteropServices;
using System.Threading;
using Microsoft.Win32;

namespace WeaselFix {
    static class Program {
        [DllImport("imm32.dll", SetLastError = true)]
        static extern bool ImmGetHotKey(uint dwHotKeyID, out uint lpuModifiers, out uint lpuVKey, out IntPtr lphKL);

        [DllImport("imm32.dll", SetLastError = true)]
        static extern bool ImmSetHotKey(uint dwHotKeyID, uint uModifiers, uint uVKey, IntPtr hKL);

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        static extern IntPtr SendMessageTimeout(
            IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
            uint fuFlags, uint uTimeout, out UIntPtr lpdwResult
        );

        [DllImport("kernel32.dll")]
        static extern bool SetProcessWorkingSetSize(IntPtr hProcess, IntPtr dwMinimumWorkingSetSize, IntPtr dwMaximumWorkingSetSize);

        [DllImport("kernel32.dll")]
        static extern IntPtr GetCurrentProcess();

        private static readonly uint[] TargetHotKeyIds = new uint[] { 0x10, 0x70 };

        private static bool ClearIfRegistered(bool forceWriteRegistry) {
            bool anyRegistered = false;
            try {
                foreach (uint id in TargetHotKeyIds) {
                    uint mod, vk;
                    IntPtr hkl;
                    if (ImmGetHotKey(id, out mod, out vk, out hkl)) {
                        anyRegistered = true;
                        ImmSetHotKey(id, 0, 0, IntPtr.Zero);
                    }
                }

                if (forceWriteRegistry || anyRegistered) {
                    EnsureRegistryDisabled();
                }
            } catch {
            }
            return anyRegistered;
        }

        private static void EnsureRegistryDisabled() {
            try {
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

                using (var rimeKey = Registry.CurrentUser.CreateSubKey(@"Software\Rime\weasel")) {
                    if (rimeKey != null) {
                        rimeKey.SetValue("ToggleImeOnOpenClose", "no", RegistryValueKind.String);
                    }
                }

                UIntPtr res;
                SendMessageTimeout((IntPtr)0xffff, 0x001A, UIntPtr.Zero, "Environment", 0x0002, 500, out res);
            } catch {
            }
        }

        private static void TrimMemory() {
            try {
                SetProcessWorkingSetSize(GetCurrentProcess(), new IntPtr(-1), new IntPtr(-1));
            } catch {
            }
        }

        [MTAThread]
        static void Main(string[] args) {
            bool runOnce = args != null && args.Length > 0 &&
                           string.Equals(args[0], "--once", StringComparison.OrdinalIgnoreCase);

            if (runOnce) {
                ClearIfRegistered(true);
                return;
            }

            bool createdNew;
            using (var mutex = new Mutex(true, @"Local\WeaselHotkeyFix_Guard_Mutex", out createdNew)) {
                if (!createdNew) {
                    // Already running: still do a quick pass in case user manually invoked it
                    ClearIfRegistered(false);
                    return;
                }

                // Initial pass + registry sync
                ClearIfRegistered(true);

                // React immediately to screen unlock / logon and sleep resume
                SystemEvents.SessionSwitch += (s, e) => {
                    if (e.Reason == SessionSwitchReason.SessionUnlock ||
                        e.Reason == SessionSwitchReason.SessionLogon ||
                        e.Reason == SessionSwitchReason.ConsoleConnect) {
                        ThreadPool.QueueUserWorkItem(_ => {
                            ClearIfRegistered(false);
                            Thread.Sleep(2000);
                            ClearIfRegistered(false);
                        });
                    }
                };

                SystemEvents.PowerModeChanged += (s, e) => {
                    if (e.Mode == PowerModes.Resume) {
                        ThreadPool.QueueUserWorkItem(_ => {
                            Thread.Sleep(1500);
                            ClearIfRegistered(false);
                            Thread.Sleep(5000);
                            ClearIfRegistered(false);
                        });
                    }
                };

                // Boot-phase rapid checks to win races with ctfmon.exe / TextInputHost.exe / WeaselServer.exe
                int[] bootDelaysMs = new int[] { 2000, 5000, 10000, 15000 };
                foreach (int delay in bootDelaysMs) {
                    Thread.Sleep(delay);
                    ClearIfRegistered(false);
                }

                TrimMemory();

                // Lightweight continuous guard (checks 2 kernel hotkey slots every 5 seconds, ~0% CPU)
                while (true) {
                    Thread.Sleep(5000);
                    ClearIfRegistered(false);
                }
            }
        }
    }
}
