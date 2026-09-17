"""Project-owned vectors captured from unmodified Gforth, never local output."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
record=json.loads((root/'evidence/input-comparison.json').read_text(encoding='utf8'))
lines=['// Generated from reference fields only by tools/generate-input-golden.py.','///|','test "Gforth input oracle 128 portable programs" {']
quote=lambda s:json.dumps(s,ensure_ascii=False)
for row in record['rows']:
    ref=row['reference']
    lines.extend(['  {', '    let m = @forth.Machine::new()', '    // '+row['name']])
    if ref['code']==0:
        lines.append('    m.eval('+quote(row['source'])+', budget=1000000)')
        lines.append('    assert_eq(m.values(), '+json.dumps(ref['stack'])+')')
        data=''.join('\\x'+ref['outputHex'][i:i+2] for i in range(0,len(ref['outputHex']),2))
        lines.append('    assert_eq(m.output_bytes(), b"'+data+'")')
    else:
        lines.append('    let code = try { m.eval('+quote(row['source'])+', budget=1000000); 0 } catch { error => error.code() }')
        lines.append('    assert_eq(code, '+str(ref['code'])+')')
    lines.append('  }')
lines.append('}')
(root/'input_golden_test.mbt').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(len(record['rows']),'reference vectors generated')
