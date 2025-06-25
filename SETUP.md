# Baarikierros Setup Guide

## Quick Start

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Google Maps API Key

**IMPORTANT**: You need to add your Google Maps API key before the app will work properly.

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
4. Create credentials (API Key)
5. Edit `android/app/src/main/AndroidManifest.xml` and replace:
   ```xml
   android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"
   ```
   with your actual API key.

### 3. Run the App

```bash
flutter run
```

## App Features

### 🏠 Home Screen

- Beautiful welcome screen with app branding
- Information cards showing route details
- Start button to begin the bar crawl

### 🗺️ Route Screen

- **Google Maps Integration**: Real-time map with bar markers
- **Location Tracking**: GPS-based proximity detection
- **Progress Overlay**: Shows current bar and route progress
- **Timer Widget**: 15-minute countdown during bar visits
- **Bar Info Overlay**: Displays current bar information with distance

### 🎨 Design Features

- **Modern Dark Theme**: Black, gold, and purple color scheme
- **Semi-transparent Overlays**: Beautiful opacity effects
- **Gradient Backgrounds**: Eye-catching visual elements
- **Responsive Design**: Works on all screen sizes

## Bar Configuration

Edit the bar locations in `lib/providers/app_state.dart`:

```dart
final List<Bar> _barRoute = [
  const Bar(
    name: 'Pub Keskusta',
    lat: 62.8926,  // Replace with actual coordinates
    lon: 27.6785,
    description: 'Klassinen keskustan pubi',
  ),
  // Add more bars...
];
```

## Troubleshooting

### Maps Not Loading

- Verify API key is correctly set in AndroidManifest.xml
- Check that Maps SDK is enabled in Google Cloud Console
- Ensure internet connection is available

### Location Issues

- Grant location permissions when prompted
- Enable location services on device
- Check that location permissions are enabled in app settings

### Build Issues

```bash
flutter clean
flutter pub get
flutter run
```

## Development Notes

The app uses:

- **Provider** for state management
- **Google Maps Flutter** for map integration
- **Geolocator** for location services
- **Go Router** for navigation
- **Modern Material 3** design system

All UI components are custom-built with the specified color scheme and modern styling.
