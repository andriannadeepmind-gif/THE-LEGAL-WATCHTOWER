#!/usr/bin/env node
// Structural validator B for the immutable pre-Phase-2 freeze.
// Independent implementation. It does not prove mathematical optimality.
// Exit 0 valid; exit 1 invalid; exit 2 self-test failure.

import { createHash } from "node:crypto";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const SEAL = "REVIEWER-SEAL.json";
const VERSION = "2.3.0-R3-PRE-PHASE-2-FROZEN-CANDIDATE";
const B0 = "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03";
const P1 = "3E927EBA2E90410C47FC955C0B6F704F054630DE141F275CF89A4AB31EAB3E93";
const FOC = Array.from({length: 19}, (_, i) => `FOC-${String(i + 1).padStart(2, "0")}`);
const THM = ["T1", "T2", "T3", "T4", "T5", "T6", "T7"];
const NC = Array.from({length: 44}, (_, i) => `NC-${String(i + 1).padStart(2, "0")}`);
const COMM = [
  "B-COMM-01-THOMSON-REUTERS-COCOUNSEL-LEGAL",
  "B-COMM-02-LEXISNEXIS-LEXIS-PLUS-WITH-PROTEGE",
  "B-COMM-03-HARVEY"
];
const AXES = Array.from({length: 22}, (_, i) => `AX-${String(i + 1).padStart(2, "0")}`);
const REQUIRED = new Set([
  "B7-PRODUCER-SESSION-EVIDENCE-RECOVERY.md", "B0-TRANSFORMATION-AND-REPOSITORY-DELTA-SPEC.json",
  "ALL-AXIS-DOMINANCE-SPEC.json", "COMMERCIAL-FRONTIER-BASELINES.json", "COORDINATOR-LAUNCH-POLICY.json",
  "NEGATIVE-CONTROLS.json", "PHASE-2-ANSWER-NEUTRAL-ACCEPTANCE-SPEC.json",
  "PHASE-2-ISOLATION-POLICY.json", "PHASE-2-OUTPUT-CONTRACT.json",
  "PROOF-OBLIGATIONS.jsonl", "PROOF-OF-CEILING-CONTRACT.json",
  "PROOF-OF-CEILING-CONTRACT.md", "REVIEW-RUNBOOK.md", "ROLE-SEPARATION.json",
  "UNIVERSAL-ESCALATION-PROTOCOL.json", "verify_freeze.mjs", "verify_freeze.py"
]);
const sha = (b) => createHash("sha256").update(b).digest("hex");
const json = (name) => JSON.parse(readFileSync(join(HERE, name), "utf8"));
const jsonl = (name) => readFileSync(join(HERE, name), "utf8").split("\n").filter(x => x.trim()).map(JSON.parse);
const clone = (x) => JSON.parse(JSON.stringify(x));

function load() {
  return {
    c: json("PROOF-OF-CEILING-CONTRACT.json"), o: jsonl("PROOF-OBLIGATIONS.jsonl"),
    e: json("UNIVERSAL-ESCALATION-PROTOCOL.json"),
    a: json("PHASE-2-ANSWER-NEUTRAL-ACCEPTANCE-SPEC.json"),
    out: json("PHASE-2-OUTPUT-CONTRACT.json"), iso: json("PHASE-2-ISOLATION-POLICY.json"),
    launch: json("COORDINATOR-LAUNCH-POLICY.json"), roles: json("ROLE-SEPARATION.json"),
    nc: json("NEGATIVE-CONTROLS.json"),
    commercial: json("COMMERCIAL-FRONTIER-BASELINES.json"),
    dom: json("ALL-AXIS-DOMINANCE-SPEC.json"),
    transform: json("B0-TRANSFORMATION-AND-REPOSITORY-DELTA-SPEC.json")
  };
}

