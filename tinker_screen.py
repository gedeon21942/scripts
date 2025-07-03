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

# Start the Tkinter event loop
root.mainloop()


