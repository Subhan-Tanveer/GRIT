# GRIT — App Icon & Brand Asset Design Blueprint

To position **GRIT** as an elite, ultra-premium product in the fitness space, its app icon and launcher visual system must command attention and reflect its raw, unyielding core. Under typical store conditions, standard icons get lost in visual noise. GRIT's visual system relies on high-density data, raw layout structures, and high contrast. 

This blueprint outlines the visual theory, official store guidelines (Google Play & Apple App Store), and a step-by-step technical implementation guide to deliver a production-grade, premium launcher icon.

---

## 1. Visual Mockups & Brand Assets

We have engineered two high-fidelity visual concepts that capture the **Industrial Brutalist** theme. They rely on high-contrast solid geometry, concrete textures, and GRIT's signature accent color: **Crimson/Oxide Red (`#E94560`)** on a deep **Obsidian Black (`#0A0A0A`)** canvas.

### The GRIT Brutalist App Icon
- **Core Concept**: A minimal, geometric, thick-lined letter **"G"** constructed from interlocking, solid concrete slabs with a textured dark steel finish.
- **Accent border**: A razor-thin, high-contrast border of Crimson Red runs along the inner edge of the glyph, creating an industrial, raw energy that screams stability and power.
- **Placement**: Cleanly centered in the middle of a textured obsidian-black canvas.

### Real-World Home Screen Preview
- **Launcher presence**: Cuts through standard circular or rounded visual clutter with bold concrete geometry.
- **Aesthetic**: Legible, sharp contrast, giving off an ultra-premium, dark-mode-first developer utility feel.

---

## 2. Official Platform Guidelines (Android & iOS)

### A. Android Launcher Icon Guidelines (Material Adaptive Icons)
Adaptive icons, introduced in Android 8.0, allow the system to render launcher icons using different masks (circle, square, squircle, teardrop, etc.) and support dynamic parallax and scale animations.

1. **Layered Structure**:
   - **Background Layer**: Fully opaque, solid color, gradient, or non-moving texture. For GRIT, this is a dark obsidian gray (`#0A0A0A`). Size: **108dp x 108dp**.
   - **Foreground Layer**: Transparent canvas containing the actual logo glyph (`grit_foreground_logo.png`). Size: **108dp x 108dp**.
2. **The Safe Zone (Critical)**:
   - While the total canvas is 108dp x 108dp, the system masks the outer edges.
   - All essential visual content (the "G" glyph) must remain inside the **central 66dp diameter safe zone**. Any details outside this zone will be cropped out or subject to extreme parallax clipping.
3. **Monochromatic App Icon (Android 13+)**:
   - For users who enable "Themed Icons" in their system settings, Android extracts the launcher's background and applies the system's dynamic Material You tinting.
   - You must provide a **monochromatic vector asset** (a transparent background with a single solid color glyph). The system handles the tinting dynamically.
