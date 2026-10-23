import subprocess
import os
import json
from typing import List, Optional
from pathlib import Path

from app.core.config import settings
from app.models.schemas import NodeVersion, VersionStatus, ListResponse, ConfigFileResponse


class NVMService:
    def __init__(self, nvm_dir: str = None):
        self.nvm_dir = nvm_dir or settings.nvm_dir
        self.nvm_script = os.path.join(self.nvm_dir, "nvm.sh")
    
    def _run_nvm(self, args: List[str], capture_output: bool = True) -> tuple[int, str, str]:
        """Run nvm command and return (exit_code, stdout, stderr)."""
        if not os.path.exists(self.nvm_script):
            return 1, "", f"NVM script not found at {self.nvm_script}"
        
        # Source nvm.sh and run command
        cmd = f"source '{self.nvm_script}' && nvm {' '.join(args)}"
        try:
            result = subprocess.run(
                ["bash", "-c", cmd],
                capture_output=capture_output,
                text=True,
                timeout=120,
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return 1, "", "Command timed out"
        except Exception as e:
            return 1, "", str(e)
    
    def is_available(self) -> bool:
        """Check if NVM is installed and available."""
        exit_code, _, _ = self._run_nvm(["--version"])
        return exit_code == 0
    
    def get_version(self) -> Optional[str]:
        """Get NVM version."""
        exit_code, stdout, _ = self._run_nvm(["--version"])
        if exit_code == 0:
            return stdout.strip()
        return None
    
    def list_installed(self) -> List[NodeVersion]:
        """List installed Node.js versions."""
        exit_code, stdout, _ = self._run_nvm(["ls", "--no-colors"])
        versions = []
        current_version = None
        default_version = None
        
        if exit_code == 0:
            lines = stdout.strip().split('\n')
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                
                is_current = '->' in line
                clean_line = line.replace('->', '').strip()
                
                # Check for aliases
                if 'default' in clean_line and '->' in clean_line:
                    # Parse default alias
                    parts = clean_line.split('->')
                    if len(parts) == 2:
                        default_version = parts[1].strip().split()[0]
                        continue
                
                if clean_line in ('system', 'node', 'stable', 'unstable', 'iojs'):
                    continue
                
                if clean_line.startswith('v'):
                    version = clean_line
                    versions.append(NodeVersion(
                        version=version,
                        status=VersionStatus.ACTIVE if is_current else VersionStatus.INSTALLED,
                        is_current=is_current,
                    ))
        
        return versions
    
    def list_remote(self, lts_only: bool = False) -> List[NodeVersion]:
        """List available remote versions."""
        args = ["ls-remote"]
        if lts_only:
            args.append("--lts")
        else:
            args.append("--no-colors")
        
        exit_code, stdout, _ = self._run_nvm(args)
        versions = []
        
        if exit_code == 0:
            lines = stdout.strip().split('\n')
            for line in lines:
                line = line.strip()
                if not line or line.startswith('N/A'):
                    continue
                if line.startswith('v'):
                    versions.append(NodeVersion(
                        version=line,
                        status=VersionStatus.LTS if lts_only else VersionStatus.AVAILABLE,
                    ))
        
        return versions
    
    def install(self, version: str, force: bool = False) -> tuple[bool, str, Optional[str]]:
        """Install a Node.js version."""
        args = ["install", version]
        if force:
            args.append("--force")
        
        exit_code, stdout, stderr = self._run_nvm(args)
        success = exit_code == 0
        message = "Installation successful" if success else f"Installation failed: {stderr}"
        return success, message, stdout if success else stderr
    
    def use(self, version: Optional[str] = None) -> tuple[bool, str, Optional[str]]:
        """Switch to a Node.js version."""
        args = ["use"]
        if version:
            args.append(version)
        
        exit_code, stdout, stderr = self._run_nvm(args)
        success = exit_code == 0
        if success:
            message = f"Switched to {version or 'auto-detected version'}"
        else:
            message = f"Failed to switch: {stderr}"
        return success, message, stdout if success else stderr
    
    def current(self) -> Optional[str]:
        """Get current Node.js version."""
        exit_code, stdout, _ = self._run_nvm(["current"])
        if exit_code == 0:
            return stdout.strip()
        return None
    
    def alias_default(self, version: str) -> tuple[bool, str]:
        """Set default Node.js version."""
        exit_code, stdout, stderr = self._run_nvm(["alias", "default", version])
        success = exit_code == 0
        message = "Default version set" if success else f"Failed: {stderr}"
        return success, message
    
    def uninstall(self, version: str) -> tuple[bool, str]:
        """Uninstall a Node.js version."""
        exit_code, stdout, stderr = self._run_nvm(["uninstall", version])
        success = exit_code == 0
        message = "Uninstall successful" if success else f"Failed: {stderr}"
        return success, message
    
    def get_config_files(self, cwd: str = None) -> ConfigFileResponse:
        """Detect config files in directory."""
        target_dir = cwd or os.getcwd()
        response = ConfigFileResponse()
        
        # Check .nvmrc
        nvmrc_path = Path(target_dir) / ".nvmrc"
        if nvmrc_path.exists():
            response.nvmrc = nvmrc_path.read_text().strip()
            response.detected_version = response.nvmrc
        
        # Check .node-version
        node_version_path = Path(target_dir) / ".node-version"
        if node_version_path.exists():
            response.node_version = node_version_path.read_text().strip()
            if not response.detected_version:
                response.detected_version = response.node_version
        
        # Check package.json
        package_json_path = Path(target_dir) / "package.json"
        if package_json_path.exists():
            try:
                data = json.loads(package_json_path.read_text())
                engines = data.get("engines", {})
                if "node" in engines:
                    response.package_json = engines["node"]
                    if not response.detected_version:
                        response.detected_version = response.package_json
            except Exception:
                pass
        
        return response
    
    def get_full_list(self) -> ListResponse:
        """Get complete version list with current and default."""
        installed = self.list_installed()
        current = self.current()
        default = None
        
        # Get default from alias
        exit_code, stdout, _ = self._run_nvm(["alias", "default"])
        if exit_code == 0 and stdout.strip():
            default = stdout.strip().split('->')[-1].strip()
        
        return ListResponse(
            versions=installed,
            current=current,
            default=default,
        )


nvm_service = NVMService()