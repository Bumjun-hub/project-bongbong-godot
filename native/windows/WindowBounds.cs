using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

// Reads window geometry and this Windows session's last input time.
// No process-memory access, input hooks or injection.
internal static class WindowBounds
{
    private const long Caption = 0x00C00000L;
    private const long ThickFrame = 0x00040000L;
    private const long SystemMenu = 0x00080000L;
    private const long ToolWindow = 0x00000080L;
    private const long Transparent = 0x00000020L;
    private const long Layered = 0x00080000L;
    private const long AppWindow = 0x00040000L;

    [StructLayout(LayoutKind.Sequential)]
    private struct Rect { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    private struct Point { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)]
    private struct LastInputInfo { public uint Size; public uint Time; }
    private sealed class Entry { public IntPtr Handle; public Rect Bounds; public bool Platform; }
    private delegate bool EnumWindowProc(IntPtr window, IntPtr parameter);

    [DllImport("user32.dll")] private static extern bool EnumWindows(EnumWindowProc callback, IntPtr parameter);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll")] private static extern bool IsIconic(IntPtr window);
    [DllImport("user32.dll")] private static extern bool GetWindowRect(IntPtr window, out Rect bounds);
    [DllImport("user32.dll")] private static extern bool GetClientRect(IntPtr window, out Rect bounds);
    [DllImport("user32.dll")] private static extern bool ClientToScreen(IntPtr window, ref Point point);
    [DllImport("user32.dll")] private static extern IntPtr GetTopWindow(IntPtr window);
    [DllImport("user32.dll")] private static extern IntPtr GetWindow(IntPtr window, uint command);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern int GetClassName(IntPtr window, StringBuilder name, int length);
    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW")] private static extern IntPtr GetWindowLongPtr64(IntPtr window, int index);
    [DllImport("user32.dll", EntryPoint = "GetWindowLongW")] private static extern int GetWindowLong32(IntPtr window, int index);
    [DllImport("dwmapi.dll", EntryPoint = "DwmGetWindowAttribute")] private static extern int GetFrameBounds(IntPtr window, int attribute, out Rect bounds, int size);
    [DllImport("dwmapi.dll", EntryPoint = "DwmGetWindowAttribute")] private static extern int GetCloaked(IntPtr window, int attribute, out uint value, int size);
    [DllImport("user32.dll")] private static extern bool GetLastInputInfo(ref LastInputInfo info);
    [DllImport("kernel32.dll")] private static extern uint GetTickCount();

    private static long IdleMilliseconds()
    {
        var info = new LastInputInfo { Size = (uint)Marshal.SizeOf(typeof(LastInputInfo)) };
        if (!GetLastInputInfo(ref info)) return -1;
        uint elapsed = unchecked(GetTickCount() - info.Time);
        return elapsed <= int.MaxValue ? elapsed : 0;
    }

    private static long Style(IntPtr window, int index)
    {
        return IntPtr.Size == 8 ? GetWindowLongPtr64(window, index).ToInt64() : GetWindowLong32(window, index);
    }

    internal static bool IsPlatformStyle(long style, long extendedStyle)
    {
        if ((extendedStyle & (ToolWindow | Transparent)) != 0) return false;
        bool standardCaption = (style & Caption) == Caption;
        // KakaoTalk and other custom-titlebar apps keep a resizable frame and
        // application window controls even though they omit WS_CAPTION.
        bool customFrame = (style & ThickFrame) != 0 &&
            ((style & SystemMenu) != 0 || (extendedStyle & AppWindow) != 0);
        return standardCaption || customFrame;
    }

