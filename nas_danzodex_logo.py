#!/usr/bin/env python3
"""
NAS_DANZODEX terminal logo
In ra banner ASCII art mau gold gradient khi mo terminal,
kem theo progress bar Backend/Frontend va audit log gia lap.
"""
import time
import random
import datetime

FONT = {
    'N': [
        "#   #",
        "##  #",
        "# # #",
        "#  ##",
        "#   #",
    ],
    'A': [
        " ### ",
        "#   #",
        "#####",
        "#   #",
        "#   #",
    ],
    'S': [
        " ####",
        "#    ",
        " ### ",
        "    #",
        "#### ",
    ],
    '_': [
        "     ",
        "     ",
        "     ",
        "     ",
        "#####",
    ],
    'D': [
        "#### ",
        "#   #",
        "#   #",
        "#   #",
        "#### ",
    ],
    'Z': [
        "#####",
        "   # ",
        "  #  ",
        " #   ",
        "#####",
    ],
    'O': [
        " ### ",
        "#   #",
        "#   #",
        "#   #",
        " ### ",
    ],
    'E': [
        "#####",
        "#    ",
        "###  ",
        "#    ",
        "#####",
    ],
    'X': [
        "#   #",
        " # # ",
        "  #  ",
        " # # ",
        "#   #",
    ],
}

TEXT = "NAS_DANZODEX"
HEIGHT = 5

# Gold gradient: tu vang dam -> vang sang -> cam
GRADIENT = [178, 214, 220, 226, 220, 214, 178, 172, 208, 214, 220, 226]

def build_lines(text):
    lines = ["" for _ in range(HEIGHT)]
    for ch in text:
        glyph = FONT.get(ch, ["     "] * HEIGHT)
        for i in range(HEIGHT):
            lines[i] += glyph[i] + " "
    return lines

def colorize(lines):
    width = len(lines[0])
    out = []
    n = len(GRADIENT)
    for line in lines:
        colored = ""
        for x, ch in enumerate(line):
            if ch == "#":
                color = GRADIENT[int(x / max(width, 1) * n) % n]
                colored += f"\033[1m\033[38;5;{color}m█\033[0m"
            else:
                colored += " "
        out.append(colored)
    return out

def progress_bar(label, color=220, width=30, duration=1.0, ok_color=82):
    """In progress bar chay tu 0 -> 100% roi bao ONLINE"""
    for pct in range(0, 101, 4):
        filled = int(width * pct / 100)
        bar = "█" * filled + "░" * (width - filled)
        print(f"\r  \033[38;5;{color}m{label:<22}\033[0m "
              f"\033[38;5;{color}m[{bar}]\033[0m {pct:3d}%",
              end="", flush=True)
        time.sleep(duration / 25)
    print(f"\r  \033[38;5;{color}m{label:<22}\033[0m "
          f"\033[38;5;{color}m[{'█'*width}]\033[0m 100%  "
          f"\033[1m\033[38;5;{ok_color}mONLINE\033[0m")


API_ENDPOINTS = [
    ("GET",  "/api/v1/health"),
    ("GET",  "/api/v1/status"),
    ("POST", "/api/v1/auth/login"),
    ("GET",  "/api/v1/user/profile"),
    ("POST", "/api/v1/wallet/sync"),
    ("GET",  "/api/v1/market/price"),
    ("POST", "/api/v1/order/create"),
    ("GET",  "/api/v1/order/history"),
    ("GET",  "/api/v1/config"),
    ("POST", "/api/v1/session/refresh"),
]

METHOD_COLOR = {"GET": 45, "POST": 214, "PUT": 220, "DELETE": 203}


def print_audit_log(n=8):
    print("\n  \033[1m\033[38;5;178m── AUDIT LOG ─────────────────────────────────────────────\033[0m")
    now = datetime.datetime.now()
    for i in range(n):
        ts = (now - datetime.timedelta(seconds=(n - i) * 2)).strftime("%Y-%m-%d %H:%M:%S")
        method, endpoint = random.choice(API_ENDPOINTS)
        status = random.choices([200, 200, 200, 201, 400, 401, 500], weights=[40,20,15,10,7,5,3])[0]
        latency = random.randint(8, 180)
        mcolor = METHOD_COLOR.get(method, 250)
        scolor = 82 if status < 300 else (220 if status < 500 else 196)
        level = "INFO" if status < 400 else ("WARN" if status < 500 else "ERROR")
        lcolor = 82 if level == "INFO" else (220 if level == "WARN" else 196)
        print(f"  \033[38;5;240m[{ts}]\033[0m "
              f"\033[1m\033[38;5;{lcolor}m{level:<5}\033[0m "
              f"\033[38;5;{mcolor}m{method:<5}\033[0m "
              f"{endpoint:<26} "
              f"\033[1m\033[38;5;{scolor}m{status}\033[0m "
              f"\033[38;5;240m{latency}ms\033[0m")
    print()


def main():
    lines = build_lines(TEXT)
    colored = colorize(lines)
    print()
    for line in colored:
        print("  " + line)
    print()
    print("  \033[38;5;220m>> N A S _ D A N Z O D E X   T O O L S U I T E <<\033[0m")
    print()
    progress_bar("Backend service", color=214)
    progress_bar("Frontend service", color=226)
    print_audit_log(n=8)
    print("  \033[1m\033[38;5;82m✔ System ready. All services operational.\033[0m\n")

if __name__ == "__main__":
    main()