4. **Android Notification Icon**:
   - Must be **completely white (`#FFFFFF`)** with transparent regions. No colors, no gradients.
   - Size: **24dp x 24dp** (rendered across drawable densities: `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).

### B. Apple iOS App Icon Guidelines
Apple enforces strict static visual shapes, which have been updated to support custom dark and tinted modes in **iOS 18+**.

1. **Dimensions & Format**:
   - Standard Size: **1024px x 1024px** (a full square, exported as an uncompressed 24-bit PNG or high-quality JPEG in sRGB).
   - **NO transparency/alpha channels allowed**. The image must be 100% opaque.
   - Do **NOT** apply any rounded corner masks or squircles to the output file. Apple's system dynamically applies its patented squircle mask.
2. **iOS 18+ Adaptive Options**:
   - **Light Mode Icon**: The standard, rich-colored, high-fidelity app icon.
   - **Dark Mode Icon**: A separate version tailored for dark wallpaper mode. Typically drops complex background colors in favor of pitch black (`#000000`) or charcoal with high-contrast glowing brand elements.
   - **Tinted Icon**: A transparent silhouette (monochrome glyph) on a solid dark base. iOS will dynamically shift the hue and saturation of this glyph to match the user's home screen color themes.

---

## 3. App Store Listing Guidelines

To present an ultra-premium app page on the Google Play Store and Apple App Store, the main assets must conform to these specific standards:

| Platform | Asset Name | Dimensions | Format | Key Requirements |
| :--- | :--- | :--- | :--- | :--- |
| **Google Play** | App Icon | `512 x 512 px` | 32-bit PNG (sRGB) | Max 1MB. Flat design, no custom rounded corners or drop shadows (Play Store applies a 20% corner radius dynamically). |
| **Google Play** | Feature Graphic | `1024 x 500 px` | JPEG or 24-bit PNG | Crucial for promotion. Keep logo, text, and main imagery within the central **600 x 300 px** safe area to avoid truncation on smaller displays. |
| **Apple App Store** | App Store Icon | `1024 x 1024 px` | 24-bit PNG (no alpha) | High-fidelity master asset. Ensure high contrast and strict brutalist visual alignment. |
| **Both Platforms** | App Screenshots | Various (typically phone aspect ratios: `1242 x 2688 px` for iPhone, `1080 x 2400 px` for Android) | PNG or JPEG | Must display actual running screens of the app (e.g. Active Workout, Rest Timer, Progressive Overload Charts). Emphasize high density and high legibility. |

---

## 4. Flutter Technical Implementation Plan

To implement the premium icons in the GRIT codebase, we will leverage **`flutter_launcher_icons`** (which is already present in your `pubspec.yaml` dev_dependencies!) to automate asset generation across all platform-specific dimensions, directories, and XML manifests.

### Step 1: Asset Preparation
Export the design files from Figma or similar vector editors into the local `assets/images/` directory:
1. **`assets/images/grit_main_logo.png`**: The master square icon (1024x1024px) for iOS, legacy Android, and Web.
2. **`assets/images/grit_foreground_logo.png`**: The transparent foreground glyph (108dp x 108dp, keeping the graphic strictly in the central 66dp circular safe zone).
3. **`assets/images/grit_monochrome_logo.png`**: The monochrome icon (transparent background with solid black glyph) for Android 13+ Material You themed icons.

### Step 2: Configure `pubspec.yaml`
Update `pubspec.yaml` to ensure the properties target the correct assets:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/grit_main_logo.png"
  
  # Android Adaptive Icon Configuration
  adaptive_icon_background: "#0A0A0A" # Obsidian Black Background
  adaptive_icon_foreground: "assets/images/grit_foreground_logo.png"
  adaptive_icon_monochrome: "assets/images/grit_monochrome_logo.png" # Themed Icons (Android 13+)

  # Notification Icon Configuration
  notification_icon:
    image_path: "assets/images/grit_foreground_logo.png"
    resource_name: "ic_notification"

  # Web Configuration
  web:
    generate: true
    image_path: "assets/images/grit_main_logo.png"
    background_color: "#0A0A0A"
    theme_color: "#E94560"
```

### Step 3: Run the Icon Generator
Run the generator package in the project root to compile the assets into all necessary platform-native folders (`android/app/src/main/res/mipmap-*` and `ios/Runner/Assets.xcassets/AppIcon.appiconset`):

```powershell
# In terminal, run:
flutter pub run flutter_launcher_icons
```

### Step 4: Configure Native Splash Screen
To maintain brand cohesiveness from the microsecond the user taps the icon, synchronize the premium icon with the **Native Splash Screen** configuration already available in the project:

```yaml
flutter_native_splash:
  color: "#0A0A0A" # Pitch-black background
  image: "assets/images/grit_main_logo.png" # Centered main brutalist logo
  android: true
  ios: true
  web: true
  fullscreen: true
  android_12:
    image: "assets/images/grit_main_logo.png"
    color: "#0A0A0A"
```

Generate the native splash files using:
```powershell
flutter pub run flutter_native_splash:create
```

---

## 5. Summary of Actions for High-Quality Store Review

1. **Vector-to-Raster Master Assets**: Standardize design assets to vector templates before exporting to raster (`.png`) format.
2. **Vibrant & Bold Contrast**: Verify high contrast of the accent Crimson `#E94560` against Obsidian Black `#0A0A0A` to guarantee outdoor legibility under gym lighting conditions.
3. **Adaptive Animation Verification**: Run the app on an Android emulator, select a squircle or teardrop icon shape from launcher settings, and long-press the GRIT app icon to test the physical parallax animation of the adaptive foreground layer.
4. **App Store Visual Consistency**: Ensure that Google Play store graphics, promo billboards (Feature Graphic), and screenshots use the exact same color scheme (Obsidian background, Concrete panels, Crimson highlights) to establish a premium and cohesive presence.
