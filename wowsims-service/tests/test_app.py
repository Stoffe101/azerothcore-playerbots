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
        "VANILLA": {
            "repository": "wowsims/classic",
            "commit": "7779ebbf79dc7f1341e6ab939b28a3402c9a730a",
        },
        "TBC": {
            "repository": "wowsims/tbc-new",
            "commit": "a4768c9d7ed51f4e49b8e90425f68ab47bde0cbc",
        },
        "WOTLK": {
            "repository": "wowsims/wotlk",
            "commit": "563e4a08cb15729f1fdcbcf68e6d68224553bfef",
        },
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
        self.assertEqual(
            out["engine"]["commit"],
            "563e4a08cb15729f1fdcbcf68e6d68224553bfef",
        )

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

    def _snapshot(self):
        gear = [None] * 17
        gear[0] = {
            "slot": "HEAD",
            "id": 40416,
            "enchant": 3819,
            "gems": [41398, 40058, 0],
            "randomPropertyId": 0,
            "suffixFactor": 0,
        }
        return {
            "schema": 1,
            "era": "WOTLK",
            "realmLevelCap": 80,
            "character": {
                "guid": 1,
                "name": "Tester",
                "level": 80,
                "classId": 8,
                "class": "MAGE",
                "raceId": 1,
                "race": "HUMAN",
                "role": "DPS",
                "activeSpecSlot": 0,
                "dominantTree": 0,
                "treePoints": [57, 3, 11],
                "talents": "23000513310033015032310250532-03-023303001",
                "gear": gear,
                "glyphs": [],
                "professions": [],
            },
        }

    def test_snapshot_validation_routes_model_without_claiming_authority(self):
        out = app.validate_character_snapshot(self._snapshot())
        self.assertTrue(out["valid"])
        self.assertEqual(out["era"], "WOTLK")
        self.assertEqual(out["character"]["spec"], "arcane")
        self.assertEqual(out["support"]["status"], "ENGINE_PRESENT_UNVALIDATED")
        self.assertEqual(out["support"]["protoSpecField"], "mage")
        self.assertIn("mage:arcane:dps", out["support"]["modelKey"])

    def test_catalog_routes_are_era_specific(self):
        vanilla = self._snapshot()
        vanilla["era"] = "VANILLA"
        vanilla["character"]["level"] = 60
        vanilla["character"]["classId"] = 7
        vanilla["character"]["class"] = "SHAMAN"
        vanilla["character"]["dominantTree"] = 1
        vanilla["character"]["treePoints"] = [0, 51, 0]
        vanilla["character"]["role"] = "TANK"
        out = app.validate_character_snapshot(vanilla)
        self.assertEqual(out["support"]["protoSpecField"], "warden_shaman")

        tbc = self._snapshot()
        tbc["era"] = "TBC"
        tbc["character"]["level"] = 70
        tbc["character"]["classId"] = 1
        tbc["character"]["class"] = "WARRIOR"
        tbc["character"]["dominantTree"] = 2
        tbc["character"]["treePoints"] = [0, 0, 41]
        tbc["character"]["role"] = "TANK"
        out = app.validate_character_snapshot(tbc)
        self.assertEqual(out["support"]["protoSpecField"], "protection_warrior")

    def test_catalog_returns_unsupported_instead_of_inventing_model(self):
        payload = self._snapshot()
        payload["character"]["role"] = "TANK"
        out = app.validate_character_snapshot(payload)
        self.assertTrue(out["valid"])
        self.assertEqual(out["support"]["status"], "UNSUPPORTED")
        self.assertNotIn("protoSpecField", out["support"])

    def test_model_catalog_pins_match_engine_manifest(self):
        support = app.load_model_support(manifest=MANIFEST)
        self.assertEqual(
            support["eras"]["WOTLK"]["commit"],
            MANIFEST["engines"]["WOTLK"]["commit"],
        )

    def test_preset_catalog_optional_when_not_built(self):
        with tempfile.TemporaryDirectory() as tmp:
            catalog = app.load_preset_catalog(tmp, manifest=MANIFEST, required=False)
        self.assertFalse(catalog["eras"]["WOTLK"]["ready"])

    def test_preset_catalog_validates_pins_and_routes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for era, engine in MANIFEST["engines"].items():
                era_dir = root / era
                request_dir = era_dir / "requests"
                request_dir.mkdir(parents=True)
                request_file = request_dir / "sample.json"
                request_file.write_text("{}\n", encoding="utf-8")
                (era_dir / "preset-index.json").write_text(
                    json.dumps(
                        {
                            "schema": 1,
                            "era": era,
                            "engineCommit": engine["commit"],
                            "routeCount": 1,
                            "requestCount": 1,
                            "routes": {
                                "8:0:DPS": [
                                    {
                                        "file": "requests/sample.json",
                                        "sha256": "abc",
                                    }
                                ]
                            },
                        }
                    ),
                    encoding="utf-8",
                )
            catalog = app.load_preset_catalog(root, manifest=MANIFEST, required=True)
            summary = app.preset_catalog_summary(catalog)
        self.assertTrue(summary["eras"]["WOTLK"]["ready"])
        self.assertEqual(summary["eras"]["WOTLK"]["requestCount"], 1)
        self.assertEqual(summary["eras"]["WOTLK"]["selectableRouteCount"], 1)

    def test_preset_catalog_rejects_pin_drift(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            era_dir = root / "WOTLK"
            era_dir.mkdir(parents=True)
            (era_dir / "preset-index.json").write_text(
                json.dumps(
                    {
                        "schema": 1,
                        "era": "WOTLK",
                        "engineCommit": "wrong",
                        "routes": {"8:0:DPS": [{"file": "x", "sha256": "y"}]},
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaises(RuntimeError):
                app.load_preset_catalog(root, manifest=MANIFEST, required=False)

    def _preset_catalog(self, root, era, route_key, requests, canonical_index=0):
        route_entries = []
        era_dir = Path(root) / era
        request_dir = era_dir / "requests"
        request_dir.mkdir(parents=True)
        for index, request in enumerate(requests):
            digest = app._canonical_request_sha256(request)
            filename = f"sample-{index}.json"
            (request_dir / filename).write_text(
                json.dumps(request, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            route_entries.append(
                {
                    "file": f"requests/{filename}",
                    "sha256": digest,
                    "source": f"unit-{index}",
                    "protoSpecField": "mage",
                    "canonical": index == canonical_index,
                    "selectionMethod": "unit-test-policy" if index == canonical_index else None,
                    "assumptionsSha256": digest,
                    "talentsString": request["raid"]["parties"][0]["players"][0].get("talentsString", ""),
                    "phase": None,
                    "variantCanonical": index == canonical_index,
                }
            )
        return {
            "root": str(root),
            "required": True,
            "eras": {
                "VANILLA": {"ready": era == "VANILLA", "routes": {}},
                "TBC": {"ready": era == "TBC", "routes": {}},
                "WOTLK": {"ready": era == "WOTLK", "routes": {}},
            },
        } | {
            "eras": {
                key: (
                    {
                        "ready": True,
                        "routes": {route_key: route_entries},
                        "routePolicies": {
                            route_key: {
                                "type": "static",
                                "selectedSha256": route_entries[canonical_index]["sha256"],
                            }
                        },
                    }
                    if key == era
                    else {"ready": False, "routes": {}}
                )
                for key in ("VANILLA", "TBC", "WOTLK")
            }
        }

    def _wotlk_preset(self):
        return {
            "raid": {
                "buffs": {"arcaneBrilliance": True},
                "parties": [
                    {
                        "players": [
                            {
                                "name": "Preset Mage",
                                "race": "RaceGnome",
                                "class": "ClassMage",
                                "equipment": {"items": [{"id": 1}]},
                                "consumes": {"flask": "FlaskOfTheFrostWyrm"},
                                "talentsString": "preset",
                                "glyphs": {"major1": 1},
                                "profession1": "Engineering",
                                "profession2": "Tailoring",
                                "rotation": {"type": "Auto"},
                                "mage": {"options": {"armor": "MoltenArmor"}},
                            }
                        ]
                    }
                ],
            },
            "encounter": {"duration": 180},
            "simOptions": {"iterations": 1000},
        }

    def test_build_baseline_request_overlays_character_and_preserves_preset_assumptions(self):
        snapshot = self._snapshot()
        snapshot["character"]["glyphs"] = [
            {"slot": 0, "spellId": 1001, "typeFlags": 0},
            {"slot": 3, "spellId": 2001, "typeFlags": 1},
        ]
        snapshot["character"]["professions"] = [
            {"skillId": 202, "name": "ENGINEERING", "level": 450},
            {"skillId": 197, "name": "TAILORING", "level": 450},
        ]
        preset = self._wotlk_preset()
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [preset])
            out = app.build_baseline_request(
                snapshot,
                app.load_model_support(manifest=MANIFEST),
                catalog,
                {1001: 44955, 2001: 43364},
            )

        self.assertEqual(out["status"], "REQUEST_BUILT_UNVALIDATED")
        self.assertEqual(out["routeKey"], "8:0:DPS")
        player = out["request"]["raid"]["parties"][0]["players"][0]
        self.assertEqual(player["name"], "Tester")
        self.assertEqual(player["race"], "RaceHuman")
        self.assertEqual(player["class"], "ClassMage")
        self.assertEqual(player["talentsString"], snapshot["character"]["talents"])
        self.assertEqual(player["equipment"]["items"][0]["id"], 40416)
        self.assertEqual(len(player["equipment"]["items"]), 17)
        self.assertEqual(player["equipment"]["items"][1], {})
        self.assertEqual(player["glyphs"]["major1"], 44955)
        self.assertEqual(player["glyphs"]["minor1"], 43364)
        self.assertEqual(player["profession1"], "Engineering")
        self.assertEqual(player["profession2"], "Tailoring")
        self.assertEqual(player["rotation"], {"type": "Auto"})
        self.assertEqual(player["mage"], {"options": {"armor": "MoltenArmor"}})
        self.assertEqual(player["consumes"], {"flask": "FlaskOfTheFrostWyrm"})
        self.assertEqual(out["request"]["raid"]["buffs"], {"arcaneBrilliance": True})
        self.assertEqual(out["request"]["encounter"], {"duration": 180})
        self.assertEqual(out["request"]["simOptions"], {"iterations": 1000})

    def test_build_baseline_request_uses_canonical_choice_for_ambiguous_route(self):
        snapshot = self._snapshot()
        preset = self._wotlk_preset()
        alternate = self._wotlk_preset()
        alternate["encounter"] = {"duration": 240}
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [preset, alternate], canonical_index=1)
            out = app.build_baseline_request(snapshot, app.load_model_support(manifest=MANIFEST), catalog, {})
            explicit = catalog["eras"]["WOTLK"]["routes"]["8:0:DPS"][0]["sha256"]
            overridden = app.build_baseline_request(
                snapshot, app.load_model_support(manifest=MANIFEST), catalog, {}, preset_sha256=explicit
            )
        self.assertEqual(out["request"]["encounter"]["duration"], 240)
        self.assertTrue(out["preset"]["canonical"])
        self.assertEqual(out["preset"]["selection"], "static")
        self.assertEqual(out["preset"]["selectionMethod"], "unit-test-policy")
        self.assertEqual(overridden["request"]["encounter"]["duration"], 180)
        self.assertEqual(overridden["preset"]["selection"], "explicit")
        self.assertFalse(overridden["preset"]["canonical"])


    def test_build_baseline_request_selects_closest_talent_variant(self):
        snapshot = self._snapshot()
        first = self._wotlk_preset()
        second = self._wotlk_preset()
        first["raid"]["parties"][0]["players"][0]["talentsString"] = "50000-00000-00000"
        second["raid"]["parties"][0]["players"][0]["talentsString"] = snapshot["character"]["talents"]
        first["encounter"] = {"duration": 120}
        second["encounter"] = {"duration": 240}
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [first, second])
            entries = catalog["eras"]["WOTLK"]["routes"]["8:0:DPS"]
            for entry in entries:
                entry["variantCanonical"] = True
            catalog["eras"]["WOTLK"]["routePolicies"]["8:0:DPS"] = {
                "type": "closest-live-talents",
                "variantSha256": [entry["sha256"] for entry in entries],
            }
            out = app.build_baseline_request(
                snapshot,
                app.load_model_support(manifest=MANIFEST),
                catalog,
                {},
            )
        self.assertEqual(out["request"]["encounter"]["duration"], 240)
        self.assertEqual(out["preset"]["selection"], "closest-live-talents")


    def test_build_baseline_request_rejects_tied_talent_variant(self):
        snapshot = self._snapshot()
        first = self._wotlk_preset()
        second = self._wotlk_preset()
        first["raid"]["parties"][0]["players"][0]["talentsString"] = "10000-00000-00000"
        second["raid"]["parties"][0]["players"][0]["talentsString"] = "01000-00000-00000"
        snapshot["character"]["talents"] = "00000-00000-00000"
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [first, second])
            entries = catalog["eras"]["WOTLK"]["routes"]["8:0:DPS"]
            catalog["eras"]["WOTLK"]["routePolicies"]["8:0:DPS"] = {
                "type": "closest-live-talents",
                "variantSha256": [entry["sha256"] for entry in entries],
            }
            with self.assertRaisesRegex(app.ServiceError, "tied closest-talent"):
                app.build_baseline_request(
                    snapshot,
                    app.load_model_support(manifest=MANIFEST),
                    catalog,
                    {},
                )


    def test_build_baseline_request_rejects_preset_checksum_drift(self):
        snapshot = self._snapshot()
        preset = self._wotlk_preset()
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [preset])
            catalog["eras"]["WOTLK"]["routes"]["8:0:DPS"][0]["sha256"] = "0" * 64
            catalog["eras"]["WOTLK"]["routePolicies"]["8:0:DPS"]["selectedSha256"] = "0" * 64
            with self.assertRaisesRegex(app.ServiceError, "checksum mismatch"):
                app.build_baseline_request(
                    snapshot,
                    app.load_model_support(manifest=MANIFEST),
                    catalog,
                    {},
                )

    def test_candidate_request_changes_only_selected_equipment_slot(self):
        snapshot = self._snapshot()
        preset = self._wotlk_preset()
        candidate = {
            "id": 40562,
            "enchant": 3819,
            "gems": [41398, 40058, 0],
            "randomPropertyId": 0,
            "suffixFactor": 0,
        }
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [preset])
            out = app.build_candidate_request(
                snapshot,
                candidate,
                0,
                app.load_model_support(manifest=MANIFEST),
                catalog,
                {},
            )

        self.assertEqual(out["status"], "CANDIDATE_REQUEST_BUILT_UNVALIDATED")
        self.assertEqual(out["slotIndex"], 0)
        self.assertTrue(out["changedPaths"])
        self.assertTrue(
            all(
                path == "raid.parties.0.players.0.equipment.items.0"
                or path.startswith("raid.parties.0.players.0.equipment.items.0.")
                for path in out["changedPaths"]
            )
        )
        baseline = out["baselineRequest"]
        changed = out["candidateRequest"]
        self.assertEqual(
            baseline["raid"]["parties"][0]["players"][0]["equipment"]["items"][0]["id"],
            40416,
        )
        self.assertEqual(
            changed["raid"]["parties"][0]["players"][0]["equipment"]["items"][0]["id"],
            40562,
        )
        baseline_copy = json.loads(json.dumps(baseline))
        baseline_copy["raid"]["parties"][0]["players"][0]["equipment"]["items"][0] = (
            changed["raid"]["parties"][0]["players"][0]["equipment"]["items"][0]
        )
        self.assertEqual(baseline_copy, changed)

    def test_candidate_request_rejects_noop_and_invalid_slot(self):
        snapshot = self._snapshot()
        preset = self._wotlk_preset()
        current = dict(snapshot["character"]["gear"][0])
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [preset])
            with self.assertRaisesRegex(app.ServiceError, "no request change"):
                app.build_candidate_request(
                    snapshot,
                    current,
                    0,
                    app.load_model_support(manifest=MANIFEST),
                    catalog,
                    {},
                )
            with self.assertRaisesRegex(app.ServiceError, "slotIndex"):
                app.build_candidate_request(
                    snapshot,
                    current,
                    17,
                    app.load_model_support(manifest=MANIFEST),
                    catalog,
                    {},
                )

    def test_bag_candidate_manifest_reuses_one_baseline_and_fingerprints_swaps(self):
        snapshot = self._snapshot()
        preset = self._wotlk_preset()
        candidates = [
            {
                "bag": 0,
                "slot": 23,
                "item": {
                    "id": 40562,
                    "enchant": 3819,
                    "gems": [41398, 40058, 0],
                    "randomPropertyId": 0,
                    "suffixFactor": 0,
                },
                "slotIndexes": [0, 1],
            }
        ]
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [preset])
            out = app.build_bag_candidate_manifest(
                snapshot,
                candidates,
                app.load_model_support(manifest=MANIFEST),
                catalog,
                {},
            )

        self.assertEqual(out["status"], "BAG_CANDIDATES_BUILT_UNVALIDATED")
        self.assertEqual(out["candidateCount"], 1)
        self.assertEqual(out["swapCount"], 2)
        self.assertEqual(out["skippedCount"], 0)
        self.assertEqual(len(out["baselineFingerprint"]), 64)
        self.assertEqual(len(out["swaps"][0]["candidateFingerprint"]), 64)
        self.assertNotEqual(
            out["baselineFingerprint"],
            out["swaps"][0]["candidateFingerprint"],
        )
        self.assertTrue(
            all(
                path == "raid.parties.0.players.0.equipment.items.0"
                or path.startswith("raid.parties.0.players.0.equipment.items.0.")
                for path in out["swaps"][0]["changedPaths"]
            )
        )

    def test_bag_candidate_manifest_skips_noop_and_rejects_duplicate_slots(self):
        snapshot = self._snapshot()
        preset = self._wotlk_preset()
        current = dict(snapshot["character"]["gear"][0])
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [preset])
            out = app.build_bag_candidate_manifest(
                snapshot,
                [{"bag": 0, "slot": 23, "item": current, "slotIndexes": [0]}],
                app.load_model_support(manifest=MANIFEST),
                catalog,
                {},
            )
            self.assertEqual(out["swapCount"], 0)
            self.assertEqual(out["skippedCount"], 1)
            self.assertEqual(out["skipped"][0]["reason"], "NO_CHANGE")

            with self.assertRaisesRegex(app.ServiceError, "must not contain duplicates"):
                app.build_bag_candidate_manifest(
                    snapshot,
                    [{"bag": 0, "slot": 23, "item": current, "slotIndexes": [0, 0]}],
                    app.load_model_support(manifest=MANIFEST),
                    catalog,
                    {},
                )

    def test_compare_bag_candidates_runs_baseline_once_and_reuses_it(self):
        snapshot = self._snapshot()
        preset = self._wotlk_preset()
        candidates = [
            {
                "bag": 0,
                "slot": 23,
                "item": {
                    "id": 40562,
                    "enchant": 3819,
                    "gems": [41398, 40058, 0],
                    "randomPropertyId": 0,
                    "suffixFactor": 0,
                },
                "slotIndexes": [0, 1],
            }
        ]
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [preset])
            runner = app.SimRunner(
                MANIFEST,
                timeout_seconds=1,
                binaries={"VANILLA": "/x", "TBC": "/x", "WOTLK": "/x"},
            )
            runner.model_support = app.load_model_support(manifest=MANIFEST)
            runner.preset_catalog = catalog
            runner.glyph_spell_map = {}
            simulated = [
                {"raidMetrics": {"dps": {"avg": 5000.0}}},
                {"raidMetrics": {"dps": {"avg": 5100.0}}},
                {"raidMetrics": {"dps": {"avg": 4950.0}}},
            ]
            with mock.patch.object(runner, "simulate", side_effect=simulated) as simulate:
                out = runner.compare_bag_candidates(snapshot, candidates)

        self.assertEqual(simulate.call_count, 3)
        self.assertEqual(out["status"], "BAG_COMPARE_COMPLETE_UNVALIDATED")
        self.assertEqual(out["metric"], "dps")
        self.assertEqual(out["baseline"], 5000.0)
        self.assertEqual(out["resultCount"], 2)
        self.assertEqual(out["results"][0]["delta"], 100.0)
        self.assertEqual(out["results"][1]["delta"], -50.0)
        self.assertEqual(out["bestUpgrade"]["itemId"], 40562)
        self.assertEqual(out["bestUpgrade"]["slotIndex"], 0)
        self.assertNotIn("candidateRequest", out["results"][0])

    def test_compare_bag_candidates_rejects_tank_without_approved_metric(self):
        snapshot = self._snapshot()
        snapshot["character"]["role"] = "TANK"
        runner = app.SimRunner(
            MANIFEST,
            timeout_seconds=1,
            binaries={"VANILLA": "/x", "TBC": "/x", "WOTLK": "/x"},
        )
        with self.assertRaisesRegex(app.ServiceError, "survivability metric"):
            runner.compare_bag_candidates(snapshot, [])

    def test_wotlk_random_property_state_fails_closed(self):
        snapshot = self._snapshot()
        snapshot["character"]["gear"][0]["randomPropertyId"] = -1979
        preset = self._wotlk_preset()
        with tempfile.TemporaryDirectory() as tmp:
            catalog = self._preset_catalog(tmp, "WOTLK", "8:0:DPS", [preset])
            with self.assertRaisesRegex(app.ServiceError, "pinned WotLK ItemSpec"):
                app.build_baseline_request(
                    snapshot,
                    app.load_model_support(manifest=MANIFEST),
                    catalog,
                    {},
                )

    def test_classic_equipment_maps_suffix_only_and_rejects_random_property(self):
        gear = self._snapshot()["character"]["gear"]
        gear[0]["randomPropertyId"] = -1979
        equipment = app._equipment_from_snapshot("VANILLA", gear)
        self.assertEqual(equipment["items"][0]["randomSuffix"], 1979)
        self.assertNotIn("gems", equipment["items"][0])

        gear[0]["randomPropertyId"] = 42
        with self.assertRaisesRegex(app.ServiceError, "random property 42"):
            app._equipment_from_snapshot("VANILLA", gear)

    def test_wotlk_glyph_map_uses_spell_to_item_and_type_flags(self):
        glyphs = [
            {"slot": 2, "spellId": 54733, "typeFlags": 0},
            {"slot": 5, "spellId": 52648, "typeFlags": 1},
        ]
        out = app._glyphs_from_snapshot(glyphs, {54733: 40909, 52648: 43361})
        self.assertEqual(out["major1"], 40909)
        self.assertEqual(out["minor1"], 43361)
        self.assertEqual(out["major2"], 0)
        with self.assertRaisesRegex(app.ServiceError, "absent from the pinned"):
            app._glyphs_from_snapshot(
                [{"slot": 0, "spellId": 99999, "typeFlags": 0}],
                {},
            )

    def test_professions_are_era_gated(self):
        with self.assertRaisesRegex(app.ServiceError, "JEWELCRAFTING is unavailable in VANILLA"):
            app._professions_from_snapshot(
                "VANILLA",
                [{"name": "JEWELCRAFTING", "skillId": 755, "level": 300}],
            )
        self.assertEqual(
            app._professions_from_snapshot(
                "TBC",
                [{"name": "JEWELCRAFTING", "skillId": 755, "level": 375}],
            ),
            ("Jewelcrafting", "ProfessionUnknown"),
        )

    def test_snapshot_rejects_future_era_class(self):
        payload = self._snapshot()
        payload["era"] = "VANILLA"
        payload["character"]["level"] = 60
        payload["character"]["classId"] = 6
        payload["character"]["class"] = "DEATHKNIGHT"
        with self.assertRaises(app.ServiceError):
            app.validate_character_snapshot(payload)

    def test_snapshot_rejects_wrong_gear_slot_count(self):
        payload = self._snapshot()
        payload["character"]["gear"] = payload["character"]["gear"][:-1]
        with self.assertRaises(app.ServiceError):
            app.validate_character_snapshot(payload)

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
