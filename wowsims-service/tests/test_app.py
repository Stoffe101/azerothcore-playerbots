import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import app


MANIFEST = {
    "engines": {
        "VANILLA": {"repository": "wowsims/classic", "commit": "classic-pin"},
        "TBC": {"repository": "wowsims/tbc-new", "commit": "tbc-pin"},
        "WOTLK": {"repository": "wowsims/wotlk", "commit": "wotlk-pin"},
    }
}


class AppTests(unittest.TestCase):
    def test_normalize_era(self):
        self.assertEqual(app.normalize_era("wotlk"), "WOTLK")
        with self.assertRaises(app.ServiceError):
            app.normalize_era("cata")

    def test_extract_metric(self):
        result = {"raidMetrics": {"dps": {"avg": 5042.5}, "hps": {"avg": 12}}}
        self.assertEqual(app.extract_metric(result, "dps"), 5042.5)
        self.assertEqual(app.extract_metric(result, "hps"), 12.0)

    def test_compare_returns_delta_and_pin(self):
        runner = app.SimRunner(
            MANIFEST,
            timeout_seconds=1,
            binaries={"VANILLA": "/x", "TBC": "/x", "WOTLK": "/x"},
        )
        results = [
            {"raidMetrics": {"dps": {"avg": 5040.0}}},
            {"raidMetrics": {"dps": {"avg": 5122.0}}},
        ]
        with mock.patch.object(runner, "simulate", side_effect=results) as simulate:
            out = runner.compare("WOTLK", {"baseline": 1}, {"candidate": 1})
        self.assertEqual(simulate.call_count, 2)
        self.assertEqual(out["delta"], 82.0)
        self.assertAlmostEqual(out["deltaPercent"], 82.0 / 5040.0 * 100.0)
        self.assertEqual(out["engine"]["commit"], "wotlk-pin")

    def test_simulate_uses_fixed_binary_without_shell(self):
        with tempfile.TemporaryDirectory() as tmp:
            binary = Path(tmp) / "wowsimcli"
            binary.write_text("#!/bin/sh\n", encoding="utf-8")
            binary.chmod(0o755)
            runner = app.SimRunner(
                MANIFEST,
                timeout_seconds=1,
                binaries={
                    "VANILLA": str(binary),
                    "TBC": str(binary),
                    "WOTLK": str(binary),
                },
            )
            completed = mock.Mock(
                returncode=0,
                stdout=json.dumps({"raidMetrics": {}}),
                stderr="",
            )
            with mock.patch("app.subprocess.run", return_value=completed) as run:
                result = runner.simulate(
                    "VANILLA",
                    {"raid": {}, "encounter": {}, "simOptions": {}},
                )
            self.assertIn("raidMetrics", result)
            command = run.call_args.args[0]
            self.assertEqual(command[0], str(binary))
            self.assertEqual(command[1:3], ["sim", "--infile"])
            self.assertNotIn("shell", run.call_args.kwargs)

    def test_health_requires_all_three_binaries(self):
        runner = app.SimRunner(
            MANIFEST,
            timeout_seconds=1,
            binaries={
                "VANILLA": "/missing-a",
                "TBC": "/missing-b",
                "WOTLK": "/missing-c",
            },
        )
        self.assertFalse(runner.health()["ready"])

    def test_load_manifest_rejects_missing_era(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "sources.json"
            path.write_text(
                json.dumps({"engines": {"WOTLK": {}}}),
                encoding="utf-8",
            )
            with self.assertRaises(RuntimeError):
                app.load_manifest(path)


if __name__ == "__main__":
    unittest.main()
