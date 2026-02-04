#!/usr/bin/env python3
import tkinter as tk
import subprocess
import os
import sys
import threading
import difflib
from tkinter import messagebox, scrolledtext

# Global placeholder
status_label = None

# Function to run a script and update the status label
def run_script(script_path, label=None):
    def task():
        # Determine if we are in GUI mode and have a valid label
        target_label = label if label else (status_label if status_label else None)
        
        if target_label:
            target_label.config(text="Running...", fg="yellow")
            target_label.update_idletasks()
        else:
            print(f"Running {script_path}...")

        try:
            result = subprocess.run(["bash", script_path], check=True, capture_output=True, text=True)
            if target_label:
                target_label.config(text="100% - Done!", fg="green")
            else:
                print(f"Done: {script_path}")

            # Log stdout
            with open("/tmp/unraid_gui.log", "a") as logf:
                logf.write(f"\n[{script_path}] STDOUT:\n{result.stdout}\n")
        except subprocess.CalledProcessError as e:
            if target_label:
                target_label.config(text="Error!", fg="red")
            else:
                print(f"Error running {script_path}")

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

def run_cli():
    print("\n--- Tinker Screen CLI ---")
    actions = {
        "1": ("Archy", "/home/nortron/.local/share/scripts/Archy.sh"),
        "2": ("Stop Work", "/home/nortron/.local/share/scripts/stopwork.sh"),
        "3": ("Unraid", "/home/nortron/.local/share/scripts/unraid.sh"),
        "4": ("Backup", "/home/nortron/.local/share/scripts/backup.sh"),
        "5": ("W11", "/home/nortron/.local/share/scripts/startwork.sh"),
        "6": ("RDVPN", "/home/nortron/.local/share/scripts/rdvpn.sh"),
        "7": ("Desktop", "/home/nortron/.local/share/scripts/desktop.sh"),
        "8": ("RDHyper", "/home/nortron/.local/share/scripts/rdhypr.sh"),
        "9": ("tarch", "/home/nortron/.local/share/scripts/tarch.sh"),
        "10": ("Kill Process", None),
        "11": ("Shutdown", None),
        "12": ("Open Window (Submenu)", None)
    }
    
    while True:
        print("\nAvailable Commands:")
        for key, (name, _) in actions.items():
            print(f"{key}. {name}")
        print("q. Quit")
        
        choice = input("\nSelect an option: ").strip()
        
        if choice == 'q':
            break
        
        if choice in actions:
            name, script = actions[choice]
            if choice == "10":
                kill_process()
            elif choice == "11":
                shutdown_computer()
            elif choice == "12":
                run_cli_submenu()
            else:
                run_script(script)
        else:
            print("Invalid selection.")

def run_cli_submenu():
    print("\n--- Open Window Submenu ---")
    actions = {
        "1": ("Suspend Desk", "/home/nortron/.local/share/scripts/suspend_desk.sh"),
        "2": ("Mount Unraid", "/home/nortron/.local/share/scripts/unraid.sh"),
        "3": ("Unmount Unraid", "/home/nortron/.local/share/scripts/uunraid.sh"),
        "4": ("Compare Aliases", "/home/nortron/.local/share/scripts/compare_aliases.sh"),
        "5": ("Work11", "/home/nortron/.local/share/scripts/work11.sh"),
        "6": ("linutil", "/home/nortron/.local/share/scripts/linutil/install.sh")
        
    }
    while True:
        print("\nSubmenu Options:")
        for key, (name, _) in actions.items():
            print(f"{key}. {name}")
        print("b. Back")
        
        choice = input("Select: ").strip()
        if choice == 'b':
            break
        if choice in actions:
            name, script = actions[choice]
            if choice == "4":
                # Run interactive script in foreground
                subprocess.run(["zsh", script])
            elif choice == "6":
                subprocess.run(["bash", script])
            else:
                run_script(script)

