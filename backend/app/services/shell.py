import subprocess
import shlex
from typing import List, Tuple, Optional
from pathlib import Path


class ShellService:
    """Utility service for executing shell commands safely."""
    
    def __init__(self, timeout: int = 120):
        self.timeout = timeout
    
    def run(
        self, 
        command: str, 
        cwd: Optional[str] = None,
        env: Optional[dict] = None,
        shell: bool = True
    ) -> Tuple[int, str, str]:
        """Run a shell command and return (exit_code, stdout, stderr)."""
        try:
            result = subprocess.run(
                command,
                shell=shell,
                cwd=cwd,
                env=env,
                capture_output=True,
                text=True,
                timeout=self.timeout,
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return 1, "", f"Command timed out after {self.timeout}s"
        except Exception as e:
            return 1, "", str(e)
    
    def run_capture(
        self, 
        args: List[str], 
        cwd: Optional[str] = None,
        env: Optional[dict] = None
    ) -> Tuple[int, str, str]:
        """Run a command with explicit arguments (no shell)."""
        try:
            result = subprocess.run(
                args,
                cwd=cwd,
                env=env,
                capture_output=True,
                text=True,
                timeout=self.timeout,
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return 1, "", f"Command timed out after {self.timeout}s"
        except Exception as e:
            return 1, "", str(e)
    
    def which(self, command: str) -> Optional[str]:
        """Find executable in PATH."""
        from shutil import which
        return which(command)
    
    def check_command_exists(self, command: str) -> bool:
        """Check if a command exists in PATH."""
        return self.which(command) is not None
    
    def get_env(self, key: str, default: Optional[str] = None) -> Optional[str]:
        """Get environment variable with optional default."""
        import os
        return os.environ.get(key, default)
    
    def expand_user(self, path: str) -> str:
        """Expand ~ and environment variables in path."""
        return str(Path(path).expanduser())


shell_service = ShellService()