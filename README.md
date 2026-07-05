# PantryPal

Smart home food management — track expiry dates, shopping lists, star rewards & in-app purchases.

## Package

`com.pantrypalmng.pantrypal`

**Default language:** English (Vietnamese optional in Settings)

## IAP Product IDs (Google Play Console)

| Type | Product ID |
|------|------------|
| Star packs 1–10 | `pp_pack_1` … `pp_pack_10` |
| Remove ads (one-time) | `pp_remove_ads` |

## Release build

```bash
flutter pub get
python tool/generate_logo.py
dart run flutter_launcher_icons
flutter build appbundle --release
```

## Logo

Square 1024×1024 logo at `assets/logo.png` (sharp corners, no rounding).
