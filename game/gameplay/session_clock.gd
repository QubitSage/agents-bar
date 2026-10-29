extends RefCounted
## Handles elapsed wall-time gaps without granting offline progress.
const GAP_SECONDS:=5.0
static func interrupted(delta: float) -> bool:
	return not is_finite(delta) or delta>GAP_SECONDS or delta<0
