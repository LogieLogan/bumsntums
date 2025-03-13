# Technical Architecture

## 3.1 Project Structure
```
├── app.dart
├── features
│   ├── auth
│   │   ├── models
│   │   │   └── user_profile.dart
│   │   ├── providers
│   │   │   ├── auth_provider.dart
│   │   │   └── user_provider.dart
│   │   ├── screens
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── onboarding_screen.dart
│   │   ├── services
│   │   │   └── firebase_auth_service.dart
│   │   └── widgets
│   │       ├── auth_button.dart
│   │       └── profile_setup_form.dart
│   ├── nutrition
│   │   ├── models
│   │   │   ├── food_item.dart
│   │   │   └── nutrition_profile.dart
│   │   ├── providers
│   │   │   ├── food_database_provider.dart
│   │   │   └── scanner_provider.dart
│   │   ├── screens
│   │   │   ├── scanner_screen.dart
│   │   │   ├── nutrition_details_screen.dart
│   │   │   └── food_diary_screen.dart
│   │   ├── services
│   │   │   ├── barcode_scanner_service.dart
│   │   │   ├── ocr_service.dart
│   │   │   └── food_api_service.dart
│   │   └── widgets
│   │       ├── nutrition_card.dart
│   │       └── scanner_overlay.dart
│   ├── workouts
│   │   ├── models
│   │   │   ├── workout.dart
│   │   │   ├── exercise.dart
│   │   │   └── workout_progress.dart
│   │   ├── providers
│   │   │   ├── workout_provider.dart
│   │   │   └── ai_recommendation_provider.dart
│   │   ├── screens
│   │   │   ├── workout_list_screen.dart
│   │   │   ├── workout_detail_screen.dart
│   │   │   └── workout_execution_screen.dart
│   │   ├── services
│   │   │   ├── workout_service.dart
│   │   │   └── openai_service.dart
│   │   └── widgets
│   │       ├── exercise_card.dart
│   │       ├── workout_timer.dart
│   │       └── rep_counter.dart
│   ├── social
│   │   ├── models
│   │   │   ├── post.dart
│   │   │   └── comment.dart
│   │   ├── providers
│   │   │   ├── feed_provider.dart
│   │   │   └── social_interaction_provider.dart
│   │   ├── screens
│   │   │   ├── feed_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── post_creation_screen.dart
│   │   ├── services
│   │   │   └── social_service.dart
│   │   └── widgets
│   │       ├── post_card.dart
│   │       └── user_avatar.dart
│   ├── challenges
│   │   ├── models
│   │   │   ├── challenge.dart
│   │   │   └── leaderboard.dart
│   │   ├── providers
│   │   │   └── challenge_provider.dart
│   │   ├── screens
│   │   │   ├── challenge_list_screen.dart
│   │   │   ├── challenge_detail_screen.dart
│   │   │   └── leaderboard_screen.dart
│   │   ├── services
│   │   │   └── challenge_service.dart
│   │   └── widgets
│   │       ├── challenge_card.dart
│   │       └── leaderboard_item.dart
│   └── splash
│       └── screens
│           └── splash_screen.dart
├── firebase_options_dev.dart
├── firebase_options_prod.dart
├── flavors.dart
├── main.dart
├── main_dev.dart
├── main_prod.dart
└── shared
    ├── components
    │   ├── buttons
    │   │   ├── primary_button.dart
    │   │   └── secondary_button.dart
    │   ├── cards
    │   │   └── base_card.dart
    │   ├── indicators
    │   │   ├── loading_indicator.dart
    │   │   └── progress_indicator.dart
    │   └── metrics
    │       └── metrics_display.dart
    ├── config
    │   └── app_config.dart
    ├── constants
    │   ├── app_constants.dart
    │   ├── route_constants.dart
    │   └── string_constants.dart
    ├── analytics
    │   ├── firebase_analytics_service.dart
    │   └── crash_reporting_service.dart
    ├── models
    │   └── app_user.dart
    ├── providers
    │   └── app_state_provider.dart
    ├── services
    │   ├── firebase_service.dart
    │   ├── storage_service.dart
    │   └── notification_service.dart
    ├── theme
    │   ├── app_theme.dart
    │   ├── color_palette.dart
    │   └── text_styles.dart
    └── utils
        ├── date_utils.dart
        ├── validator_utils.dart
        └── string_utils.dart
```

## 3.2 State Management & Dependency Injection
- **Primary State Management:** Riverpod for reactive state management
  - Note: While Riverpod has a higher learning curve than alternatives like Provider or GetX, it offers better long-term scalability for a feature-rich app like Bums 'n' Tums
- **Local Storage:** Hive for efficient local storage
- **Service Locator:** GetIt for dependency injection
- **Navigation:** Go Router for declarative routing

## 3.3 Mobile App Configuration
- Will use Flutter flavors for development, staging, and production environments
- Separate Firebase projects for development and production
- FlutterFire CLI will be used for Firebase initialization

## 3.4 Performance Considerations

### Image and Asset Management
- Implement progressive image loading
- Use appropriate image formats (WebP for static, JPEG for photos)
- Apply image compression for user uploads
- Implement asset preloading for common resources

### Network Optimization
- Implement connection state awareness
- Add offline capability for core features
- Use caching strategies for API responses
- Implement batch operations for firestore

### Battery Optimization
- Optimize location services usage
- Batch database operations
- Implement efficient background processing
- Use WorkManager for scheduled tasks