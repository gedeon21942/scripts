#!/usr/bin/env python3
import tkinter as tk
import subprocess
import os
import sys
import threading

# Function to run a script and update the status label
def run_script(script_path):
    def task():
        status_label.config(text="Running...", fg="yellow")
        root.update_idletasks()
        try:
            result = subprocess.run(["bash", script_path], check=True, capture_output=True, text=True)
            status_label.config(text="100% - Done!", fg="green")
            # Log stdout
            with open("/tmp/unraid_gui.log", "a") as logf:
                logf.write(f"\n[{script_path}] STDOUT:\n{result.stdout}\n")
        except subprocess.CalledProcessError as e:
            status_label.config(text="Error!", fg="red")
            with open("/tmp/unraid_gui.log", "a") as logf:
                logf.write(f"\n[{script_path}] ERROR:\nReturn code: {e.returncode}\nSTDOUT:\n{e.stdout}\nSTDERR:\n{e.stderr}\n")
            print(f"Error running script {script_path}: {e}")
    threading.Thread(target=task, daemon=True).start()

# Function to forcefully kill the process
def kill_process():
    print("Forcefully killing the process...")
    os.kill(os.getpid(), 9)  # Sends SIGKILL to the current process

def open_rdvpn_on_free_workspace():
    used = subprocess.check_output("hyprctl workspaces -j | jq '.[].id'", shell=True).decode().split()
    for i in range(1, 11):
        if str(i) not in used:
            free_ws = i
            break
    else:
        free_ws = 10

    subprocess.Popen([
        "kitty", "--title", "RDVPN-Terminal", "bash", "-c", "/home/nortron/.local/share/scripts/rdvpn.sh"
    ])
    subprocess.run(f"sleep 0.5 && hyprctl dispatch movetoworkspace {free_ws} title:RDVPN-Terminal", shell=True)

def shutdown_computer():
    # You may want to confirm before shutting down
    os.system("systemctl poweroff")

# Create the main window
root = tk.Tk()
root.title("Tinker Screen")
root.geometry("500x300")  # Adjusted window size to accommodate the new buttons
root.configure(bg="black")  # Set the background color to black

# Add buttons for scripts in the top row
button1 = tk.Button(root, text="Archy", command=lambda: run_script("/home/nortron/.local/share/scripts/Archy.sh"))
button1.grid(row=0, column=0, padx=10, pady=10)

button2 = tk.Button(root, text="Stop Work", command=lambda: run_script("/home/nortron/.local/share/scripts/stopwork.sh"))
button2.grid(row=0, column=1, padx=10, pady=10)

button3 = tk.Button(root, text="Unraid", command=lambda: run_script("/home/nortron/.local/share/scripts/unraid.sh"))
button3.grid(row=0, column=2, padx=10, pady=10)

button4 = tk.Button(root, text="Backup", command=lambda: run_script("/home/nortron/.local/share/scripts/backup.sh"))
button4.grid(row=0, column=3, padx=10, pady=10)

button5 = tk.Button(root, text="W11", command=lambda: run_script("/home/nortron/.local/share/scripts/startwork.sh"))
button5.grid(row=0, column=4, padx=10, pady=10)

button6 = tk.Button(root, text="RDVPN", command=open_rdvpn_on_free_workspace)
button6.grid(row=0, column=5, padx=10, pady=10)

button7 = tk.Button(root, text="Desktop", command=lambda: run_script("/home/nortron/.local/share/scripts/desktop.sh"))
button7.grid(row=0, column=6, padx=10, pady=10)

button8 = tk.Button(root, text="RDHyper", command=lambda: run_script("/home/nortron/.local/share/scripts/rdhypr.sh"))
button8.grid(row=0, column=7, padx=10, pady=10)

button9 = tk.Button(root, text="tarch", command=lambda: run_script("/home/nortron/.local/share/scripts/tarch.sh"))
button9.grid(row=0, column=8, padx=10, pady=10)

# Add a close button in the upper-right corner
close_button = tk.Button(root, text="X", command=root.destroy, bg="red", fg="white", font=("Arial", 10, "bold"))
close_button.place(relx=1.0, rely=0.0, anchor="ne", width=30, height=30)

# Add a "Kill Process" button
kill_button = tk.Button(root, text="Kill Process", command=kill_process, bg="red", fg="white", font=("Arial", 10, "bold"))
kill_button.grid(row=1, column=0, columnspan=6, pady=10)  # Positioned below the buttons

# Status label for percentage/status
status_label = tk.Label(root, text="Ready", bg="black", fg="white", font=("Arial", 12))
status_label.grid(row=2, column=0, columnspan=6, pady=10)

# Add a Shutdown button at the bottom
shutdown_button = tk.Button(root, text="Shutdown", command=shutdown_computer, bg="orange", fg="black", font=("Arial", 12, "bold"))
shutdown_button.grid(row=99, column=0, columnspan=7, pady=20, sticky="we")  # row=99 ensures it's at the bottom

def refresh_script():
    python = sys.executable
    os.execl(python, python, *sys.argv)

refresh_button = tk.Button(root, text="Refresh", command=refresh_script, bg="blue", fg="white", font=("Arial", 10, "bold"))
refresh_button.grid(row=1, column=6, padx=10, pady=10)

def open_new_window():
    # Get the main window's position and size
    root.update_idletasks()
    x = root.winfo_x()
    y = root.winfo_y()
    width = root.winfo_width()
    height = root.winfo_height()

    root.withdraw()

    new_win = tk.Toplevel(root)
    new_win.title("New Tkinter Window")
    new_win.attributes('-fullscreen', True)
    new_win.configure(bg="black")  # Set the background color to black

    def on_close():
        root.deiconify()
        new_win.destroy()
    new_win.protocol("WM_DELETE_WINDOW", on_close)
    new_win.bind("<Escape>", lambda e: on_close())

    label = tk.Label(new_win, text="This is another Tkinter window!", font=("Arial", 12))
    
    label.pack(pady=20)

    # Add a button under the label to run a script
    run_btn = tk.Button(
        new_win,
        text="Suspend Desk",
        command=lambda: run_script("/home/nortron/.local/share/scripts/suspend_desk.sh")
    )
    run_btn.pack(pady=10)

    back_btn = tk.Button(new_win, text="Back", command=on_close)
    back_btn.pack(pady=10)

# Add this button to the top row (for example, after the last button)
open_window_button = tk.Button(root, text="Open Window", command=open_new_window)
open_window_button.grid(row=0, column=10, padx=10, pady=10)

# Add a button next to 'Open Window' to run work11.sh
work11_button = tk.Button(root, text="Work11", command=lambda: run_script("/home/nortron/.local/share/scripts/work11.sh"))
work11_button.grid(row=0, column=11, padx=10, pady=10)

# Start the Tkinter event loop
root.mainloop()
