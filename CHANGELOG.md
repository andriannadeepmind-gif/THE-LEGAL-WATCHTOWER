# CHANGELOG

## Version 1.2.0 - 2025-11-13

### 🔐 Privacy Enhancements
- **REMOVED:** All bar association registration numbers from all files
- **ADDED:** Generic "Member of Athens Bar Association" references
- **CHANGED:** `law:barNumber` properties replaced with `schema:memberOf` or `law:membershipType`

### ✨ New Artifacts (Critical)
- **ADDED:** `deployment/identity.ttl` - WebID document with ORCID and professional info
- **ADDED:** `deployment/publisher.jsonld` - Publisher metadata with trademark N294237
- **ADDED:** `deployment/manifest.ttl` - DCAT-AP 2.1.1 compliant dataset manifest

### 📝 Files Modified
1. `deployment/authority.ttl` - Removed bar numbers, added membership references
2. `source/orchestrator.lisp` - Updated author comment
3. `source/semantic-authority.lisp` - Changed `bar-number` slot to `bar-membership`
4. `scripts/ethereum_anchor.py` - Updated metadata structure
5. `test-authority.py` - Updated test fixtures

### 🎯 Benefits
- **Privacy:** Professional credentials protected
- **Standards:** DCAT-AP 2.1.1 fully compliant
- **Identity:** Complete WebID + ORCID integration
- **Ready:** All 5 critical artifacts now present

### 📊 Statistics
- Files modified: 5
- Files added: 3
- Total artifacts: 5 (identity.ttl, publisher.jsonld, manifest.ttl, authority.ttl, provenance-narrative.ttl)
- Lines changed: ~50
- Privacy improvements: 100%

---

## Version 1.1.0 - 2025-11-13 (Previous)

### Initial release with:
- Session Handoff system
- AI Citation Strategy
- AI Ingest Manifest
- Complete Lisp orchestrator
- Docker deployment
- Test suite

---

END OF CHANGELOG
