#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include <stdbool.h>

static void LaunchApp(void) {
    // Try launching Microsoft Edge in standalone App Mode
    // Edge App mode provides a completely borderless dedicated app window (no address bar, no tabs)
    WCHAR edgePath[MAX_PATH] = {0};
    ExpandEnvironmentStringsW(L"%ProgramFiles(x86)%\\Microsoft\\Edge\\Application\\msedge.exe", edgePath, MAX_PATH);

    DWORD attr = GetFileAttributesW(edgePath);
    if (attr == INVALID_FILE_ATTRIBUTES) {
        ExpandEnvironmentStringsW(L"%ProgramFiles%\\Microsoft\\Edge\\Application\\msedge.exe", edgePath, MAX_PATH);
        attr = GetFileAttributesW(edgePath);
    }

    WCHAR appArgs[] = L"--app=http://localhost:3000 --window-size=1366,800";

    if (attr != INVALID_FILE_ATTRIBUTES) {
        HINSTANCE res = ShellExecuteW(NULL, L"open", edgePath, appArgs, NULL, SW_SHOWNORMAL);
        if ((INT_PTR)res > 32) {
            return;
        }
    }

    // Try Google Chrome in standalone App Mode
    WCHAR chromePath[MAX_PATH] = {0};
    ExpandEnvironmentStringsW(L"%ProgramFiles%\\Google\\Chrome\\Application\\chrome.exe", chromePath, MAX_PATH);
    attr = GetFileAttributesW(chromePath);
    if (attr == INVALID_FILE_ATTRIBUTES) {
        ExpandEnvironmentStringsW(L"%ProgramFiles(x86)%\\Google\\Chrome\\Application\\chrome.exe", chromePath, MAX_PATH);
        attr = GetFileAttributesW(chromePath);
    }

    if (attr != INVALID_FILE_ATTRIBUTES) {
        HINSTANCE res = ShellExecuteW(NULL, L"open", chromePath, appArgs, NULL, SW_SHOWNORMAL);
        if ((INT_PTR)res > 32) {
            return;
        }
    }

    // Fallback: Default Browser
    ShellExecuteW(NULL, L"open", L"http://localhost:3000", NULL, NULL, SW_SHOWNORMAL);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    (void)hInstance;
    (void)hPrevInstance;
    (void)lpCmdLine;
    (void)nCmdShow;
    LaunchApp();
    return 0;
}

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    LaunchApp();
    return 0;
}
