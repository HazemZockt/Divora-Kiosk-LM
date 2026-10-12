import plistlib
from pathlib import Path
import tempfile
import unittest
from prepare_ios import prepare


class PrepareIOS(unittest.TestCase):
    def test_preserves_generated_code_and_adds_native_source(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            project = root / "App.xcodeproj"
            project.mkdir()
            app = root / "App"
            app.mkdir()
            (app / "dummy.cpp").write_text("void generated_plugin_init() {}")
            plist = {"UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"]}
            (app / "App-Info.plist").write_bytes(plistlib.dumps(plist))
            (project / "project.pbxproj").write_text(
                'dummy.cpp in Sources; lastKnownFileType = sourcecode.cpp.cpp; path = dummy.cpp;\n'
                'OTHER_LDFLAGS = "existing-debug";\nOTHER_LDFLAGS = "existing-release";'
            )
            bridge = root / "bridge.mm"
            bridge.write_text("// native notification bridge")
            prepare(project, bridge)
            source = (app / "divora_notifications.mm").read_text()
            self.assertIn("generated_plugin_init", source)
            self.assertIn("native notification bridge", source)
            text = (project / "project.pbxproj").read_text()
            self.assertIn("sourcecode.cpp.objcpp", text)
            self.assertIn("existing-debug -framework UserNotifications", text)
            output = plistlib.loads((app / "App-Info.plist").read_bytes())
            self.assertFalse(output["UIRequiresFullScreen"])
            self.assertEqual(output["UISupportedInterfaceOrientations"], plist["UISupportedInterfaceOrientations"])
            self.assertEqual(len(output["UISupportedInterfaceOrientations~ipad"]), 4)

    def test_unknown_template_fails_instead_of_silently_omitting_notifications(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            project = root / "App.xcodeproj"
            project.mkdir()
            (project / "project.pbxproj").write_text("changed template")
            with self.assertRaises(ValueError):
                prepare(project, root / "missing.mm")


if __name__ == "__main__":
    unittest.main()
