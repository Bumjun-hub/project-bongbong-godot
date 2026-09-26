using System;

internal static class WindowStyleChecks
{
    private static int failures;

    private static void Check(string name, long style, long extendedStyle, bool expected)
    {
        bool actual = WindowBounds.IsPlatformStyle(style, extendedStyle);
        if (actual == expected) return;
        Console.Error.WriteLine("{0}: expected {1}, got {2}", name, expected, actual);
        failures++;
    }

    private static int Main()
    {
        Check("Standard desktop window", 0x16CF0000L, 0, true);
        Check("Observed Kakao main window", 0x960F0000L, 0x00040100L, true);
        Check("Observed Kakao chat window", 0x960F0000L, 0x00000110L, true);
        Check("Layered custom app window", 0x960F0000L, 0x00080000L, true);
        Check("Resizable application without system menu", 0x96040000L, 0x00040000L, true);
        Check("Observed Kakao auxiliary panel", 0x96000000L, 0, false);
        Check("Resize-only auxiliary window", 0x86040000L, 0x00000100L, false);
        Check("Layered pet overlay", 0x96000000L, 0x00080000L, false);
        Check("Tool window with standard caption", 0x16CF0000L, 0x00000080L, false);
        Check("Tool window with custom frame", 0x960F0000L, 0x00000080L, false);
        Check("Click-through standard window", 0x16CF0000L, 0x00000020L, false);
        Check("Click-through custom window", 0x960F0000L, 0x00000020L, false);
        Check("Borderless fullscreen or popup", 0x96000000L, 0x00040000L, false);
        if (failures == 0) Console.WriteLine("Window styles passed: standard, Kakao main/chat, custom/layered apps, auxiliary panels and overlays (13 cases)");
        return failures == 0 ? 0 : 1;
    }
}
