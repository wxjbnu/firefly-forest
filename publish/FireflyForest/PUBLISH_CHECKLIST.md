# Firefly Forest — Publish Checklist

## Project Info

| Field | Value |
|---|---|
| Bundle ID | com.rosewood.fireflyforest |
| Display Name | Firefly Forest |
| Version | 1.0 (Build 1) |
| Team ID | 7ZR52UNP43 |
| Device Family | iPhone only (1) |
| Deployment Target | iOS 13.0 |
| Scheme | FireflyForest |
| Xcode Scheme | FireflyForest |
| Source Dir | /Users/wxj/888ios/batch-game/FireflyForest |
| ReleaseProject Dir | /Users/wxj/888ios/batch-game/FireflyForest-ReleaseProject |
| Publish Output Dir | /Users/wxj/888ios/batch-game/FireflyForest/publish/FireflyForest |

---

## Output File Directory Structure

```
FireflyForest/publish/FireflyForest/
├── index.html
├── privacy.html
├── appstore-review-text.html
├── keywords.txt
├── README.md
└── PUBLISH_CHECKLIST.md
```

---

## Gameplay Fact Card

- **Game Type:** Firefly catching / color-matching arena game
- **Lantern Colors:** 3 — Gold (0), Green (1), Blue (2). Switch via color chips at bottom. Wrong color gives hint "Switch to X light".
- **Catch Radius:** 42pt — any matching-color firefly within radius is caught
- **Scoring:** Base 10pts per catch, multiplied by catch count. Combo: +5 per extra consecutive same-color catch within 2.5s window
- **Rare Golden Firefly:** Type 3, spawns Level 3+ only, 8% chance, caught with Gold lantern, awards +50 bonus points
- **Target Catches:** MIN(24, 6 + level x 2)
- **Time Limit:** MAX(25, 55 - level x 0.65) seconds (starts 55s, decreases by 0.65s per level, minimum 25s)
- **Firefly Count:** MIN(34, 10 + level x 2)
- **Color Activation:** Level 1-2: 2 colors active; Level 3+: all 3 colors active
- **Areas:** 50 total (Area 1 = Level 1)
- **Progress Storage:** NSUserDefaults stores unlocked area number
- **Background:** forest_bg texture, dark forest arena
- **HUD:** Score, timer, capture count/target, combo indicator, progress bar
- **Particle Effect:** Particle burst on successful catch
- **Lantern Glow:** Pulsing glow effect on the lantern
- **Menu Buttons:** Enter Forest, Areas, Settings
- **Area Select:** 4x4 grid, 16 areas per page, 4 pages total (50 areas)

---

## Archive Command

```bash
xcodebuild -project FireflyForest.xcodeproj \
  -scheme FireflyForest \
  -configuration Release \
  -archivePath ./BuildArtifacts/FireflyForest.xcarchive \
  archive
```

---

## App Store Connect Field Values

| Field | Value |
|---|---|
| Promotional Text (field-0) | See appstore-review-text.html / field-0 |
| Title (field-1) | Firefly Forest |
| Subtitle (field-2) | Catch Fireflies in the Dark Forest |
| Description (field-3) | See appstore-review-text.html / field-3 |
| Keywords (field-4) | firefly,catch,lantern,forest,color,combo,night,organic,survival,collect,glow,bug,quest,game |
| URL | https://rosewood.itch.io/firefly-forest |
| Support URL | https://rosewood.itch.io/firefly-forest |
| Marketing URL | (optional) |
| Privacy Policy URL | https://firefly-forest.vercel.app/privacy |
| Primary Category | Games |
| Secondary Category | Family |
| Content Rating | 4+ |
| Age Band | N/A |
| Additional Category 1 | Casual |
| Additional Category 2 | (none) |

---

## Screenshot Specs

| Size | Orientation | Min Resolution | Files |
|---|---|---|---|
| 6.7" (iPhone 14/15 Pro) | Portrait | 1290 x 2796 | menu.png, game1.png, game2.png, game-success.png (source) |
| 5.5" (iPhone 8/7/6s Plus) | Portrait | 1242 x 2208 | (from same source files, scaled) |
| 12.9" (iPad Pro 3rd) | Portrait | 2048 x 2732 | (optional) |

Source screenshot paths:
- /Users/wxj/888ios/batch-game/FireflyForest/publish/menu.png
- /Users/wxj/888ios/batch-game/FireflyForest/publish/game1.png
- /Users/wxj/888ios/batch-game/FireflyForest/publish/game2.png
- /Users/wxj/888ios/batch-game/FireflyForest/publish/game-success.png

---

## Encryption

**NO** — This app does not use any encryption beyond what is provided by iOS.

---

## Privacy Policy URL Note

Publish privacy.html to your hosting provider and provide the full public URL in App Store Connect. The index.html links to `/privacy` (no .html extension). Ensure your server rewrites `/privacy` to serve `privacy.html`, or update the link to include `.html`.
