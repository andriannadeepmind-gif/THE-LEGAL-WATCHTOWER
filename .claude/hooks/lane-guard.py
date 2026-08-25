#!/usr/bin/env python3
"""DEPRECATED SHIM -> pretool_guard (REV3 single decision seat).
Kept only so a stale in-memory hook config that still points at this filename
routes to current REV3 logic. REV3 settings.json references pretool_guard.py.
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import pretool_guard
pretool_guard.main()