function issues(d) {
  const bad = [];
  const need = (x, m) => { if (!x) bad.push(m); };
  need(d.c.schema === "watchtower/proof-of-ceiling-contract/2", "contract schema");
  need(d.c.contract_version === VERSION && d.c.authoritative === false, "contract version/authority");
  need(d.c.baseline_B0?.commit === B0 && d.c.phase_1_binding?.sha256 === P1, "baseline bindings");
  const ids = d.o.map(x => x.id);
  need(JSON.stringify(ids) === JSON.stringify([...FOC, ...THM]), "obligation ids");
  need(d.o.every(x => x.state === "BLOCKED"), "pre-discharged obligation");
  const idset = new Set(ids);
  for (const row of d.o) for (const dep of row.depends_on || []) need(idset.has(dep), `dangling ${dep}`);
  const f16 = d.o.find(x => x.id === "FOC-16") || {};
  const ftext = String(f16.statement || "").toLowerCase();
  need(["round", "time", "candidate", "greatest-element"].every(x => ftext.includes(x)), "FOC-16 incomplete");
  const f17 = d.o.find(x => x.id === "FOC-17") || {};
  const f17text = String(f17.statement || "").toLowerCase();
  need(["continual", "monotonically", "revalidation", "independent"].every(x => f17text.includes(x)), "FOC-17 incomplete");
  const f18text = String((d.o.find(x => x.id === "FOC-18") || {}).statement || "").toLowerCase();
  need(["strictly better", "every", "cocounsel", "protégé", "harvey", "unknown"].every(x => f18text.includes(x)), "FOC-18 incomplete");
  const f19text = String((d.o.find(x => x.id === "FOC-19") || {}).statement || "").toLowerCase();
  need(["andrianna", "repository", "refactor", "creator approval", "greenfield"].every(x => f19text.includes(x)), "FOC-19 incomplete");
  const t6 = d.o.find(x => x.id === "T6") || {};
  need(String(t6.statement || "").includes("StrictBetter") && String(t6.statement || "").includes("proper subset"), "T6 incomplete");
  const t7 = d.o.find(x => x.id === "T7") || {};
  need(String(t7.statement || "").includes("Apply(B0,Delta_B0)=E_star") && String(t7.statement || "").includes("parallel authority"), "T7 incomplete");

  need(d.c.universal_escalation?.termination_policy === "UNIVERSAL_PROOF_ONLY", "contract termination");
  need(d.c.universal_escalation?.fixed_caps_cannot_authorize_success === true, "fixed caps");
  need(d.c.continual_evolution?.obligation === "FOC-17" && d.c.continual_evolution?.stale_certificate_forbidden === true, "contract continual evolution");
  need(String(d.c.continual_evolution?.monotonic_ratchet || "").includes("preserves"), "contract monotonic ratchet");
  const cd = d.c.strict_all_axis_commercial_dominance || {};
  need(cd.obligation === "FOC-18" && cd.theorem === "T6", "contract FOC-18/T6");
  need(JSON.stringify(cd.mandatory_products) === JSON.stringify(["CoCounsel Legal", "Lexis+ with Protégé", "Harvey"]), "contract products");
  need(cd.baseline_count === 3 && cd.binding_axis_count === 22 && cd.required_matrix_cells === 66, "contract commercial dimensions");
  for (const key of ["every_product_every_axis", "capability_proper_superset_required", "content_quantity_excluded", "no_average_or_compensation", "equality_blocks", "unknown_blocks", "inaccessible_blocks"])
    need(cd[key] === true, "contract commercial strictness " + key);
  need(String(cd.product_update_rule || "").includes("CEILING_REVALIDATION_REQUIRED"), "commercial update revalidation");
  need(d.c.current_state?.COMMERCIAL_SUPERIORITY === "NOT_YET_PROVED", "commercial pre-proof state");

  need(d.commercial.policy_status === "FROZEN_BEFORE_FRESH_PHASE_2", "commercial freeze");
  need(JSON.stringify(d.commercial.mandatory_baseline_ids) === JSON.stringify(COMM) && d.commercial.baseline_count === 3, "commercial identities/count");
  need(JSON.stringify((d.commercial.baselines || []).map(x => x.id)) === JSON.stringify(COMM), "commercial records");
  need((d.commercial.baselines || []).every(x => x.internal_architecture_visibility === "PROPRIETARY_NOT_PUBLICLY_COMPLETE" && x.source_access_date === "2026-08-27" && (x.official_sources || []).length > 0), "commercial evidence honesty");
  need(String(d.commercial.unknown_rule || "").includes("UNKNOWN") && String(d.commercial.unknown_rule || "").includes("blocks"), "commercial unknown rule");
  need(String(d.commercial.axis_closure_rule || "").includes("exactly one frozen binding axis"), "commercial axis closure");

  need(d.dom.obligation === "FOC-18" && d.dom.theorem === "T6", "dominance binding");
  need(String(d.dom.formal_rule || "").includes("every b") && String(d.dom.formal_rule || "").includes("every a") && String(d.dom.formal_rule || "").includes("proper subset"), "dominance formal rule");
  need(JSON.stringify((d.dom.binding_axes || []).map(x => x.id)) === JSON.stringify(AXES) && d.dom.axis_count === 22, "axis closure");
  need(Object.values(d.dom.non_compensation || {}).length > 0 && Object.values(d.dom.non_compensation || {}).every(x => x === true), "non-compensation");
  need(d.dom.required_matrix?.cells === 66 && d.dom.required_matrix?.all_66_cells_must_pass === true && d.dom.required_matrix?.only_passing_cell_verdict === "STRICTLY_BETTER", "66-cell matrix");
  need(d.dom.capability_proper_superset?.missing_or_equal_capability_status === "COMMERCIAL_SUPERIORITY_BLOCKED", "capability superset");
  need(d.dom.failure_status === "COMMERCIAL_SUPERIORITY_BLOCKED" && d.dom.initial_state === "BLOCKED", "commercial fail-closed");

  need(d.transform.policy_status === "FROZEN_BEFORE_FRESH_PHASE_2" && d.transform.obligation === "FOC-19" && d.transform.theorem === "T7", "transformation freeze/binding");
  need(d.transform.source_baseline?.commit === B0 && d.transform.source_baseline?.tree === "23b7a6f4450f50d151d38e13020bee9872e73bcd", "transformation B0 binding");
  need(String(d.transform.target_rule || "").includes("evolutionary successor") && String(d.transform.target_rule || "").includes("greenfield"), "anti-greenfield target");
  need((d.transform.required_post_reveal_artifacts || []).length === 9, "delta artifacts");
  need(new Set(d.transform.change_kinds || []).size === 6 && ["ADD", "MODIFY", "REFACTOR", "MOVE", "REPLACE", "REMOVE"].every(x => (d.transform.change_kinds || []).includes(x)), "change kinds");
  need(Object.values(d.transform.anti_duplication_rules || {}).length > 0 && Object.values(d.transform.anti_duplication_rules || {}).every(x => x === true), "anti-duplication");
  need(d.transform.repository_writes_before_creator_approval === 0, "repository write gate");
  need(String(d.transform.formal_rule || "").includes("Apply(B0,Delta_B0)=E_star"), "transformation formal rule");
  const ct = d.c.andrianna_b0_transformation || {};
  need(ct.obligation === "FOC-19" && ct.theorem === "T7" && ct.anti_greenfield === true && ct.anti_parallel_authority === true, "contract transformation gate");
  need(d.c.current_state?.B0_TRANSFORMATION === "NOT_YET_PLANNED", "transformation pre-plan state");
  need(d.e.escalation_engine?.termination_policy === "UNIVERSAL_PROOF_ONLY", "protocol termination");
  const caps = (d.e.escalation_engine?.no_success_caps || []).join(" ").toLowerCase();
  need(["round", "time", "compute", "candidate", "reviewer", "benchmark"].every(x => caps.includes(x)), "cap list");
  need(d.e.domain_rules?.winner_only_domain_forbidden === true && d.e.domain_rules?.post_hoc_domain_forbidden === true, "domain independence");
  need((d.e.domain_rules?.closure_routes || []).length === 2, "closure routes");
  need(d.e.success_gate?.otherwise_status === "FINAL_OPTIMALITY_BLOCKED", "blocked status");
  need(d.e.success_gate?.success_status === "FINAL_B0_SUCCESSOR_GREATEST_ELEMENT_AND_STRICT_ALL_AXIS_COMMERCIAL_SUPERIORITY_VERIFIED_UNDER_HASHED_TCB", "success status");
  need((d.e.success_gate?.all_required || []).length >= 9, "proof gate");
  need(d.e.continual_frontier_maintenance?.obligation === "FOC-17", "protocol FOC-17");
  need((d.e.continual_frontier_maintenance?.state_transition || []).includes("CEILING_REVALIDATION_REQUIRED"), "revalidation state");
  need(String(d.e.continual_frontier_maintenance?.stale_certificate_rule || "").includes("cannot support a current-best claim"), "stale certificate");
  need(String(d.e.continual_frontier_maintenance?.monotonic_ratchet || "").includes("preserves"), "protocol ratchet");

  need(d.a.answer_neutral === true, "answer neutrality");
  need((d.a.forbidden_producer_statuses || []).includes("PHASE_2_COMPLETE"), "producer self-completion");
  need(d.a.acceptance_outcomes?.semantic_and_artifact_gates_pass === "PHASE_2_CANDIDATE_ACCEPTED_FOR_PROOF_PIPELINE", "P2 outcome");
  need(String(d.a.acceptance_outcomes?.blindness_label || "").includes("BLINDNESS_"), "blindness separation");
  need(String(d.a.checker_epoch_rule || "").includes("new preserved review epoch"), "checker epoch");
  need(d.out.manifest_and_seal?.no_hand_asserted_counts === true, "hand counts");
  need(new Set(d.out.blindness_status_enum || []).size === 3, "blindness enum");
  need((d.out.required_artifacts || []).length >= 23, "output artifacts");
  const rout = new Set(d.out.required_artifacts || []);
  need(["PHASE-2-COMMERCIAL-BASELINE-LEDGER.jsonl", "PHASE-2-ALL-AXIS-DOMINANCE-MATRIX.json", "PHASE-2-MECHANISM-ONLY-EVALUATION-PLAN.md", "PHASE-2-IMPLEMENTATION-ABSTRACTION-MAP.json"].every(x => rout.has(x)), "commercial/transformation outputs");
  need(d.out.implementation_abstraction_rule?.artifact === "PHASE-2-IMPLEMENTATION-ABSTRACTION-MAP.json", "implementation abstraction");
  need(d.iso.incident_rule?.no_repeated_phase_2_rerun_for_logging_defects === true, "isolation rerun loop");
  need(String(d.iso.incident_rule?.effect_on_final_ceiling || "").includes("universal proof"), "proof separation");
  need(d.launch.current_connected_project?.eligible_to_run_blind_phase_2 === false, "connected project eligibility");
  const routes = new Set((d.launch.eligible_launch_routes_in_order || []).map(x => x.route));
  need(routes.has("NEW_UPLOAD_ONLY_CLOUD_WORKSPACE") && routes.has("NEW_STERILE_STUDY_REPOSITORY"), "launch routes");
  need(String(d.launch.evidence_model?.explicit_non_claim || "").includes("not an OS monitor"), "logger overclaim");
  const roles = new Set((d.roles.roles || []).map(x => x.role));
  need(["FRESH_PHASE_2_PRODUCER", "PHASE_2_INDEPENDENT_REVIEWER", "PHASE_5_RED_TEAM", "PHASE_6_REPLICATOR_A_OR_B"].every(x => roles.has(x)), "roles");
  need(d.roles.acceptance_rule === "No actor accepts its own produced artifact.", "self certification");
  need(JSON.stringify((d.nc.controls || []).map(x => x.id)) === JSON.stringify(NC), "negative controls");
  need(d.nc.control_count === NC.length, "negative-control frozen count");
  need(d.nc.enforcement_model?.prelaunch_structural_self_tests === MUT.length, "prelaunch structural self-test count");
  need(d.nc.enforcement_model?.post_output_semantic_controls === NC.length, "post-output semantic-control count");
  need(String(d.nc.enforcement_model?.semantic_scope || "").includes("UNEXECUTED"), "unexecutable controls remain unexecuted");
  need(String(d.nc.enforcement_model?.no_count_inflation || "").includes("not reported as 44 executed"), "negative-control no-inflation rule");
  need(String(d.nc.clean_baseline_expected || "").includes("33/33"), "structural baseline result labelling");
  need(d.c.current_state?.P2 === "FRESH_RERUN_PREPARED_NOT_LAUNCHED" && d.c.current_state?.P3 === "UNAUTHORIZED", "current phase state");
  need(d.c.current_state?.derived_verdict === "FINAL_OPTIMALITY_BLOCKED", "current verdict");
  need(d.c.permitted_final_status === d.e.success_gate?.success_status, "final status drift");
  need(d.c.trust_root?.mode === "HASH_BOUND_CREATOR_APPROVAL_RECEIPT" && d.c.trust_root?.receipt_is_external_to_freeze === true, "approval mode");
  return bad;
}

