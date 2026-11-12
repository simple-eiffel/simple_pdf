/* simple_pdf_print_win.h - Windows helpers for printing an existing PDF (2026-11-11).

   spp_printer_port: a printer's port, read with GetPrinterW (level 2). A printer whose port is
   PORTPROMPT: or FILE: writes a file and asks where (Microsoft Print to PDF, the XPS writer);
   simple_pdf asks that question itself, with the system's Save dialog owned by the program's
   window, and hands the path to pdftocairo: the printer's own prompt, from a helper that was
   started hidden, stood invisible while the program waited (Larry's copy hung, 2026-11-11).

   spp_pump_messages: while the print helper runs, keep this thread's windows painting (and
   Windows from calling the program "Not responding"); keyboard and mouse input is dropped,
   so nothing re-enters the program mid-print. spp_disable_windows / spp_enable_windows make
   the wait modal. spp_in_job: is a process in a job (tests: the helper ends with us).
   No state kept. */

#ifndef SIMPLE_PDF_PRINT_WIN_H
#define SIMPLE_PDF_PRINT_WIN_H

#ifdef _WIN32
#include <windows.h>
#include <winspool.h>
#include <stdlib.h>
#include <wchar.h>

#pragma comment(lib, "winspool.lib")

/* The port of printer `a_name' into `a_out' (`a_cap' wide characters); 1 when read. */
static int spp_printer_port(const wchar_t* a_name, wchar_t* a_out, int a_cap)
{
    HANDLE l_printer = NULL;
    DWORD l_need = 0;
    PRINTER_INFO_2W* l_info;
    int l_answer = 0;
    if (!a_out || a_cap < 2) return 0;
    a_out[0] = 0;
    if (!OpenPrinterW((LPWSTR) a_name, &l_printer, NULL)) return 0;
    GetPrinterW(l_printer, 2, NULL, 0, &l_need);
    if (l_need > 0) {
        l_info = (PRINTER_INFO_2W*) malloc(l_need);
        if (l_info) {
            if (GetPrinterW(l_printer, 2, (LPBYTE) l_info, l_need, &l_need) && l_info->pPortName) {
                wcsncpy(a_out, l_info->pPortName, (size_t) (a_cap - 1));
                a_out[a_cap - 1] = 0;
                l_answer = 1;
            }
            free(l_info);
        }
    }
    ClosePrinter(l_printer);
    return l_answer;
}

/* A message held back during the wait, handed back after it. */
typedef struct { HWND h; UINT m; WPARAM w; LPARAM l; } SPP_HELD;

/* Is `a_m' a request to close a window (WM_CLOSE, or the system menu's Close)? */
static int spp_is_close(const MSG* a_m)
{
    return a_m->message == WM_CLOSE
        || (a_m->message == WM_SYSCOMMAND && (a_m->wParam & 0xFFF0) == SC_CLOSE);
}

/* Dispatch this thread's posted messages: keyboard and mouse input dropped; a close
   request held in `a_held' (room for `a_cap', `a_count' already there) for `spp_repost';
   everything else (paint, timers) dispatched. Answers the new count held. A message sent
   by another thread or program is delivered by Windows inside PeekMessage, as in any
   modal wait, and is not held. */
static int spp_pump_messages(SPP_HELD* a_held, int a_cap, int a_count)
{
    MSG m;
    while (PeekMessageW(&m, NULL, 0, 0, PM_REMOVE)) {
        if ((m.message >= WM_KEYFIRST && m.message <= WM_KEYLAST)
            || (m.message >= WM_MOUSEFIRST && m.message <= WM_MOUSELAST)
            || (m.message >= WM_NCMOUSEMOVE && m.message <= WM_NCMBUTTONDBLCLK)) {
            continue;
        }
        if (spp_is_close(&m)) {
            if (a_held && a_count < a_cap) {
                a_held[a_count].h = m.hwnd;
                a_held[a_count].m = m.message;
                a_held[a_count].w = m.wParam;
                a_held[a_count].l = m.lParam;
                a_count++;
            }
            continue;
        }
        if (m.message == WM_QUIT) {
            PostQuitMessage((int) m.wParam);
            break;
        }
        TranslateMessage(&m);
        DispatchMessageW(&m);
    }
    return a_count;
}

