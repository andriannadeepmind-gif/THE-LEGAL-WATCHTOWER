#!/usr/bin/env python3
"""Structural validator A for the immutable pre-Phase-2 freeze.

This validator proves package integrity and policy-shape consistency only. It does
not prove U_T/D_T closure, global optimality, executable refinement or any theorem.

Exit 0: FREEZE_STRUCTURE_VALID
Exit 1: package/policy invalid
Exit 2: validator self-test failed
"""
from __future__ import annotations

import copy
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SEAL = "REVIEWER-SEAL.json"
VERSION = "2.3.0-R3-PRE-PHASE-2-FROZEN-CANDIDATE"
B0_COMMIT = "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
B0_TREE = "23b7a6f4450f50d151d38e13020bee9872e73bcd"
P1_SHA = "3E927EBA2E90410C47FC955C0B6F704F054630DE141F275CF89A4AB31EAB3E93"
FOC_IDS = [f"FOC-{n:02d}" for n in range(1, 20)]
THEOREMS = ["T1", "T2", "T3", "T4", "T5", "T6", "T7"]
NC_IDS = [f"NC-{n:02d}" for n in range(1, 45)]
COMMERCIAL_IDS = [
    "B-COMM-01-THOMSON-REUTERS-COCOUNSEL-LEGAL",
    "B-COMM-02-LEXISNEXIS-LEXIS-PLUS-WITH-PROTEGE",
    "B-COMM-03-HARVEY",
]
AXIS_IDS = [f"AX-{n:02d}" for n in range(1, 23)]
REQUIRED_FILES = {
    "B7-PRODUCER-SESSION-EVIDENCE-RECOVERY.md",
    "B0-TRANSFORMATION-AND-REPOSITORY-DELTA-SPEC.json",
    "ALL-AXIS-DOMINANCE-SPEC.json",
    "COMMERCIAL-FRONTIER-BASELINES.json",
    "COORDINATOR-LAUNCH-POLICY.json",
    "NEGATIVE-CONTROLS.json",
    "PHASE-2-ANSWER-NEUTRAL-ACCEPTANCE-SPEC.json",
    "PHASE-2-ISOLATION-POLICY.json",
    "PHASE-2-OUTPUT-CONTRACT.json",
    "PROOF-OBLIGATIONS.jsonl",
    "PROOF-OF-CEILING-CONTRACT.json",
    "PROOF-OF-CEILING-CONTRACT.md",
    "REVIEW-RUNBOOK.md",
    "ROLE-SEPARATION.json",
    "UNIVERSAL-ESCALATION-PROTOCOL.json",
    "verify_freeze.mjs",
    "verify_freeze.py",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_json(name: str):
    with open(os.path.join(HERE, name), encoding="utf-8") as handle:
        return json.load(handle)


def read_jsonl(name: str):
    with open(os.path.join(HERE, name), encoding="utf-8") as handle:
        return [json.loads(line) for line in handle if line.strip()]


def semantic_issues(data: dict) -> list[str]:
    c = data["contract"]
    obligations = data["obligations"]
    escalation = data["escalation"]
    acceptance = data["acceptance"]
    output = data["output"]
    isolation = data["isolation"]
    launch = data["launch"]
    roles = data["roles"]
    controls = data["controls"]
    commercial = data["commercial"]
    dominance = data["dominance"]
    transformation = data["transformation"]
    issues: list[str] = []

    def need(condition, message):
        if not condition:
            issues.append(message)

    need(c.get("schema") == "watchtower/proof-of-ceiling-contract/2", "contract schema")
    need(c.get("contract_version") == VERSION, "contract version")
    need(c.get("authoritative") is False, "candidate authority")
    b0 = c.get("baseline_B0", {})
    need(b0.get("commit") == B0_COMMIT and b0.get("tree") == B0_TREE, "B0 binding")
    p1 = c.get("phase_1_binding", {})
    need(p1.get("sha256") == P1_SHA and p1.get("state") == "ACCEPTED", "P1 binding")

    ids = [row.get("id") for row in obligations]
    need(ids == FOC_IDS + THEOREMS, "obligations must be exactly FOC-01..19 then T1..T7")
    need(all(row.get("state") == "BLOCKED" for row in obligations), "obligation pre-discharge")
    id_set = set(ids)
    for row in obligations:
        for dep in row.get("depends_on", []):
            need(dep in id_set, f"dangling dependency {dep} in {row.get('id')}")
    foc16 = next((row for row in obligations if row.get("id") == "FOC-16"), {})
    foc16_text = str(foc16.get("statement", "")).lower()
    need(all(word in foc16_text for word in ("round", "time", "candidate", "greatest-element")), "FOC-16 incomplete")
    foc17 = next((row for row in obligations if row.get("id") == "FOC-17"), {})
    foc17_text = str(foc17.get("statement", "")).lower()
    need(all(word in foc17_text for word in ("continual", "monotonically", "revalidation", "independent")), "FOC-17 incomplete")
    foc18 = next((row for row in obligations if row.get("id") == "FOC-18"), {})
    foc18_text = str(foc18.get("statement", "")).lower()
    need(all(word in foc18_text for word in ("strictly better", "every", "cocounsel", "protégé", "harvey", "unknown")), "FOC-18 incomplete")
    t6 = next((row for row in obligations if row.get("id") == "T6"), {})
    need("StrictBetter" in str(t6.get("statement", "")) and "proper subset" in str(t6.get("statement", "")), "T6 incomplete")
    foc19 = next((row for row in obligations if row.get("id") == "FOC-19"), {})
    foc19_text = str(foc19.get("statement", "")).lower()
    need(all(word in foc19_text for word in ("andrianna", "repository", "refactor", "creator approval", "greenfield")), "FOC-19 incomplete")
    t7 = next((row for row in obligations if row.get("id") == "T7"), {})
    need("Apply(B0,Delta_B0)=E_star" in str(t7.get("statement", "")) and "parallel authority" in str(t7.get("statement", "")), "T7 incomplete")

    ue = c.get("universal_escalation", {})
    need(ue.get("obligation") == "FOC-16", "contract FOC-16 binding")
    need(ue.get("termination_policy") == "UNIVERSAL_PROOF_ONLY", "contract termination rule")
    need(ue.get("fixed_caps_cannot_authorize_success") is True, "fixed caps must not authorize success")
    need(ue.get("failure_to_close") == "FINAL_OPTIMALITY_BLOCKED", "contract fail-closed status")
    ce = c.get("continual_evolution", {})
    need(ce.get("obligation") == "FOC-17", "contract FOC-17 binding")
    need(ce.get("stale_certificate_forbidden") is True, "stale certificate")
    need("preserves" in ce.get("monotonic_ratchet", ""), "monotonic evolution")
    cd = c.get("strict_all_axis_commercial_dominance", {})
    need(cd.get("obligation") == "FOC-18" and cd.get("theorem") == "T6", "contract FOC-18/T6 binding")
    need(cd.get("mandatory_products") == ["CoCounsel Legal", "Lexis+ with Protégé", "Harvey"], "contract commercial products")
    need(cd.get("baseline_count") == 3 and cd.get("binding_axis_count") == 22 and cd.get("required_matrix_cells") == 66, "contract commercial dimensions")
    for key in ("every_product_every_axis", "capability_proper_superset_required", "content_quantity_excluded", "no_average_or_compensation", "equality_blocks", "unknown_blocks", "inaccessible_blocks"):
        need(cd.get(key) is True, "contract commercial strictness: " + key)
    need("CEILING_REVALIDATION_REQUIRED" in cd.get("product_update_rule", ""), "commercial product update revalidation")
    need(c.get("current_state", {}).get("COMMERCIAL_SUPERIORITY") == "NOT_YET_PROVED", "commercial pre-proof state")

    need(commercial.get("policy_status") == "FROZEN_BEFORE_FRESH_PHASE_2", "commercial baseline freeze")
    need(commercial.get("mandatory_baseline_ids") == COMMERCIAL_IDS, "commercial baseline identities/order")
    need(commercial.get("baseline_count") == 3, "commercial baseline count")
    baseline_rows = commercial.get("baselines", [])
    need([row.get("id") for row in baseline_rows] == COMMERCIAL_IDS, "commercial baseline records")
    need(all(row.get("internal_architecture_visibility") == "PROPRIETARY_NOT_PUBLICLY_COMPLETE" for row in baseline_rows), "commercial visibility honesty")
    need(all(row.get("official_sources") and row.get("source_access_date") == "2026-08-27" for row in baseline_rows), "commercial primary-source binding")
    need("UNKNOWN" in commercial.get("unknown_rule", "") and "blocks" in commercial.get("unknown_rule", ""), "commercial UNKNOWN rule")
    need("exactly one frozen binding axis" in commercial.get("axis_closure_rule", ""), "commercial axis closure")

    need(dominance.get("policy_status") == "FROZEN_BEFORE_FRESH_PHASE_2", "dominance freeze")
    need(dominance.get("obligation") == "FOC-18" and dominance.get("theorem") == "T6", "dominance FOC-18/T6")
    need("every b" in dominance.get("formal_rule", "") and "every a" in dominance.get("formal_rule", "") and "proper subset" in dominance.get("formal_rule", ""), "dominance formal rule")
    axes = dominance.get("binding_axes", [])
    need([row.get("id") for row in axes] == AXIS_IDS and dominance.get("axis_count") == 22, "binding axis closure")
    noncomp = dominance.get("non_compensation", {})
    need(noncomp and all(value is True for value in noncomp.values()), "non-compensation flags")
    matrix = dominance.get("required_matrix", {})
    need(matrix.get("cells") == 66 and matrix.get("all_66_cells_must_pass") is True and matrix.get("only_passing_cell_verdict") == "STRICTLY_BETTER", "66-cell strict matrix")
    need(dominance.get("capability_proper_superset", {}).get("missing_or_equal_capability_status") == "COMMERCIAL_SUPERIORITY_BLOCKED", "capability proper-superset gate")
    need(dominance.get("failure_status") == "COMMERCIAL_SUPERIORITY_BLOCKED" and dominance.get("initial_state") == "BLOCKED", "commercial fail-closed status")

    need(transformation.get("policy_status") == "FROZEN_BEFORE_FRESH_PHASE_2", "B0 transformation freeze")
    need(transformation.get("obligation") == "FOC-19" and transformation.get("theorem") == "T7", "B0 transformation FOC-19/T7")
    need(transformation.get("source_baseline", {}).get("commit") == B0_COMMIT and transformation.get("source_baseline", {}).get("tree") == B0_TREE, "B0 transformation binding")
    need("evolutionary successor" in transformation.get("target_rule", "") and "greenfield" in transformation.get("target_rule", ""), "anti-greenfield target")
    need(len(transformation.get("required_post_reveal_artifacts", [])) == 9, "repository-delta artifact set")
    need(set(transformation.get("change_kinds", [])) == {"ADD", "MODIFY", "REFACTOR", "MOVE", "REPLACE", "REMOVE"}, "repository change kinds")
    anti = transformation.get("anti_duplication_rules", {})
    need(anti and all(value is True for value in anti.values()), "repository anti-duplication")
    need(transformation.get("repository_writes_before_creator_approval") == 0, "repository write gate")
    need("Apply(B0,Delta_B0)=E_star" in transformation.get("formal_rule", ""), "B0 transformation formal rule")
    ctransform = c.get("andrianna_b0_transformation", {})
    need(ctransform.get("obligation") == "FOC-19" and ctransform.get("theorem") == "T7", "contract B0 transformation binding")
    need(ctransform.get("anti_greenfield") is True and ctransform.get("anti_parallel_authority") is True, "contract anti-greenfield/parallel-authority")
    need(c.get("current_state", {}).get("B0_TRANSFORMATION") == "NOT_YET_PLANNED", "B0 transformation pre-plan state")

    need(escalation.get("policy_status") == "FROZEN_BEFORE_FRESH_PHASE_2", "escalation freeze status")
    engine = escalation.get("escalation_engine", {})
    need(engine.get("termination_policy") == "UNIVERSAL_PROOF_ONLY", "escalation termination")
    caps = " ".join(engine.get("no_success_caps", [])).lower()
    need(all(word in caps for word in ("round", "time", "compute", "candidate", "reviewer", "benchmark")), "success-cap exclusions")
    domain = escalation.get("domain_rules", {})
    need(domain.get("winner_only_domain_forbidden") is True, "winner-only domain")
    need(domain.get("post_hoc_domain_forbidden") is True, "post-hoc domain")
    need(len(domain.get("closure_routes", [])) == 2, "closure routes")
    success = escalation.get("success_gate", {})
    need(success.get("success_status") == "FINAL_B0_SUCCESSOR_GREATEST_ELEMENT_AND_STRICT_ALL_AXIS_COMMERCIAL_SUPERIORITY_VERIFIED_UNDER_HASHED_TCB", "final success label")
    need(success.get("otherwise_status") == "FINAL_OPTIMALITY_BLOCKED", "final blocked label")
    need(len(success.get("all_required", [])) >= 9, "universal proof gate incomplete")
    continuous = escalation.get("continual_frontier_maintenance", {})
    need(continuous.get("obligation") == "FOC-17", "protocol FOC-17 binding")
    need("CEILING_REVALIDATION_REQUIRED" in continuous.get("state_transition", []), "revalidation state")
    need("cannot support a current-best claim" in continuous.get("stale_certificate_rule", ""), "stale-certificate revocation")
    need("preserves" in continuous.get("monotonic_ratchet", ""), "protocol monotonic ratchet")

    need(acceptance.get("answer_neutral") is True, "acceptance not answer-neutral")
    need("PHASE_2_COMPLETE" in acceptance.get("forbidden_producer_statuses", []), "producer completion must be forbidden")
    outcomes = acceptance.get("acceptance_outcomes", {})
    need(outcomes.get("semantic_and_artifact_gates_pass") == "PHASE_2_CANDIDATE_ACCEPTED_FOR_PROOF_PIPELINE", "Phase-2 reviewer outcome")
    need("BLINDNESS_" in str(outcomes.get("blindness_label", "")), "separate blindness label")
    need("new preserved review epoch" in acceptance.get("checker_epoch_rule", ""), "checker epoch rule")

    need(output.get("supporting_artifact_rule", "").startswith("Supporting files"), "output inventory rule")
    need(output.get("manifest_and_seal", {}).get("no_hand_asserted_counts") is True, "hand counts forbidden")
    need(set(output.get("blindness_status_enum", [])) == {"BLINDNESS_VERIFIED", "BLINDNESS_FAILED", "BLINDNESS_UNVERIFIED"}, "blindness enum")
    need(len(output.get("required_artifacts", [])) >= 23, "required output artifacts")
    required_output = set(output.get("required_artifacts", []))
    need({"PHASE-2-COMMERCIAL-BASELINE-LEDGER.jsonl", "PHASE-2-ALL-AXIS-DOMINANCE-MATRIX.json", "PHASE-2-MECHANISM-ONLY-EVALUATION-PLAN.md", "PHASE-2-IMPLEMENTATION-ABSTRACTION-MAP.json"} <= required_output, "commercial/transformation Phase-2 outputs")
    need(output.get("implementation_abstraction_rule", {}).get("artifact") == "PHASE-2-IMPLEMENTATION-ABSTRACTION-MAP.json", "implementation abstraction rule")

    incident = isolation.get("incident_rule", {})
    need(incident.get("no_repeated_phase_2_rerun_for_logging_defects") is True, "no endless isolation reruns")
    need("universal proof" in incident.get("effect_on_final_ceiling", ""), "isolation/proof separation")

    current = launch.get("current_connected_project", {})
    need(current.get("eligible_to_run_blind_phase_2") is False, "baseline-connected launch must be ineligible")
    routes = {r.get("route") for r in launch.get("eligible_launch_routes_in_order", [])}
    need({"NEW_UPLOAD_ONLY_CLOUD_WORKSPACE", "NEW_STERILE_STUDY_REPOSITORY"} <= routes, "clean launch routes")
    evidence = launch.get("evidence_model", {})
    need("not an OS monitor" in evidence.get("explicit_non_claim", ""), "logger overclaim")

    role_names = {row.get("role") for row in roles.get("roles", [])}
    need({"FRESH_PHASE_2_PRODUCER", "PHASE_2_INDEPENDENT_REVIEWER", "PHASE_5_RED_TEAM", "PHASE_6_REPLICATOR_A_OR_B"} <= role_names, "role separation")
    need(roles.get("acceptance_rule") == "No actor accepts its own produced artifact.", "anti-self-certification")

    actual_nc = [row.get("id") for row in controls.get("controls", [])]
    need(actual_nc == NC_IDS, "negative controls must be exactly NC-01..44")
    need(controls.get("control_count") == len(NC_IDS), "negative-control frozen count")
    enforcement = controls.get("enforcement_model", {})
    need(enforcement.get("prelaunch_structural_self_tests") == len(MUTATIONS), "prelaunch structural self-test count")
    need(enforcement.get("post_output_semantic_controls") == len(NC_IDS), "post-output semantic-control count")
    need("UNEXECUTED" in enforcement.get("semantic_scope", ""), "unexecutable controls must remain unexecuted")
    need("not reported as 44 executed" in enforcement.get("no_count_inflation", ""), "negative-control no-inflation rule")
    need("33/33" in controls.get("clean_baseline_expected", ""), "structural baseline result labelling")

    state = c.get("current_state", {})
    need(state.get("P1") == "ACCEPTED", "current P1")
    need(state.get("P2") == "FRESH_RERUN_PREPARED_NOT_LAUNCHED", "current P2")
    need(state.get("P3") == "UNAUTHORIZED", "current P3")
    need(state.get("derived_verdict") == "FINAL_OPTIMALITY_BLOCKED", "current verdict")
    need(c.get("permitted_final_status") == success.get("success_status"), "final status drift")

    trust = c.get("trust_root", {})
    need(trust.get("mode") == "HASH_BOUND_CREATOR_APPROVAL_RECEIPT", "creator approval mode")
    need(trust.get("receipt_is_external_to_freeze") is True, "approval must not mutate freeze")
    return issues


def load_data() -> dict:
    return {
        "contract": read_json("PROOF-OF-CEILING-CONTRACT.json"),
        "obligations": read_jsonl("PROOF-OBLIGATIONS.jsonl"),
        "escalation": read_json("UNIVERSAL-ESCALATION-PROTOCOL.json"),
        "acceptance": read_json("PHASE-2-ANSWER-NEUTRAL-ACCEPTANCE-SPEC.json"),
        "output": read_json("PHASE-2-OUTPUT-CONTRACT.json"),
        "isolation": read_json("PHASE-2-ISOLATION-POLICY.json"),
        "launch": read_json("COORDINATOR-LAUNCH-POLICY.json"),
        "roles": read_json("ROLE-SEPARATION.json"),
        "controls": read_json("NEGATIVE-CONTROLS.json"),
        "commercial": read_json("COMMERCIAL-FRONTIER-BASELINES.json"),
        "dominance": read_json("ALL-AXIS-DOMINANCE-SPEC.json"),
        "transformation": read_json("B0-TRANSFORMATION-AND-REPOSITORY-DELTA-SPEC.json"),
    }


MUTATIONS = [
    ("drop_foc16", lambda d: d["obligations"].pop(15)),
    ("drop_foc17", lambda d: d["obligations"].pop(16)),
    ("drop_foc18", lambda d: d["obligations"].pop(17)),
    ("drop_foc19", lambda d: d["obligations"].pop(18)),
    ("fixed_round_success", lambda d: d["escalation"]["escalation_engine"].update({"termination_policy": "K_ROUNDS"})),
    ("winner_domain", lambda d: d["escalation"]["domain_rules"].update({"winner_only_domain_forbidden": False})),
    ("posthoc_domain", lambda d: d["escalation"]["domain_rules"].update({"post_hoc_domain_forbidden": False})),
    ("producer_complete", lambda d: d["acceptance"]["forbidden_producer_statuses"].remove("PHASE_2_COMPLETE")),
    ("answer_tuned", lambda d: d["acceptance"].update({"answer_neutral": False})),
    ("hand_counts", lambda d: d["output"]["manifest_and_seal"].update({"no_hand_asserted_counts": False})),
    ("drop_blind_label", lambda d: d["output"].update({"blindness_status_enum": []})),
    ("rerun_loop", lambda d: d["isolation"]["incident_rule"].update({"no_repeated_phase_2_rerun_for_logging_defects": False})),
    ("baseline_eligible", lambda d: d["launch"]["current_connected_project"].update({"eligible_to_run_blind_phase_2": True})),
    ("logger_os_claim", lambda d: d["launch"]["evidence_model"].update({"explicit_non_claim": "logger is authoritative"})),
    ("self_accept", lambda d: d["roles"].update({"acceptance_rule": "producer accepts"})),
    ("drop_nc", lambda d: d["controls"]["controls"].pop()),
    ("p3_started", lambda d: d["contract"]["current_state"].update({"P3": "STARTED"})),
    ("trust_mutates", lambda d: d["contract"]["trust_root"].update({"receipt_is_external_to_freeze": False})),
    ("stale_certificate", lambda d: d["escalation"]["continual_frontier_maintenance"].update({"stale_certificate_rule": "keep current"})),
    ("regressive_successor", lambda d: d["contract"]["continual_evolution"].update({"monotonic_ratchet": "regression allowed"})),
    ("omit_commercial_baseline", lambda d: d["commercial"]["mandatory_baseline_ids"].pop()),
    ("allow_average", lambda d: d["dominance"]["non_compensation"].update({"average_forbidden": False})),
    ("allow_equal_axis", lambda d: d["dominance"]["non_compensation"].update({"equal_on_any_binding_axis_forbidden": False})),
    ("allow_unknown_commercial", lambda d: d["contract"]["strict_all_axis_commercial_dominance"].update({"unknown_blocks": False})),
    ("drop_axis", lambda d: d["dominance"]["binding_axes"].pop()),
    ("matrix_65", lambda d: d["dominance"]["required_matrix"].update({"cells": 65})),
    ("capability_not_proper", lambda d: d["contract"]["strict_all_axis_commercial_dominance"].update({"capability_proper_superset_required": False})),
    ("content_credit", lambda d: d["contract"]["strict_all_axis_commercial_dominance"].update({"content_quantity_excluded": False})),
    ("commercial_update_stale", lambda d: d["contract"]["strict_all_axis_commercial_dominance"].update({"product_update_rule": "keep certificate current"})),
    ("greenfield_allowed", lambda d: d["contract"]["andrianna_b0_transformation"].update({"anti_greenfield": False})),
    ("parallel_authority_allowed", lambda d: d["transformation"]["anti_duplication_rules"].update({"parallel_authority_forbidden": False})),
    ("repo_write_before_approval", lambda d: d["transformation"].update({"repository_writes_before_creator_approval": 1})),
    ("drop_delta_artifact", lambda d: d["transformation"]["required_post_reveal_artifacts"].pop()),
]


def self_test(data: dict) -> list[str]:
    failures = []
    for name, mutate in MUTATIONS:
        changed = copy.deepcopy(data)
        mutate(changed)
        if not semantic_issues(changed):
            failures.append(name)
    return failures


def package_issues(contract: dict) -> list[str]:
    issues = []
    seal_path = os.path.join(HERE, SEAL)
    if not os.path.isfile(seal_path):
        return ["REVIEWER-SEAL.json missing"]
    seal = read_json(SEAL)
    sealed = {row.get("file"): row for row in seal.get("sealed_files", [])}
    actual = {name for name in os.listdir(HERE) if os.path.isfile(os.path.join(HERE, name)) and name != SEAL}
    if actual != REQUIRED_FILES:
        issues.append(f"actual file set differs: missing={sorted(REQUIRED_FILES-actual)} extra={sorted(actual-REQUIRED_FILES)}")
    if set(sealed) != actual:
        issues.append("seal inventory differs from actual file set")
    for name, row in sealed.items():
        path = os.path.join(HERE, name)
        if not os.path.isfile(path):
            continue
        data = open(path, "rb").read()
        if row.get("byte_length") != len(data) or row.get("sha256") != sha256(data):
            issues.append("hash/length mismatch: " + name)
    if seal.get("contract_version") != VERSION:
        issues.append("seal contract version")
    if seal.get("current_state") != contract.get("current_state"):
        issues.append("seal/contract state drift")
    for cited in contract.get("cited_documents", []):
        path = os.path.join(HERE, cited.get("file", ""))
        if not os.path.isfile(path):
            issues.append("cited document missing")
            continue
        data = open(path, "rb").read()
        if cited.get("byte_length") != len(data) or cited.get("sha256") != sha256(data):
            issues.append("cited document binding mismatch")
    return issues


def main() -> int:
    try:
        data = load_data()
    except Exception as exc:
        print("FREEZE_STRUCTURE_INVALID")
        print("  - parse error:", exc)
        return 1
    failures = self_test(data)
    if failures:
        print("VALIDATOR_A_SELF_TEST_FAILED:", ", ".join(failures))
        return 2
    print(f"VALIDATOR_A_SELF_TEST_PASS: {len(MUTATIONS)}/{len(MUTATIONS)}")
    issues = semantic_issues(data) + package_issues(data["contract"])
    if issues:
        print("FREEZE_STRUCTURE_INVALID")
        for issue in issues:
            print("  -", issue)
        return 1
    print("FREEZE_STRUCTURE_VALID")
    print("NATURE: structural freeze validator; NOT an optimality proof")
    print("CURRENT_STUDY_STATE: FINAL_OPTIMALITY_BLOCKED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
