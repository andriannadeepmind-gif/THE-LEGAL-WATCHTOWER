# ============================================================================
# LAWMAX OPERATOR CONSOLE — κουμπιά χειριστή (Windows / PowerShell)
# ============================================================================
# ΕΡΓΑΛΕΙΟ ΧΕΙΡΙΣΤΗ, ΟΧΙ runtime feature: δεν αλλάζει ΤΙΠΟΤΑ στο σύστημα —
# απλώς εκτελεί τις ΥΠΑΡΧΟΥΣΕΣ εντολές του μητρώου (builtin-commands.lisp)
# μέσω docker run, με τα σωστά mounts. Πατάς αριθμό → τρέχει η εντολή.
#
# Χρήση:  cd $HOME\STAVROPOULOSLAWCORPUS
#         powershell -ExecutionPolicy Bypass -File deployment\tools\lawmax-console.ps1
# ============================================================================

$ROOT  = (Get-Location).Path
if (-not (Test-Path "$ROOT\deployment")) {
  Write-Host "Τρέξε με από τη ρίζα του repo (εκεί που υπάρχει το deployment\)." -ForegroundColor Red
  exit 1
}
$IMAGE = if ($env:IMAGE) { $env:IMAGE } else { "orchestrator:latest" }

function Invoke-Lawmax {
  param([string[]]$CmdArgs, [string]$Corpus = "")
  $dockerArgs = @("run","--rm",
    "-v","$ROOT\output:/app/output",
    "-v","$ROOT\deployment:/app/deployment",
    "-v","$ROOT\input:/app/input")
  if ($Corpus -ne "") { $dockerArgs += @("-e","ORCHESTRATOR_CORPUS=$Corpus") }
  $dockerArgs += @($IMAGE) + $CmdArgs
  Write-Host ""
  Write-Host ("docker " + ($dockerArgs -join " ")) -ForegroundColor DarkGray
  & docker @dockerArgs
  Write-Host ""
  Write-Host "── exit code: $LASTEXITCODE ──" -ForegroundColor Yellow
}

function Select-Corpus {
  Write-Host ""
  Write-Host "  1) syntagma   2) poinikos   3) kpoinikis" -ForegroundColor Cyan
  Write-Host "  4) astikos    5) kpolitikis 6) kdioikitikis   0) ΟΛΟΙ" -ForegroundColor Cyan
  $c = Read-Host "Κώδικας"
  switch ($c) {
    "1" { return @("syntagma") }
    "2" { return @("poinikos") }
    "3" { return @("kpoinikis") }
    "4" { return @("astikos") }
    "5" { return @("kpolitikis") }
    "6" { return @("kdioikitikis") }
    "0" { return @("syntagma","poinikos","kpoinikis","astikos","kpolitikis","kdioikitikis") }
    default { Write-Host "Άκυρη επιλογή" -ForegroundColor Red; return @() }
  }
}

while ($true) {
  Write-Host ""
  Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
  Write-Host "║        LAWMAX OPERATOR CONSOLE — πάτα αριθμό              ║" -ForegroundColor Green
  Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
  Write-Host "  ── ΔΙΑΛΟΓΟΣ ──"
  Write-Host "   1. Ρώτησε το σύστημα (--ask)"
  Write-Host "   2. Web chat (--serve στο http://localhost:8080)"
  Write-Host "  ── ΕΛΕΓΧΟΣ ──"
  Write-Host "   3. Ολομέλεια πυλών (--gates)"
  Write-Host "   4. Καθρέφτης (--mirror)"
  Write-Host "   5. Μητρώο αποτυχιών (--failures)"
  Write-Host "   6. Τελευταίο συμπέρασμα (--trace-last-conclusion)"
  Write-Host "  ── ΠΑΡΑΓΩΓΗ ΑΡΘΡΩΝ ──"
  Write-Host "   7. ΟΛΟΙ οι κώδικες: πλήρες pipeline (--run-all-pipelines)"
  Write-Host "   8. ΕΝΑΣ κώδικας: pipeline (--run-pipeline)"
  Write-Host "   9. Αποδείξεις άρθρων (--emit-proofs)"
  Write-Host "  10. Παραπομπές (--emit-references)"
  Write-Host "  11. Υπεργράφος (--emit-hypergraph)"
  Write-Host "  12. Νοημοσύνη κώδικα (--verify-intelligence)"
  Write-Host "  ── ΕΠΑΛΗΘΕΥΣΗ ──"
  Write-Host "  13. Επαλήθευση ΟΛΩΝ των corpora (--verify-all)"
  Write-Host "  14. Blind failure test (v3, ερμητικό)"
  Write-Host "  ── ΑΛΛΟ ──"
  Write-Host "  15. Ελεύθερη εντολή (γράφεις ό,τι θες, π.χ. --help)"
  Write-Host "   0. Έξοδος"
  $choice = Read-Host "Επιλογή"

  switch ($choice) {
    "1"  { $q = Read-Host "Η ερώτησή σου"; Invoke-Lawmax @("--ask", $q) }
    "2"  { Write-Host "Άνοιξε http://localhost:8080 στον browser. Ctrl+C για τερματισμό." -ForegroundColor Cyan
           & docker run --rm -p 8080:8080 -v "$ROOT\output:/app/output" -v "$ROOT\deployment:/app/deployment" $IMAGE --serve }
    "3"  { Invoke-Lawmax @("--gates") }
    "4"  { Invoke-Lawmax @("--mirror") }
    "5"  { Invoke-Lawmax @("--failures") }
    "6"  { Invoke-Lawmax @("--trace-last-conclusion") }
    "7"  { Invoke-Lawmax @("--run-all-pipelines") }
    "8"  { foreach ($c in (Select-Corpus)) { Invoke-Lawmax @("--run-pipeline") -Corpus $c } }
    "9"  { foreach ($c in (Select-Corpus)) { Invoke-Lawmax @("--emit-proofs") -Corpus $c } }
    "10" { foreach ($c in (Select-Corpus)) { Invoke-Lawmax @("--emit-references") -Corpus $c } }
    "11" { foreach ($c in (Select-Corpus)) { Invoke-Lawmax @("--emit-hypergraph") -Corpus $c } }
    "12" { foreach ($c in (Select-Corpus)) { Invoke-Lawmax @("--verify-intelligence") -Corpus $c } }
    "13" { Invoke-Lawmax @("--verify-all") }
    "14" { $q1 = Read-Host "Blind ερώτηση 1"; $q2 = Read-Host "Blind ερώτηση 2"; $q3 = Read-Host "Blind ερώτηση 3"
           & "C:\Program Files\Git\bin\bash.exe" -lc 'bash deployment/verify/blind-failure-test.sh "$@"' -- $q1 $q2 $q3 }
    "15" { $free = Read-Host "Εντολή (π.χ. --help)"; Invoke-Lawmax ($free -split " ") }
    "0"  { break }
    default { Write-Host "Άκυρη επιλογή" -ForegroundColor Red }
  }
  if ($choice -eq "0") { break }
}