def run_gui():
    global root, status_label
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

    def compare_aliases_gui():
        local_file = os.path.expanduser("~/.aliases.zsh")
        server_file = "/mnt/share/unraid/Backup/Arch/server/.aliases.zsh"

        # Ensure Unraid is mounted
        if not os.path.exists("/mnt/share/unraid/Backup"):
            subprocess.run(["bash", "/home/nortron/.local/share/scripts/unraid.sh"])

        if not os.path.exists(server_file):
            messagebox.showerror("Error", f"Server file not found:\n{server_file}\nMake sure Unraid is mounted.")
            return

        try:
            with open(local_file, 'r') as f:
                local_lines = f.readlines()
            with open(server_file, 'r') as f:
                server_lines = f.readlines()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to read files: {e}")
            return

        diff = list(difflib.unified_diff(local_lines, server_lines, fromfile='Local', tofile='Server'))

        if not diff:
            messagebox.showinfo("Compare Aliases", "Files are identical.")
            return

        # Create Diff Window
        diff_win = tk.Toplevel(root)
        diff_win.title("Compare Aliases - Diff")
        diff_win.geometry("900x700")
        diff_win.configure(bg="black")

        # Text Area
        txt = scrolledtext.ScrolledText(diff_win, bg="#1e1e1e", fg="#d4d4d4", font=("Consolas", 11))
        txt.pack(expand=True, fill="both", padx=10, pady=10)

        for line in diff:
            tag = "normal"
            if line.startswith("---") or line.startswith("+++"): tag = "header"
            elif line.startswith("-"): tag = "removed"
            elif line.startswith("+"): tag = "added"
            elif line.startswith("@@"): tag = "meta"
            txt.insert(tk.END, line, tag)

        txt.tag_config("header", foreground="#569cd6")
        txt.tag_config("removed", foreground="#f44747")
        txt.tag_config("added", foreground="#6a9955")
        txt.tag_config("meta", foreground="#dcdcaa")
        txt.configure(state="disabled")

        # Buttons
        btn_frame = tk.Frame(diff_win, bg="black")
        btn_frame.pack(fill="x", pady=10)

        def push():
            if messagebox.askyesno("Confirm Push", "Overwrite SERVER file with LOCAL version?"):
                subprocess.run(["sudo", "cp", local_file, server_file])
                messagebox.showinfo("Success", "Server file updated.")
                diff_win.destroy()

        def pull():
            if messagebox.askyesno("Confirm Pull", "Overwrite LOCAL file with SERVER version?"):
                subprocess.run(["sudo", "cp", server_file, local_file])
                user = os.environ.get('USER', 'nortron')
                subprocess.run(["sudo", "chown", f"{user}:{user}", local_file])
                messagebox.showinfo("Success", "Local file updated.")
                diff_win.destroy()

        tk.Button(btn_frame, text="Pull (Server -> Local)", command=pull, bg="green", fg="white", font=("Arial", 10, "bold")).pack(side="left", padx=20)
        tk.Button(btn_frame, text="Push (Local -> Server)", command=push, bg="blue", fg="white", font=("Arial", 10, "bold")).pack(side="left", padx=20)
        tk.Button(btn_frame, text="Cancel", command=diff_win.destroy, bg="red", fg="white", font=("Arial", 10, "bold")).pack(side="right", padx=20)

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
            command=lambda: run_script("/home/nortron/.local/share/scripts/suspend_desk.sh", new_status_label)
        )
        run_btn.pack(pady=10)

        mount_unraid_btn = tk.Button(new_win, text="mount unraid", command=lambda: run_script("/home/nortron/.local/share/scripts/unraid.sh", new_status_label))
        mount_unraid_btn.pack(pady=10)

        unmount_unraid_btn = tk.Button(new_win, text="un mount", command=lambda: run_script("/home/nortron/.local/share/scripts/uunraid.sh", new_status_label))
        unmount_unraid_btn.pack(pady=10)

        compare_btn = tk.Button(new_win, text="Compare Aliases", command=compare_aliases_gui)
        compare_btn.pack(pady=10)

        def run_linutil():
            subprocess.Popen(["kitty", "--title", "Linutil", "bash", "/home/nortron/.local/share/scripts/linutil/install.sh"])
            new_win.withdraw()

        linutil_btn = tk.Button(new_win, text="linutil", command=run_linutil)
        linutil_btn.pack(pady=10)

        new_status_label = tk.Label(new_win, text="Ready", bg="black", fg="white", font=("Arial", 12))
        new_status_label.pack(pady=10)

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

if __name__ == "__main__":
    if os.environ.get('DISPLAY'):
        run_gui()
    else:
        run_cli()