/* Post again the `a_count' messages `spp_pump_messages' held. */
static void spp_repost(const SPP_HELD* a_held, int a_count)
{
    int i;
    for (i = 0; i < a_count; i++) {
        if (IsWindow(a_held[i].h)) PostMessageW(a_held[i].h, a_held[i].m, a_held[i].w, a_held[i].l);
    }
}

typedef struct { HWND* list; int cap; int count; } SPP_DISABLE;

static BOOL CALLBACK spp_disable_each(HWND h, LPARAM l)
{
    SPP_DISABLE* d = (SPP_DISABLE*) l;
    if (d->count < d->cap && IsWindowVisible(h) && IsWindowEnabled(h)) {
        EnableWindow(h, FALSE);
        d->list[d->count++] = h;
    }
    return TRUE;
}

/* Disable this thread's visible, enabled top-level windows, as a modal wait does; their
   handles go into `a_out' (`a_cap' of them); answers how many. */
static int spp_disable_windows(HWND* a_out, int a_cap)
{
    SPP_DISABLE d;
    d.list = a_out;
    d.cap = a_cap;
    d.count = 0;
    EnumThreadWindows(GetCurrentThreadId(), spp_disable_each, (LPARAM) &d);
    return d.count;
}

/* Enable again the windows `spp_disable_windows' disabled. */
static void spp_enable_windows(HWND* a_list, int a_count)
{
    int i;
    for (i = 0; i < a_count; i++) if (IsWindow(a_list[i])) EnableWindow(a_list[i], TRUE);
}

/* Is process `a_pid' in a job object (tests)? */
static int spp_in_job(DWORD a_pid)
{
    HANDLE l_child = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, a_pid);
    BOOL l_in = FALSE;
    if (l_child) {
        IsProcessInJob(l_child, NULL, &l_in);
        CloseHandle(l_child);
    }
    return l_in ? 1 : 0;
}

/* Tests: a window of this thread, visible to Windows but placed off every screen and kept
   off the taskbar, that counts the clicks and close requests it receives. */
static LRESULT CALLBACK spp_test_proc(HWND h, UINT m, WPARAM w, LPARAM l)
{
    if (m == WM_LBUTTONDOWN) {
        SetPropW(h, L"spp_clicks", (HANDLE) ((INT_PTR) GetPropW(h, L"spp_clicks") + 1));
        return 0;
    }
    if (m == WM_CLOSE) {
        SetPropW(h, L"spp_closes", (HANDLE) ((INT_PTR) GetPropW(h, L"spp_closes") + 1));
        return 0;
    }
    if (m == WM_NCDESTROY) {
        RemovePropW(h, L"spp_clicks");
        RemovePropW(h, L"spp_closes");
    }
    return DefWindowProcW(h, m, w, l);
}

static HWND spp_test_window(void)
{
    WNDCLASSW c;
    HINSTANCE l_instance = GetModuleHandleW(NULL);
    if (!GetClassInfoW(l_instance, L"SimplePdfTestWindow", &c)) {
        ZeroMemory(&c, sizeof(c));
        c.lpfnWndProc = spp_test_proc;
        c.hInstance = l_instance;
        c.lpszClassName = L"SimplePdfTestWindow";
        RegisterClassW(&c);
    }
    return CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE, L"SimplePdfTestWindow", L"simple_pdf test",
        WS_POPUP | WS_VISIBLE, -32000, -32000, 10, 10, NULL, NULL, l_instance, NULL);
}

static void spp_test_post_click_and_close(HWND h)
{
    PostMessageW(h, WM_LBUTTONDOWN, MK_LBUTTON, 0);
    PostMessageW(h, WM_CLOSE, 0, 0);
}

static int spp_test_clicks(HWND h) { return (int) (INT_PTR) GetPropW(h, L"spp_clicks"); }
static int spp_test_closes(HWND h) { return (int) (INT_PTR) GetPropW(h, L"spp_closes"); }
static int spp_test_enabled(HWND h) { return IsWindowEnabled(h) ? 1 : 0; }

/* Dispatch whatever is posted now (tests, after the wait). */
static void spp_test_drain(void)
{
    MSG m;
    while (PeekMessageW(&m, NULL, 0, 0, PM_REMOVE)) {
        TranslateMessage(&m);
        DispatchMessageW(&m);
    }
}
#endif

#endif /* SIMPLE_PDF_PRINT_WIN_H */
