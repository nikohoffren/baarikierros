# Baarikierros - Flutter App

Flutter app for organizing and participating in bar crawls with real-time location tracking and Google Maps integration.

## Features

- **Google Maps Integration** - Real-time map view with bar locations
- **Location Tracking** - GPS-based proximity detection
- **Timer System** - 15-minute countdown for each bar visit
- **Progress Tracking** - Visual progress indicators
- **Completion Screen** - Celebration when route is finished

## Screenshots

The app features:

- **Home Screen**: Welcome screen with app information and start button
- **Route Screen**: Interactive map with bar markers and overlay information
- **Timer Overlay**: Beautiful countdown timer during bar visits
- **Completion Screen**: Celebration screen when all bars are visited

## Setup Instructions

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code
- Google Maps API Key

### 1. Clone the Repository

```bash
git clone <repository-url>
cd baarikierros
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
4. Create credentials (API Key)
5. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` in `android/app/src/main/AndroidManifest.xml` with your actual API key

### 4. Configure Bar Locations

Edit the bar locations in `lib/providers/app_state.dart`:

```dart
final List<Bar> _barRoute = [
  const Bar(
    name: 'Your Bar Name',
    lat: YOUR_LATITUDE,
    lon: YOUR_LONGITUDE,
    description: 'Bar description',
  ),
  // Add more bars...
];
```

### 5. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── bar.dart             # Bar data model
├── providers/
│   └── app_state.dart       # State management
├── screens/
│   ├── home_screen.dart     # Welcome screen
│   └── route_screen.dart    # Main route screen
├── services/
│   ├── location_service.dart # GPS and location utilities
│   └── timer_service.dart   # Timer functionality
├── theme/
│   └── app_theme.dart       # App styling and colors
└── widgets/
    ├── bar_info_overlay.dart # Bar information overlay
    └── timer_widget.dart    # Countdown timer widget
```

## Color Scheme

The app uses a modern dark theme with:

- **Primary Black**: `#1A1A1A`
- **Secondary Black**: `#2D2D2D`
- **Accent Gold**: `#FFD700`
- **Accent Yellow**: `#FFEB3B`
- **Deep Purple**: `#673AB7`
- **Light Purple**: `#9C27B0`

## Dependencies

- `google_maps_flutter`: Google Maps integration
- `geolocator`: Location services
- `permission_handler`: Permission management
- `go_router`: Navigation
- `provider`: State management
- `flutter_svg`: SVG support

## How It Works

1. **Home Screen**: Users see app information and can start a bar crawl
2. **Route Screen**:
   - Shows Google Map with bar markers
   - Tracks user location in real-time
   - Displays current bar information in overlay
   - Checks proximity when user tries to enter a bar
3. **Timer**: 15-minute countdown starts when user enters a bar
4. **Progress**: Visual indicators show route completion
5. **Completion**: Celebration screen when all bars are visited

### Build Issues

```bash
flutter clean
flutter pub get
flutter run
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please open an issue in the repository.
