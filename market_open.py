"""Exit 0 if the given date traded, 1 if it did not. Single source of truth: KIS minute bars
for a liquid index ETF. A calendar would need its own holiday table and would drift.

Only a successful answer with no bars on that date means CLOSED. On a holiday KIS still
answers -- with the previous session's bars -- so a missing answer is a failed request, not a
holiday: kis_scan._get swallows connect timeouts and returns None, which intraday_bars used to
flatten into [] and read as CLOSED (2026-10-01 09:30 skipped the whole review that way).
A failed probe is retried; if it never answers the run proceeds, because a wrongly skipped run
is silent while a wrongly started one fails loudly in the next step."""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                                ".claude", "skills", "gapbet"))
import kis_scan as K

PROBES = 3
RETRY_SEC = 60


def probe(cfg, tok, date):
    """Bars on `date` between 09:00 and 09:30, or None when KIS gave no answer."""
    rows = K._get(cfg, tok, "/uapi/domestic-stock/v1/quotations/inquire-time-dailychartprice",
                  {"FID_ETC_CLS_CODE": "", "FID_COND_MRKT_DIV_CODE": "J",
                   "FID_INPUT_ISCD": "069500", "FID_INPUT_HOUR_1": "093000",
                   "FID_INPUT_DATE_1": date, "FID_PW_DATA_INCU_YN": "Y",
                   "FID_FAKE_TICK_INCU_YN": "N"}, "FHKST03010230", out_key="output2")
    if rows is None:
        return None
    seen = {}
    K._collect_bars(rows, "0900", "0930", date, seen)
    return len(seen)


date = (sys.argv[1] if len(sys.argv) > 1 else time.strftime("%Y-%m-%d")).replace("-", "")
cfg = K._load_cfg()
tok = K._get_token(cfg) if cfg else None
if not tok:
    print("UNKNOWN: no KIS credentials -- treating as open")
    sys.exit(0)                       # never skip a run because auth broke
for i in range(PROBES):
    try:
        n = probe(cfg, tok, date)
    except Exception as e:
        print(f"probe {i + 1}: {e}")
        n = None
    if n is not None:
        print(f"{'OPEN' if n else 'CLOSED'}: {n} bars")
        sys.exit(0 if n else 1)
    if i + 1 < PROBES:
        print(f"probe {i + 1}: no answer from KIS -- retrying in {RETRY_SEC}s")
        time.sleep(RETRY_SEC)
print(f"UNKNOWN: no answer after {PROBES} probes -- treating as open")
sys.exit(0)
