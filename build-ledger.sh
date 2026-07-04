#!/usr/bin/env bash
set -euo pipefail
ACCOUNT="assets:checking"   # adjust to your account(s)
FRAGMENT=$(hledger aregister "$ACCOUNT" -O html)

# Indian fiscal year: Apr–Mar, e.g. 2026-27
MONTH=$(date +%-m)
YEAR=$(date +%Y)
if [ "$MONTH" -ge 4 ]; then
  FY="${YEAR}-$(printf '%02d' $(( (YEAR + 1) % 100 )))"
else
  FY="$(( YEAR - 1 ))-$(printf '%02d' $(( YEAR % 100 )))"
fi

mkdir -p docs
cat > docs/ledger.html <<EOF
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Ledger</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #f5f4f2;
    --card: #ffffff;
    --text: #222222;
    --muted: #aaaaaa;
    --border: #e8e8e8;
    --accent: #5c8c7a;
    --danger: #e53e3e;
  }
  html.dark {
    --bg: #111111;
    --card: #1e1e1e;
    --text: #e8e8e8;
    --muted: #777777;
    --border: #2e2e2e;
    --accent: #7ab5a0;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 1.5rem;
    background: var(--bg);
    color: var(--text);
    font-family: 'Inter', system-ui, sans-serif;
    font-size: 15px;
  }
  h1 {
    font-size: 1.1rem;
    font-weight: 600;
    margin: 0 0 1rem;
    color: var(--text);
  }
  .card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 0.75rem;
    box-shadow: 0 1px 2px rgba(0,0,0,0.05);
    overflow: hidden;
  }
  .table-wrap {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }
  table {
    width: 100%;
    border-collapse: collapse;
  }
  th, td {
    padding: 0.6rem 0.9rem;
    text-align: left;
    font-size: 0.85rem;
    border-bottom: 1px solid var(--border);
    white-space: normal;
    word-break: break-word;
  }
  th {
    color: var(--muted);
    font-weight: 500;
    text-transform: uppercase;
    font-size: 0.7rem;
    letter-spacing: 0.03em;
    background: var(--bg);
    white-space: nowrap;
  }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: color-mix(in srgb, var(--accent) 6%, transparent); }

  td.date {
    white-space: nowrap;
    color: var(--text);
  }

  td.num {
    text-align: right;
    white-space: nowrap;
    font-variant-numeric: tabular-nums;
    font-weight: 500;
  }
  td.num.neg { color: var(--danger); }
  td.num.pos { color: var(--accent); }

  @media (max-width: 640px) {
    body { padding: 0.75rem; font-size: 13px; }
    h1 { font-size: 1rem; }

    .card { background: transparent; border: none; box-shadow: none; }
    .table-wrap { overflow-x: visible; }
    table, thead, tbody, tr, td, th { display: block; width: 100%; }
    thead { display: none; }

    /* one card per transaction, with real spacing between them */
    tbody tr {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 0.9rem;
      box-shadow: 0 1px 3px rgba(0,0,0,0.06);
      margin-bottom: 0.9rem;
      padding: 0.85rem 1rem;
    }
    tbody tr:last-child { margin-bottom: 0; }
    tbody tr:hover td { background: transparent; }

    td {
      display: block;
      padding: 0;
      border: none;
      white-space: normal;
      text-align: left;
    }
    td::before { content: none; }

    /* column 1: date — small muted label above the description */
    td:nth-child(1) {
      color: var(--muted);
      font-size: 0.7rem;
      font-weight: 500;
      margin-bottom: 0.2rem;
    }

    /* column 2: description — the card's title */
    td:nth-child(2) {
      color: var(--text);
      font-size: 0.95rem;
      font-weight: 600;
      line-height: 1.3;
      margin-bottom: 0.35rem;
    }

    /* column 3: other accounts — muted subtitle */
    td:nth-child(3) {
      color: var(--muted);
      font-size: 0.75rem;
      line-height: 1.4;
      margin-bottom: 0.65rem;
    }

    /* columns 4 & 5: change + balance — footer row, side by side */
    td:nth-child(4), td:nth-child(5) {
      display: inline-flex;
      width: 48%;
      align-items: baseline;
      gap: 0.3rem;
      padding-top: 0.55rem;
      border-top: 1px dashed var(--border);
      font-size: 0.85rem;
    }
    td:nth-child(4)::before, td:nth-child(5)::before {
      content: attr(data-label);
      color: var(--muted);
      font-size: 0.65rem;
      text-transform: uppercase;
      letter-spacing: 0.03em;
      font-weight: 500;
    }
    td:nth-child(5) { justify-content: flex-end; }
  }
</style>
</head>
<body>
<h1>CBA Ledger - F.Y $FY</h1>
<div class="card">
  <div class="table-wrap">
$FRAGMENT
  </div>
</div>
<script>
  // theme: read ?theme=dark|light from URL (set by parent app), else fall back to system preference
  const params = new URLSearchParams(location.search);
  const theme = params.get('theme');
  if (theme === 'dark' || (!theme && matchMedia('(prefers-color-scheme: dark)').matches)) {
    document.documentElement.classList.add('dark');
  }

  const table = document.querySelector('table');
  if (table) {
    // show newest entries first (header row stays put)
    const rows = Array.from(table.rows);
    rows.slice(1).reverse().forEach(r => table.appendChild(r));

    // detect dates and amounts, format/color them
    const dateRe = /^\d{4}[-\/.]\d{2}[-\/.]\d{2}$/;
    const numRe = /^-?[\d,]+\.\d{2}(\s?[A-Za-z\$€£]{1,4})?$/;

    // column headers, used as data-label for the mobile stacked-card layout
    const headers = Array.from(table.rows[0].cells).map(th => th.textContent.trim());

    table.querySelectorAll('tr').forEach((row, i) => {
      if (i === 0) return; // skip header
      Array.from(row.cells).forEach((td, idx) => {
        td.setAttribute('data-label', headers[idx] || '');
        const text = td.textContent.trim();
        if (dateRe.test(text)) {
          const d = new Date(text + 'T00:00:00Z');
          td.textContent = d.toLocaleDateString('en-GB', {
            day: '2-digit', month: 'short', year: 'numeric', timeZone: 'UTC'
          });
          td.classList.add('date');
        } else if (numRe.test(text)) {
          td.classList.add('num');
          td.classList.add(text.startsWith('-') ? 'neg' : 'pos');
        }
      });
    });
  }

  // report our real content height to the parent page so it can size the
  // iframe to fit — avoids a second, nested scrollbar inside the iframe
  function postHeight() {
    window.parent.postMessage(
      { type: 'ledger-height', height: document.documentElement.scrollHeight },
      '*'
    );
  }
  postHeight();
  window.addEventListener('load', postHeight);
  window.addEventListener('resize', postHeight);
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(postHeight);
  }
</script>
</body>
</html>
EOF

echo "Wrote docs/ledger.html"
