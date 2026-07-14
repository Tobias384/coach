# Branding notes

- App display name: Coach
- Launcher icon config: flutter_launcher_icons.yaml
- Splash config: flutter_native_splash.yaml
- Expected asset files:
  - assets/icon/app_icon.png
  - assets/icon/app_icon_foreground.png
  - assets/splash/splash.png

Run the following when the assets are ready:

```bash
flutter pub add flutter_launcher_icons
flutter pub add flutter_native_splash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```
