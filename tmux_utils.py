#!/usr/bin/env python3
"""
Tmux Orchestrator Python Library

This library provides a Python API for interacting with tmux sessions
and Podman containers. While the project primarily uses shell scripts,
this module is available for more complex automation tasks.

Usage example:
    orchestrator = TmuxOrchestrator()
    status = orchestrator.get_comprehensive_status()
    print(json.dumps(status, indent=2))

Note: Most orchestration is done via shell scripts in scripts/ directory.
This library provides programmatic access when needed.
"""

import subprocess
import json
import time
import shutil
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime

@dataclass
class TmuxWindow:
    session_name: str
    window_index: int
    window_name: str
    active: bool

@dataclass
class TmuxSession:
    name: str
    windows: List[TmuxWindow]
    attached: bool

@dataclass
class PodmanContainer:
    name: str
    status: str
    image: str
    created: str

class TmuxOrchestrator:
    def __init__(self):
        self.safety_mode = True
        self.max_lines_capture = 1000
        
    def get_tmux_sessions(self) -> List[TmuxSession]:
        """Get all tmux sessions and their windows"""
        try:
            # Get sessions
            sessions_cmd = ["tmux", "list-sessions", "-F", "#{session_name}:#{session_attached}"]
            sessions_result = subprocess.run(sessions_cmd, capture_output=True, text=True, check=True)
            
            sessions = []
            for line in sessions_result.stdout.strip().split('\n'):
                if not line:
                    continue
                session_name, attached = line.split(':')
                
                # Get windows for this session
                windows_cmd = ["tmux", "list-windows", "-t", session_name, "-F", "#{window_index}:#{window_name}:#{window_active}"]
                windows_result = subprocess.run(windows_cmd, capture_output=True, text=True, check=True)
                
                windows = []
                for window_line in windows_result.stdout.strip().split('\n'):
                    if not window_line:
                        continue
                    window_index, window_name, window_active = window_line.split(':')
                    windows.append(TmuxWindow(
                        session_name=session_name,
                        window_index=int(window_index),
                        window_name=window_name,
                        active=window_active == '1'
                    ))
                
                sessions.append(TmuxSession(
                    name=session_name,
                    windows=windows,
                    attached=attached == '1'
                ))
            
            return sessions
        except subprocess.CalledProcessError as e:
            print(f"Error getting tmux sessions: {e}")
            return []
    
    def capture_window_content(self, session_name: str, window_index: int, num_lines: int = 50) -> str:
        """Safely capture the last N lines from a tmux window"""
        if num_lines > self.max_lines_capture:
            num_lines = self.max_lines_capture
            
        try:
            cmd = ["tmux", "capture-pane", "-t", f"{session_name}:{window_index}", "-p", "-S", f"-{num_lines}"]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            return f"Error capturing window content: {e}"
    
    def get_window_info(self, session_name: str, window_index: int) -> Dict:
        """Get detailed information about a specific window"""
        try:
            cmd = ["tmux", "display-message", "-t", f"{session_name}:{window_index}", "-p", 
                   "#{window_name}:#{window_active}:#{window_panes}:#{window_layout}"]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            
            if result.stdout.strip():
                parts = result.stdout.strip().split(':')
                return {
                    "name": parts[0],
                    "active": parts[1] == '1',
                    "panes": int(parts[2]),
                    "layout": parts[3],
                    "content": self.capture_window_content(session_name, window_index)
                }
        except subprocess.CalledProcessError as e:
            return {"error": f"Could not get window info: {e}"}
    
    def send_keys_to_window(self, session_name: str, window_index: int, keys: str, confirm: bool = True) -> bool:
        """Safely send keys to a tmux window with confirmation"""
        if self.safety_mode and confirm:
            print(f"SAFETY CHECK: About to send '{keys}' to {session_name}:{window_index}")
            response = input("Confirm? (yes/no): ")
            if response.lower() != 'yes':
                print("Operation cancelled")
                return False
        
        try:
            cmd = ["tmux", "send-keys", "-t", f"{session_name}:{window_index}", keys]
            subprocess.run(cmd, check=True)
            return True
        except subprocess.CalledProcessError as e:
            print(f"Error sending keys: {e}")
            return False
    
    def send_command_to_window(self, session_name: str, window_index: int, command: str, confirm: bool = True) -> bool:
        """Send a command to a window (adds Enter automatically)"""
        # First send the command text
        if not self.send_keys_to_window(session_name, window_index, command, confirm):
            return False
        # Then send the actual Enter key (C-m)
        try:
            cmd = ["tmux", "send-keys", "-t", f"{session_name}:{window_index}", "C-m"]
            subprocess.run(cmd, check=True)
            return True
        except subprocess.CalledProcessError as e:
            print(f"Error sending Enter key: {e}")
            return False
    
    def get_all_windows_status(self) -> Dict:
        """Get status of all windows across all sessions"""
        sessions = self.get_tmux_sessions()
        status = {
            "timestamp": datetime.now().isoformat(),
            "sessions": []
        }
        
        for session in sessions:
            session_data = {
                "name": session.name,
                "attached": session.attached,
                "windows": []
            }
            
            for window in session.windows:
                window_info = self.get_window_info(session.name, window.window_index)
                window_data = {
                    "index": window.window_index,
                    "name": window.window_name,
                    "active": window.active,
                    "info": window_info
                }
                session_data["windows"].append(window_data)
            
            status["sessions"].append(session_data)
        
        return status
    
    def find_window_by_name(self, window_name: str) -> List[Tuple[str, int]]:
        """Find windows by name across all sessions"""
        sessions = self.get_tmux_sessions()
        matches = []
        
        for session in sessions:
            for window in session.windows:
                if window_name.lower() in window.window_name.lower():
                    matches.append((session.name, window.window_index))
        
        return matches
    
    def create_monitoring_snapshot(self) -> str:
        """Create a comprehensive snapshot for Claude analysis"""
        status = self.get_all_windows_status()

        # Format for Claude consumption
        snapshot = f"Tmux Monitoring Snapshot - {status['timestamp']}\n"
        snapshot += "=" * 50 + "\n\n"

        for session in status['sessions']:
            snapshot += f"Session: {session['name']} ({'ATTACHED' if session['attached'] else 'DETACHED'})\n"
            snapshot += "-" * 30 + "\n"

            for window in session['windows']:
                snapshot += f"  Window {window['index']}: {window['name']}"
                if window['active']:
                    snapshot += " (ACTIVE)"
                snapshot += "\n"

                if 'content' in window['info']:
                    # Get last 10 lines for overview
                    content_lines = window['info']['content'].split('\n')
                    recent_lines = content_lines[-10:] if len(content_lines) > 10 else content_lines
                    snapshot += "    Recent output:\n"
                    for line in recent_lines:
                        if line.strip():
                            snapshot += f"    | {line}\n"
                snapshot += "\n"

        return snapshot

    # ===== Podman Container Support =====

    def has_podman(self) -> bool:
        """Check if Podman is available"""
        return shutil.which('podman') is not None

    def get_podman_containers(self, all_containers: bool = False) -> List[PodmanContainer]:
        """Get list of Podman containers (running or all)"""
        if not self.has_podman():
            return []

        try:
            cmd = ["podman", "ps", "--format", "json"]
            if all_containers:
                cmd.append("-a")

            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            containers_data = json.loads(result.stdout)

            containers = []
            for container in containers_data:
                containers.append(PodmanContainer(
                    name=container.get('Names', ['unknown'])[0] if isinstance(container.get('Names'), list) else container.get('Names', 'unknown'),
                    status=container.get('State', 'unknown'),
                    image=container.get('Image', 'unknown'),
                    created=container.get('Created', 'unknown')
                ))

            return containers
        except subprocess.CalledProcessError as e:
            print(f"Error getting Podman containers: {e}")
            return []
        except json.JSONDecodeError as e:
            print(f"Error parsing Podman output: {e}")
            return []

    def exec_in_container(self, container_name: str, command: List[str]) -> Tuple[bool, str]:
        """Execute command in a Podman container"""
        if not self.has_podman():
            return False, "Podman not available"

        try:
            cmd = ["podman", "exec", container_name] + command
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return True, result.stdout
        except subprocess.CalledProcessError as e:
            return False, f"Error: {e.stderr}"

    def capture_container_tmux_window(self, container_name: str, tmux_target: str, num_lines: int = 50) -> str:
        """Capture tmux window content from inside a container"""
        if num_lines > self.max_lines_capture:
            num_lines = self.max_lines_capture

        success, output = self.exec_in_container(
            container_name,
            ["tmux", "capture-pane", "-t", tmux_target, "-p", "-S", f"-{num_lines}"]
        )

        if success:
            return output
        else:
            return f"Error capturing container window: {output}"

    def send_to_container(self, container_name: str, tmux_target: str, message: str) -> bool:
        """Send message to tmux session inside a container"""
        if not self.has_podman():
            print("Podman not available")
            return False

        try:
            # Send message
            subprocess.run(
                ["podman", "exec", container_name, "tmux", "send-keys", "-t", tmux_target, message],
                check=True
            )
            time.sleep(0.5)
            # Send Enter
            subprocess.run(
                ["podman", "exec", container_name, "tmux", "send-keys", "-t", tmux_target, "Enter"],
                check=True
            )
            return True
        except subprocess.CalledProcessError as e:
            print(f"Error sending to container: {e}")
            return False

    def get_container_tmux_sessions(self, container_name: str) -> List[str]:
        """Get tmux sessions running inside a container"""
        success, output = self.exec_in_container(
            container_name,
            ["tmux", "ls", "-F", "#{session_name}"]
        )

        if success:
            return [line.strip() for line in output.split('\n') if line.strip()]
        else:
            return []

    def is_container_running(self, container_name: str) -> bool:
        """Check if a specific container is running"""
        containers = self.get_podman_containers(all_containers=False)
        return any(c.name == container_name for c in containers)

    def get_comprehensive_status(self) -> Dict:
        """Get status of both host tmux and containerized agents"""
        status = {
            "timestamp": datetime.now().isoformat(),
            "host": {
                "tmux_sessions": []
            },
            "containers": []
        }

        # Get host tmux sessions
        sessions = self.get_tmux_sessions()
        for session in sessions:
            session_data = {
                "name": session.name,
                "attached": session.attached,
                "windows": [
                    {
                        "index": w.window_index,
                        "name": w.window_name,
                        "active": w.active
                    }
                    for w in session.windows
                ]
            }
            status["host"]["tmux_sessions"].append(session_data)

        # Get containerized agents
        if self.has_podman():
            containers = self.get_podman_containers()
            for container in containers:
                container_data = {
                    "name": container.name,
                    "status": container.status,
                    "image": container.image,
                    "tmux_sessions": self.get_container_tmux_sessions(container.name)
                }
                status["containers"].append(container_data)

        return status

if __name__ == "__main__":
    orchestrator = TmuxOrchestrator()
    status = orchestrator.get_all_windows_status()
    print(json.dumps(status, indent=2))