# Mobile Banking App

A secure and interactive mobile banking application developed using Flutter and Firebase.

## Features

* User registration and login
* Secure authentication
* Withdraw money
* Transfer money between accounts
* Transaction history
* User profile management
* ID verification upload

## Technology Stack

* Flutter
* Firebase Authentication
* Cloud Firestore
* Firebase Storage

## Project Architecture

```text
lib/
│
├── main.dart
├── firebase_options.dart
│
├── models/
│   ├── user_model.dart
│   ├── account_model.dart
│   └── transaction_model.dart
│
├── services/
│   └── api_service.dart
│
├── widgets/
│   ├── custom_button.dart
│   ├── pin_dialog.dart
│   └── transaction_receipt.dart
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   │
│   ├── home/
│   │   └── dashboard_screen.dart
│   │
│   ├── account/
│   │   ├── deposit_screen.dart
│   │   ├── withdraw_screen.dart
│   │   ├── transfer_screen.dart
│   │   └── transactions_screen.dart
│   │
│   └── profile/
│       ├── profile_screen.dart
│       └── id_preview_screen.dart
```

## Core Functionalities


### Withdraw

Users can withdraw funds after balance validation.

### Transfer

Users can transfer money securely between accounts.

### Transaction History

Users can view all transaction records.

## Backend Services

Firebase services used:

* Firebase Authentication
* Cloud Firestore
* cloudariy Storage

## Security Features

* Authentication validation
* PIN confirmation
* Cloud data protection

## Future Improvements

* OTP verification
* Biometric login
* Push notifications
* QR code payments