const MUT = [
  ["drop16", d => d.o.splice(15, 1)],
  ["drop17", d => d.o.splice(16, 1)],
  ["drop18", d => d.o.splice(17, 1)],
  ["drop19", d => d.o.splice(18, 1)],
  ["krounds", d => d.e.escalation_engine.termination_policy = "K_ROUNDS"],
  ["winner", d => d.e.domain_rules.winner_only_domain_forbidden = false],
  ["posthoc", d => d.e.domain_rules.post_hoc_domain_forbidden = false],
  ["producerComplete", d => d.a.forbidden_producer_statuses = []],
  ["tuned", d => d.a.answer_neutral = false],
  ["counts", d => d.out.manifest_and_seal.no_hand_asserted_counts = false],
  ["blind", d => d.out.blindness_status_enum = []],
  ["rerun", d => d.iso.incident_rule.no_repeated_phase_2_rerun_for_logging_defects = false],
  ["eligible", d => d.launch.current_connected_project.eligible_to_run_blind_phase_2 = true],
  ["osclaim", d => d.launch.evidence_model.explicit_non_claim = "logger authoritative"],
  ["self", d => d.roles.acceptance_rule = "producer accepts"],
  ["nc", d => d.nc.controls.pop()],
  ["p3", d => d.c.current_state.P3 = "STARTED"],
  ["receipt", d => d.c.trust_root.receipt_is_external_to_freeze = false],
  ["stale", d => d.e.continual_frontier_maintenance.stale_certificate_rule = "keep current"],
  ["regress", d => d.c.continual_evolution.monotonic_ratchet = "regression allowed"],
  ["omitCommercial", d => d.commercial.mandatory_baseline_ids.pop()],
  ["allowAverage", d => d.dom.non_compensation.average_forbidden = false],
  ["allowEquality", d => d.dom.non_compensation.equal_on_any_binding_axis_forbidden = false],
  ["allowUnknown", d => d.c.strict_all_axis_commercial_dominance.unknown_blocks = false],
  ["dropAxis", d => d.dom.binding_axes.pop()],
  ["cells65", d => d.dom.required_matrix.cells = 65],
  ["notProper", d => d.c.strict_all_axis_commercial_dominance.capability_proper_superset_required = false],
  ["contentCredit", d => d.c.strict_all_axis_commercial_dominance.content_quantity_excluded = false],
  ["commercialStale", d => d.c.strict_all_axis_commercial_dominance.product_update_rule = "keep current"],
  ["greenfield", d => d.c.andrianna_b0_transformation.anti_greenfield = false],
  ["parallelAuthority", d => d.transform.anti_duplication_rules.parallel_authority_forbidden = false],
  ["earlyWrite", d => d.transform.repository_writes_before_creator_approval = 1],
  ["dropDeltaArtifact", d => d.transform.required_post_reveal_artifacts.pop()]
];

