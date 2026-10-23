import re
from typing import List, Optional, Tuple
from packaging import version as pkg_version


def normalize_version(version: str) -> str:
    """Normalize version string by removing 'v' prefix and ensuring proper format."""
    v = version.strip()
    if v.startswith('v'):
        v = v[1:]
    return v


def parse_version(version: str) -> Tuple[int, ...]:
    """Parse version string into tuple of integers for comparison."""
    normalized = normalize_version(version)
    # Handle semver with possible pre-release/build metadata
    match = re.match(r'^(\d+)\.(\d+)\.(\d+)', normalized)
    if match:
        return tuple(map(int, match.groups()))
    return (0, 0, 0)


def compare_versions(v1: str, v2: str) -> int:
    """Compare two version strings. Returns -1 if v1 < v2, 0 if equal, 1 if v1 > v2."""
    try:
        return -1 if pkg_version.parse(normalize_version(v1)) < pkg_version.parse(normalize_version(v2)) else (1 if pkg_version.parse(normalize_version(v1)) > pkg_version.parse(normalize_version(v2)) else 0)
    except Exception:
        # Fallback to tuple comparison
        t1 = parse_version(v1)
        t2 = parse_version(v2)
        if t1 < t2:
            return -1
        elif t1 > t2:
            return 1
        return 0


def version_satisfies(version: str, requirement: str) -> bool:
    """Check if a version satisfies a requirement (basic semver support)."""
    try:
        from packaging.specifiers import SpecifierSet
        spec = SpecifierSet(requirement)
        return pkg_version.parse(normalize_version(version)) in spec
    except Exception:
        # Simple fallback for basic comparisons
        if requirement.startswith('>='):
            return compare_versions(version, requirement[2:]) >= 0
        elif requirement.startswith('<='):
            return compare_versions(version, requirement[2:]) <= 0
        elif requirement.startswith('>'):
            return compare_versions(version, requirement[1:]) > 0
        elif requirement.startswith('<'):
            return compare_versions(version, requirement[1:]) < 0
        elif requirement.startswith('=') or requirement.startswith('^') or requirement.startswith('~'):
            # Basic prefix match
            req_ver = requirement.lstrip('=^~')
            return version.startswith(req_ver)
        return version == requirement


def get_lts_name(version: str) -> Optional[str]:
    """Get LTS codename for a Node.js version."""
    normalized = normalize_version(version)
    major = normalized.split('.')[0]
    
    lts_map = {
        '4': 'argon',
        '6': 'boron',
        '8': 'carbon',
        '10': 'dubnium',
        '12': 'erbium',
        '14': 'fermium',
        '16': 'gallium',
        '18': 'hydrogen',
        '20': 'iron',
        '22': 'jod',
    }
    return lts_map.get(major)


def sort_versions(versions: List[str], reverse: bool = False) -> List[str]:
    """Sort version strings naturally."""
    return sorted(versions, key=lambda v: parse_version(v), reverse=reverse)


def is_lts_version(version: str) -> bool:
    """Check if a version is an LTS release."""
    return get_lts_name(version) is not None


def extract_version_from_string(text: str) -> Optional[str]:
    """Extract version pattern from text (e.g., 'v20.10.0' from 'Now using node v20.10.0')."""
    match = re.search(r'v?(\d+\.\d+\.\d+)', text)
    if match:
        return f"v{match.group(1)}"
    return None