Tobacco POS (Flutter)

This project is a demo Flutter application for a Tobacco Point of Sale (POS) system.

Quick setup

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. From project root (G:\flutter_application_1):

   flutter pub get
   flutter run

Optional: Initialize Git and push to GitHub

   git init
   git add .
   git commit -m "Initial project structure and Provider state" \
   Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
   # Create repo on GitHub and push

Notes
- Provider is used for application state (lib/providers/pos_provider.dart)
- RTL (Arabic) is enabled across the app via Directionality in MaterialApp
- Files of interest:
  - lib/main.dart
  - lib/providers/pos_provider.dart
  - lib/models/
  - lib/widgets/

Next steps
- (Recommended) Run `flutter pub get` and `flutter analyze` then `flutter run` on your target.
- Connect to a real product data source, implement persistence and authentication.