function selftest(base) {
  const missed = [];
  for (const [name, mutate] of MUT) {
    const d = clone(base); mutate(d);
    if (issues(d).length === 0) missed.push(name);
  }
  return missed;
}

function packageIssues(contract) {
  const bad = [];
  const path = join(HERE, SEAL);
  if (!existsSync(path)) return ["REVIEWER-SEAL.json missing"];
  const seal = json(SEAL);
  const actual = new Set(readdirSync(HERE).filter(f => f !== SEAL && statSync(join(HERE, f)).isFile()));
  const sealed = new Map((seal.sealed_files || []).map(x => [x.file, x]));
  const same = (a, b) => a.size === b.size && [...a].every(x => b.has(x));
  if (!same(actual, REQUIRED)) bad.push("actual file set differs");
  if (!same(actual, new Set(sealed.keys()))) bad.push("seal inventory differs");
  for (const [name, row] of sealed) {
    const p = join(HERE, name); if (!existsSync(p)) continue;
    const bytes = readFileSync(p);
    if (row.byte_length !== bytes.length || row.sha256 !== sha(bytes)) bad.push("hash/length " + name);
  }
  if (seal.contract_version !== VERSION) bad.push("seal version");
  if (JSON.stringify(seal.current_state) !== JSON.stringify(contract.current_state)) bad.push("state drift");
  for (const cited of contract.cited_documents || []) {
    const p = join(HERE, cited.file);
    if (!existsSync(p)) { bad.push("cited missing"); continue; }
    const bytes = readFileSync(p);
    if (cited.byte_length !== bytes.length || cited.sha256 !== sha(bytes)) bad.push("cited binding");
  }
  return bad;
}

let data;
try { data = load(); }
catch (e) { console.log("FREEZE_STRUCTURE_INVALID\n  - parse error: " + e.message); process.exit(1); }
const missed = selftest(data);
if (missed.length) { console.log("VALIDATOR_B_SELF_TEST_FAILED: " + missed.join(", ")); process.exit(2); }
console.log(`VALIDATOR_B_SELF_TEST_PASS: ${MUT.length}/${MUT.length}`);
const bad = [...issues(data), ...packageIssues(data.c)];
if (bad.length) {
  console.log("FREEZE_STRUCTURE_INVALID");
  for (const item of bad) console.log("  - " + item);
  process.exit(1);
}
console.log("FREEZE_STRUCTURE_VALID");
console.log("NATURE: structural freeze validator; NOT an optimality proof");
console.log("CURRENT_STUDY_STATE: FINAL_OPTIMALITY_BLOCKED");
