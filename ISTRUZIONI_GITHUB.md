# Istruzioni GitHub: build della ROM e accesso per Claude

Cosa serve: un account GitHub (il tuo è `Clutsy`) e `git` sul PC. Il lavoro pesante lo fa il runner gratuito di GitHub
(repo pubblico: 4 vCPU, 16 GB RAM, 14 GB disco, 6 ore per job, 10 GB di cache). Non è garantito che basti: vedi "Limiti".

## 1. Crea il repo e carica i file
1. github.com → **New repository** → nome `s3neo-lineage23`, **Public**, senza README/.gitignore/licenza.
2. Sul PC (la cartella `.github` è nascosta: usa git, non il caricamento da browser):
```
unzip s3neo-los23-repo.zip -d s3neo-lineage23
cd s3neo-lineage23
git init -b main
git add -A
git commit -m "initial import"
git remote add origin https://github.com/Clutsy/s3neo-lineage23.git
git push -u origin main
```
3. Controlla che nel repo esista `.github/workflows/build.yml`.

## 2. Impostazioni del repo (una volta sola)
- **Settings → Actions → General → Actions permissions**: *Allow all actions and reusable workflows*
  (il workflow usa `easimon/maximize-build-space`, `actions/cache`, `actions/checkout`, `actions/upload-artifact`).
- **Settings → Actions → General → Workflow permissions**: *Read and write permissions* → Save.

## 3. Scegli la variante giusta (importante per la camera)
- `s3ve3gxx` = sensore posteriore **Sony IMX175**; `s3ve3gjv` = sensore **Samsung S5K4H5YB**. Blob diversi: con la variante sbagliata la camera non parte.
- Dal telefono con ADB: `adb shell cat /sys/class/camera/rear/rear_camtype` (il nodo esiste nel tree; il formato esatto del testo non l'ho verificato)
  oppure `adb shell dmesg | grep -i -E "imx175|s5k4h5yb"`.

## 4. Lancia le run
**Actions → LineageOS 23.2 Galaxy S3 Neo → Run workflow.**
1. `mode = analyze`, `device` = la tua variante. Fa sync + `m nothing` (nessuna compilazione): trova gli errori di porting. Tempo atteso: da decine di minuti a ~2 ore.
2. Quando `analyze` passa: `mode = build`. Se il tempo finisce (il log dice `exit 124`), rilancia `build`: riparte dalla ccache.
3. A build finita la ROM compare in **Releases** (prerelease, `lineage-*.zip` + `boot.img` + `recovery.img`).
4. I log di ogni run vengono scritti nel branch **`ci-logs`** del repo (`run-<id>-<mode>-<device>/summary.txt`, `error.txt`, `soong.txt`, `m-nothing.txt`...).

## 5. Come mi dai accesso
**Opzione A, senza token (la più sicura):** il repo è pubblico, quindi posso leggere il branch `ci-logs` senza credenziali.
Premi *Run workflow* tu, scrivimi "fatto" con il nome del repo, e leggo i log. Le correzioni te le do come patch da committare tu.

**Opzione B, con token (io lancio le run, leggo i log e spingo le correzioni):**
1. GitHub → foto profilo → **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
2. *Token name*: `claude-s3neo` · *Expiration*: **7 giorni** · *Resource owner*: `Clutsy`.
3. *Repository access*: **Only select repositories** → solo `s3neo-lineage23`.
4. *Permissions → Repository permissions*: **Contents: Read and write**, **Actions: Read and write**, **Workflows: Read and write**.
   (*Metadata: Read-only* si aggiunge da solo.) Nient'altro.
5. **Generate token**, copia il valore (`github_pat_...`; non si rivede più) e incollalo in chat.
6. A lavoro finito: stessa pagina → il token → **Delete**/**Revoke**.

Cose da sapere sul token:
- Lo vedrà chiunque abbia accesso alla conversazione: per questo solo 1 repo, solo quei permessi e scadenza breve. Non lo salvo nella memoria e non lo uso fuori da questo repo.
- Con il token posso: fare commit/push nel repo, lanciare il workflow, leggere stato e log dei run (API) e il branch `ci-logs`.
- Non mi dà più potenza di calcolo: la build gira sul runner GitHub.
- Non l'ho potuto provare end-to-end (non ho un token): la lettura di repo pubblici da github.com e api.github.com dal mio ambiente l'ho verificata, il flusso autenticato no.
  Dai log di run e artifact su GitHub non conto di poter scaricare: per questo il workflow scrive i log in `ci-logs`.

## 6. Limiti, onestà inclusa
- La prima `analyze` quasi certamente fallirà: le patch sono state controllate solo nel senso "si applicano" (`git am`), non compilate. Si itera sui log.
- 16 GB di RAM sono molto meno dei 64 GB che la wiki di LineageOS chiede per lineage-21+: possibile fuori memoria o più run.
- "Compila" non vuol dire "funziona": camera, NFC, LED e flash sono stati preparati nel codice ma non provati su un telefono.
- Prima di flashare: backup di EFS/IMEI e di una ROM funzionante, e un recovery (TWRP) già testato sul telefono.
