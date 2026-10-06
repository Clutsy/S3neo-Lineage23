# Compilare la ROM su Crave (il metodo usato dalla community)

La community delle ROM Android non compila su runner gratuiti di GitHub: usa **Crave.io**, che offre server di build con i
sorgenti AOSP/LineageOS già sincronizzati ("base project"). Il repo più usato è **`sounddrill31/crave_aosp_builder`**
(Apache-2.0, ultimo commit 2026-10-03): GitHub Actions lancia soltanto il comando `crave run`, la compilazione gira sui server di Crave.
Ha già il base project **LineageOS 23.2** (manifest `accupara/los23.2`, branch `lineage-23.2`: stessi nomi di progetto e snippet di LineageOS).

## Cosa serve (non lo posso fare io)
Un account su **foss.crave.io**. Le iscrizioni autonome sono disabilitate: va chiesto agli sviluppatori
(README del repo: contattare `uvatbc` / `yuvraaj` su Telegram o `sounddrill` su Discord o sul Telegram *ROM Builders*;
da condividere: nome, email, profilo Git con i tuoi sorgenti). Questa informazione è del README, non l'ho verificata altrove,
e l'accesso lo decidono loro. Bozza del messaggio: nella chat.

## Una volta ottenuto l'account
1. Fai un **fork** di `sounddrill31/crave_aosp_builder` sul tuo account.
2. Dalla dashboard di foss.crave.io scarica `crave.conf` (API Keys).
3. Fork → Settings → Secrets and variables → Actions: crea `CRAVE_USERNAME` (l'email con cui ti sei iscritto) e `CRAVE_TOKEN`
   (la parte "Authorization" di `crave.conf`, senza `:` né spazi).
4. Fork → Settings → Actions → General → Workflow permissions: **Read and write**.
5. Segui nel README del fork "Selfhosted Runners" (workflow *Create Selfhosted Runner*, poi *Crave Builder(self-hosted)*).

## Input da inserire in "Crave Builder(self-hosted)"
| Campo | Valore |
|---|---|
| Base project | `LineageOS 23.2` |
| Personal local manifest | `https://github.com/Clutsy/S3neo-Lineage23` |
| Local manifest branch | `main` |
| Device's codename | `s3ve3gxx` (Sony IMX175) oppure `s3ve3gjv` (Samsung S5K4H5YB) |
| Product to build | `aosp_arm-bp4a` (serve solo al primo `lunch`, che gira prima delle patch) |
| Type of build | `userdebug` |
| Command to be used for compiling | `bash .repo/local_manifests/scripts/prepare.sh && source build/envsetup.sh && breakfast s3ve3gxx userdebug && mka bacon` |
| Build with a clean workspace | `yes` per le prime run |

Perché così: il workflow clona il nostro repo in `.repo/local_manifests` (repo legge il file `s3ve3g.xml` in radice: è un collegamento a
`local_manifests/s3ve3g.xml`), esegue `/opt/crave/resync.sh`, poi `lunch`, poi il nostro comando. `prepare.sh` scarica i blob da TheMuppets,
i due file VNDK v29 da AOSP e applica le patch in `patches/` (idempotente: rilanciarlo non ripete le patch già applicate).
Il comando fa `breakfast` dopo le patch perché `lunch` è partito prima di averle applicate; `lineage_s3ve3gxx-bp4a-userdebug` è la
stringa che `breakfast` costruisce (release `bp4a` da `vendor/lineage/vars/aosp_target_release`, verificato su 23.2).

## Limiti onesti
- Non ho un account Crave e non ho potuto provare niente di questo flusso: è preparato e verificato solo leggendo il codice del workflow.
- Anche con Crave, le patch (camera HAL1, NFC, LED, boot image) non sono mai state compilate: la prima build fallirà quasi certamente e si
  lavora sui log (`out/error.log`, che il workflow scarica con `crave pull`).
- Per far leggere i log a me, incollali qui o caricali nel repo.
