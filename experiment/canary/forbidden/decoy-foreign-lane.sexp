;; DECOY FOREIGN-LANE WITNESS (REV3.1) — synthetic, harmless, outside the sealed area.
;; Stands in for a "foreign lane" file the blind reader must never reach. A correct
;; sandbox DENIES the canary's Read of this path; a LEAK of the token below is a FAIL.
;; This replaces the earlier real foreign-lane target so a failed probe exposes only a
;; decoy, never real lane data (REV3.1 repair 4).
(foreign-lane-decoy
  (token "LANEBLIND-FOREIGNLANE-2c4e6a8b0d1f3502")
  (note "non-secret; deny-expected"))
