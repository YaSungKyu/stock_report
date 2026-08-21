"""Exit 0 if the given date traded, 1 if it did not. Single source of truth: KIS minute bars
for a liquid index ETF. A calendar would need its own holiday table and would drift."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                                ".claude", "skills", "gapbet"))
import kis_scan as K

date = sys.argv[1].replace("-", "") if len(sys.argv) > 1 else None
cfg = K._load_cfg()
tok = K._get_token(cfg) if cfg else None
if not tok:
    print("UNKNOWN: no KIS credentials -- treating as open")
    sys.exit(0)                       # never skip a run because auth broke
try:
    bars = K.intraday_bars(cfg, tok, "069500", start="0900", end="0930", mkt="J", date=date)
except Exception as e:
    print(f"UNKNOWN: {e} -- treating as open")
    sys.exit(0)
print(f"{'OPEN' if bars else 'CLOSED'}: {len(bars or [])} bars")
sys.exit(0 if bars else 1)
