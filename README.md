# 2017 Roblox `.rbxl` Offline iOS Viewer & Player (Godot 4 + JIT)

A lightweight, high-performance offline 2017 Roblox `.rbxl` map viewer and single-player experience built with **Godot 4.3**, fully enabled for **JIT (Just-In-Time) compilation** on iOS when sideloaded via **AltStore**, **SideStore**, or **TrollStore**.

---

## Features

- **Offline 2017 `.rbxl` Parser**: Reads uncopyblocked 2017 Roblox XML place files directly from local storage.
- **3D Spatial Matrix Reconstruction**: Converts Roblox `CFrame` rotation matrices and positions into native Godot `Transform3D` matrices.
- **Color & Material Engine**: Translates Roblox `BrickColor` IDs and `Color3uint` values into Godot PBR materials with transparency and reflectance support.
- **Mobile Touch Controls**: Dual-zone virtual joystick for directional movement and right-screen touch drag for FPS/TPS camera rotation.
- **AltStore / SideStore JIT Support**: Pre-configured `Entitlements.plist` enabling `dynamic-codesigning` and `extended-virtual-addressing`.
- **Automated GitHub Actions CI/CD**: Cross-compiles unsigned `.ipa` packages on `macos-latest` ready for sideloading.

---

## Repository Structure

```
├── .github/
│   └── workflows/
│       └── build-ios.yml         # GitHub Actions CI/CD workflow for iOS IPA export
├── maps/
│   └── sample_2017_place.rbxl    # Sample 2017 XML place file with Baseplate, Spawns & Ramps
├── scenes/
│   ├── main_stage.tscn           # Main 3D world scene
│   └── virtual_joystick.tscn     # Mobile HUD virtual touch controls
├── scripts/
│   ├── brickcolor_db.gd          # BrickColor ID to RGB color lookup table
│   ├── cframe_helper.gd          # Roblox CFrame matrix to Godot Transform3D converter
│   ├── main_stage.gd             # Map loader & spawn manager
│   ├── player_controller.gd      # CharacterBody3D player physics & camera look
│   ├── rbxl_parser.gd            # XML .rbxl parser & dynamic 3D node generator
│   └── virtual_joystick.gd       # Touch gesture & joystick input handler
├── Entitlements.plist            # iOS JIT entitlements configuration
├── export_presets.cfg            # Godot 4 iOS export preset
├── project.godot                  # Godot 4 engine configuration
└── README.md
```

---

## iOS JIT Entitlements Configuration (`Entitlements.plist`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>get-task-allow</key>
	<true/>
	<key>dynamic-codesigning</key>
	<true/>
	<key>com.apple.developer.kernel.extended-virtual-addressing</key>
	<true/>
</dict>
</plist>
```

---

## How to Sideload & Enable JIT

1. Push this repository to GitHub.
2. Go to the **Actions** tab on your GitHub repository and wait for the **Build iOS App (JIT Enabled)** workflow to finish.
3. Download the `RobloxViewer-2017-iOS-JIT` `.ipa` artifact.
4. Install onto your iOS device using **AltStore** or **SideStore**.
5. Enable JIT in AltStore/SideStore by long-pressing the app icon and selecting **Enable JIT**.
