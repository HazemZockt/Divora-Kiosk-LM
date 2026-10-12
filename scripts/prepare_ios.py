"""Add the local notification bridge to the pinned Godot 4.5.1 Xcode template.

The existing dummy.cpp contains generated Godot plugin initialization; preserve
all of it and compile the combined source as Objective-C++ rather than C++.
Fail closed if a future template changes the expected references.
"""
from pathlib import Path
import re
import sys
import plistlib


def prepare(project: Path, source: Path) -> None:
    pbx = project / "project.pbxproj"
    text = pbx.read_text()
    dummy_files = list(project.parent.rglob("dummy.cpp"))
    if len(dummy_files) != 1 or text.count("path = dummy.cpp;") != 1:
        raise ValueError("Unexpected Godot template: expected one dummy.cpp")
    dummy = dummy_files[0]
    combined = dummy.read_text() + "\n" + source.read_text()
    target = dummy.with_name("divora_notifications.mm")
    updated = text.replace("dummy.cpp", target.name)
    updated, count = re.subn(
        r"(lastKnownFileType = )sourcecode\.cpp\.cpp(; path = divora_notifications\.mm;)",
        r"\1sourcecode.cpp.objcpp\2", updated,
    )
    if count != 1:
        raise ValueError("Expected exactly one C++ file reference")
    updated, count = re.subn(
        r'(OTHER_LDFLAGS = ")([^"\n]*)(";)',
        r'\1\2 -framework UserNotifications\3', updated,
    )
    if count != 2:
        raise ValueError("Expected Debug and Release linker settings")
    target.write_text(combined)
    pbx.write_text(updated)
    # Keep iPhone portrait; iPad windows may resize/rotate around the centered UI.
    plists = list(dummy.parent.glob("*-Info.plist"))
    if len(plists) != 1:
        raise ValueError("Expected one application Info.plist")
    plist = plistlib.loads(plists[0].read_bytes())
    plist["UIRequiresFullScreen"] = False
    plist["UISupportedInterfaceOrientations~ipad"] = [
        "UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown",
        "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight",
    ]
    plists[0].write_bytes(plistlib.dumps(plist))
    print(f"Native notifications integrated: {target}")


if __name__ == "__main__":
    prepare(Path(sys.argv[1]), Path(__file__).resolve().parents[1] / "platform/ios/DivoraNotifications.mm")
