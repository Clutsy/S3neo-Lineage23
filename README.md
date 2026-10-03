# Galaxy S3 Neo → LineageOS 23.2 (Android 16): build su GitHub Actions

Stato: **pipeline e patch pronte, mai eseguite su un runner**. Nessuna build di questa ROM è mai partita: la prima run di `analyze`
serve a scoprire cosa si rompe. Una ROM funzionante (camera, rete, audio) non è garantita.

## Perché GitHub Actions
La mia sandbox ha 1 CPU / 4 GB RAM / ~8 GB disco, troppo poco. Un repo **pubblico** ha runner gratuiti da
4 vCPU / 16 GB RAM / 14 GB disco (docs GitHub), con limite di 6 ore per job e 10 GB di cache per repo.
La wiki LineageOS chiede 64 GB di RAM per lineage-21+, quindi può servire più di una run o può finire fuori memoria.

**Istruzioni complete passo-passo (repo, impostazioni, token): `ISTRUZIONI_GITHUB.md`.**

## Come lanciarla
1. Crea un repo **pubblico** su GitHub (nei repo privati il runner è più piccolo e consuma minuti).
2. Carica tutto il contenuto di questa cartella, compresa `.github/`, nella root del repo.
3. Actions → *LineageOS 23.2 Galaxy S3 Neo* → *Run workflow*:
   - `mode: analyze` per primo. Esegue sync + `m nothing` (nessuna compilazione) e trova gli errori di porting.
   - `device`: `s3ve3gxx` (sensore Sony IMX175) o `s3ve3gjv` (sensore Samsung S5K4H5YB).
4. A fine run scarica l'artifact: dentro `logs/` ci sono `analyze-*.log.gz` ed `error.log.gz`.
   Mandameli: correggo le patch in `patches/` (formato in `patches/README.md`) e rilanci.
5. Quando `analyze` passa, lancia `mode: build`. Se il tempo finisce (`exit 124` nel log) rilancia: riparte dalla ccache.
   La ROM esce come artifact `lineage-*.zip`.

## Contenuto
- `.github/workflows/build.yml` pipeline (sync / analyze / build, con budget di tempo e ccache salvata anche in caso di timeout)
- `local_manifests/s3ve3g.xml` 18 progetti, tutti i branch verificati esistenti su GitHub
- `scripts/fetch_blobs.sh` blob da TheMuppets lineage-18.1 (SHA1 verificati contro le liste di html6405)
- `scripts/apply_patches.sh`, `scripts/vendor_vndk29.sh`, `patches/` patch testate con `git am` su repo upstream puliti (non compilate): build/make (boot image con dt.img), s3ve3g-common (shim, bootimg, LED, NFC), msm8226-common (vndk v29, camera HAL1 e torcia), frameworks/av e frameworks/base (camera HAL1 per Android 16)
- `kernel-build/` kernel 3.4.113 già compilato nella sandbox (zImage + dtb + config + script)
- `PORTING.md` blocchi noti e ordine di lavoro

## Non risolto (vedi PORTING.md, sezione finale)
Camera HAL1, override SDK dei processi, SELinux legacy: vanno affrontati con i log delle prime run.