    private static Entry ReadWindow(IntPtr window, IntPtr excluded)
    {
        if (window == excluded || !IsWindowVisible(window) || IsIconic(window)) return null;
        uint cloaked;
        if (GetCloaked(window, 14, out cloaked, 4) == 0 && cloaked != 0) return null;

        var className = new StringBuilder(256);
        GetClassName(window, className, className.Capacity);
        string kind = className.ToString();
        if (kind == "Progman" || kind == "WorkerW" || kind == "Shell_TrayWnd" ||
            kind == "Shell_SecondaryTrayWnd" || kind == "tooltips_class32" || kind == "SysShadow") return null;

        long style = Style(window, -16);
        long extendedStyle = Style(window, -20);
        bool platform = IsPlatformStyle(style, extendedStyle);
        // Click-through/layered decorations, including another desktop pet,
        // should not obscure the real windows behind them.
        if ((extendedStyle & Transparent) != 0) return null;
        if ((extendedStyle & Layered) != 0 && (style & Caption) == 0 && !platform) return null;

        Rect bounds;
        if (GetFrameBounds(window, 9, out bounds, Marshal.SizeOf(typeof(Rect))) != 0 && !GetWindowRect(window, out bounds)) return null;
        if (bounds.Right <= bounds.Left || bounds.Bottom <= bounds.Top) return null;
        return new Entry { Handle = window, Bounds = bounds, Platform = platform };
    }

    private static string Snapshot(IntPtr excluded)
    {
        var entries = new Dictionary<IntPtr, Entry>();
        EnumWindows(delegate(IntPtr window, IntPtr parameter)
        {
            Entry entry = ReadWindow(window, excluded);
            if (entry != null) entries[window] = entry;
            return true;
        }, IntPtr.Zero);

        // Resolve explicit front-to-back order. Bound traversal in case the
        // desktop changes while we read it; never loop over a recycled handle.
        var ordered = new List<Entry>();
        var visited = new HashSet<IntPtr>();
        for (IntPtr window = GetTopWindow(IntPtr.Zero); window != IntPtr.Zero && visited.Count < 8192; window = GetWindow(window, 2))
        {
            if (!visited.Add(window)) break;
            Entry entry;
            if (entries.TryGetValue(window, out entry)) ordered.Add(entry);
        }

        // Godot's DisplayServer can normalize a multi-monitor desktop's origin.
        // Report the pet's physical client origin so both coordinate systems align.
        var clientOrigin = new Point();
        Rect client;
        if (!GetClientRect(excluded, out client) || !ClientToScreen(excluded, ref clientOrigin)) client = new Rect();
        var json = new StringBuilder();
        json.AppendFormat(CultureInfo.InvariantCulture,
            "{{\"version\":1,\"client\":{{\"x\":{0},\"y\":{1},\"width\":{2},\"height\":{3}}},\"idle_ms\":{4},\"windows\":[",
            clientOrigin.X, clientOrigin.Y, client.Right - client.Left, client.Bottom - client.Top, IdleMilliseconds());
        for (int index = 0; index < ordered.Count; index++)
        {
            Entry entry = ordered[index];
            Rect r = entry.Bounds;
            if (index != 0) json.Append(',');
            json.AppendFormat(CultureInfo.InvariantCulture,
                "{{\"id\":\"{0}\",\"x\":{1},\"y\":{2},\"width\":{3},\"height\":{4},\"platform\":{5}}}",
                entry.Handle.ToInt64(), r.Left, r.Top, r.Right - r.Left, r.Bottom - r.Top, entry.Platform ? "true" : "false");
        }
        return json.Append("]}").ToString();
    }

    private static int Main(string[] arguments)
    {
        bool once = arguments.Length > 0 && arguments[0] == "--once";
        long excluded;
        int index = once ? 1 : 0;
        if (arguments.Length <= index || !long.TryParse(arguments[index], out excluded)) return 2;
        try
        {
            using (var output = new StreamWriter(Console.OpenStandardOutput(), new UTF8Encoding(false)))
            {
                output.AutoFlush = true;
                if (once) { output.WriteLine(Snapshot(new IntPtr(excluded))); return 0; }
                using (var input = new StreamReader(Console.OpenStandardInput(), Encoding.UTF8))
                {
                    string request;
                    // EOF automatically exits if the owning Godot process stops.
                    while ((request = input.ReadLine()) != null && request != "quit")
                        if (request == "snapshot") output.WriteLine(Snapshot(new IntPtr(excluded)));
                }
            }
            return 0;
        }
        catch (IOException) { return 0; } // Parent closed its pipe.
        catch (Exception) { return 1; }
    }
}
