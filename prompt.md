Using the Project Knowledge and the specs provided as your core instructions please help me build my flutter mobile ios app on the defined area of focus. 

Area of focus:
phase 2 implementation
I am getting a permissions issue when trying to access the progress tab (calendar screen)
11.8.1 - [FirebaseFirestore][I-FST000001] Listen for query at workout_logs failed: Missing or insufficient permissions.
flutter: Error getting workout history by week: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
11.8.1 - [FirebaseFirestore][I-FST000001] Listen for query at workout_logs failed: Missing or insufficient permissions.
flutter: Error getting workout history by week: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
11.8.1 - [FirebaseFirestore][I-FST000001] Listen for query at workout_logs failed: Missing or insufficient permissions.
flutter: Error getting workout history by week: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
11.8.1 - [FirebaseFirestore][I-FST000001] Listen for query at workout_logs failed: Missing or insufficient permissions.
flutter: Error getting workout history by week: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
11.8.1 - [FirebaseFirestore][I-FST000001] WatchStream (313630613334313538) Stream error: 'Cancelled: Disconnecting idle stream. Timed out waiting for new targets.'
etc.............

Project folder structure:

├── app.dart
├── features
│   ├── ai
│   │   ├── providers
│   │   │   ├── ai_chat_provider.dart
│   │   │   ├── openai_provider.dart
│   │   │   └── workout_recommendation_provider.dart
│   │   ├── screens
│   │   │   ├── ai_chat_screen.dart
│   │   │   └── ai_workout_screen.dart
│   │   └── services
│   │       └── openai_service.dart
│   ├── auth
│   │   ├── models
│   │   │   └── user_profile.dart
│   │   ├── providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── fitness_profile_provider.dart
│   │   │   └── user_provider.dart
│   │   ├── screens
│   │   │   ├── edit_profile_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── services
│   │   │   ├── firebase_auth_service.dart
│   │   │   ├── fitness_profile_service.dart
│   │   │   └── google_sign_in_service.dart
│   │   └── widgets
│   │       ├── apple_sign_in_button.dart
│   │       ├── auth_button.dart
│   │       ├── google_sign_in_button.dart
│   │       └── onboarding
│   │           ├── components
│   │           │   ├── goal_option.dart
│   │           │   ├── level_option.dart
│   │           │   ├── privacy_policy_dialog.dart
│   │           │   ├── scrollable_step.dart
│   │           │   ├── step_progress_indicator.dart
│   │           │   └── terms_conditions_dialog.dart
│   │           ├── profile_setup_coordinator.dart
│   │           └── steps
│   │               ├── basic_info_step.dart
│   │               ├── body_focus_step.dart
│   │               ├── capability_questionnaire.dart
│   │               ├── dietary_preferences_step.dart
│   │               ├── fitness_level_step.dart
│   │               ├── goals_step.dart
│   │               ├── measurements_step.dart
│   │               └── workout_environment_step.dart
│   ├── home
│   │   ├── providers
│   │   │   ├── display_name_provider.dart
│   │   │   ├── recommended_workout_provider.dart
│   │   │   └── workout_stats_provider.dart
│   │   ├── screens
│   │   │   ├── home_screen.dart
│   │   │   ├── home_tab.dart
│   │   │   └── profile_tab.dart
│   │   └── widgets
│   │       ├── ai_workout_creator_card.dart
│   │       ├── category_card.dart
│   │       ├── featured_workout_card.dart
│   │       ├── quick_action_card.dart
│   │       ├── stats_card.dart
│   │       └── welcome_card.dart
│   ├── nutrition
│   │   ├── models
│   │   │   └── food_item.dart
│   │   ├── providers
│   │   │   └── food_scanner_provider.dart
│   │   ├── repositories
│   │   │   └── food_repository.dart
│   │   ├── screens
│   │   │   ├── food_details_screen.dart
│   │   │   └── scanner_screen.dart
│   │   └── services
│   │       ├── barcode_scanner_service.dart
│   │       ├── ml_kit_service.dart
│   │       ├── open_food_facts_service.dart
│   │       └── permissions_service.dart
│   ├── settings
│   │   └── screens
│   │       └── gdpr_settings_screen.dart
│   ├── splash
│   │   └── screens
│   │       └── splash_screen.dart
│   └── workouts
│       ├── models
│       │   ├── exercise.dart
│       │   ├── workout.dart
│       │   ├── workout_log.dart
│       │   ├── workout_plan.dart
│       │   ├── workout_stats.dart
│       │   └── workout_streak.dart
│       ├── providers
│       │   ├── exercise_selector_provider.dart
│       │   ├── workout_editor_provider.dart
│       │   ├── workout_execution_provider.dart
│       │   ├── workout_planning_provider.dart
│       │   ├── workout_provider.dart
│       │   └── workout_stats_provider.dart
│       ├── repositories
│       │   └── custom_workout_repository.dart
│       ├── screens
│       │   ├── custom_workouts_screen.dart
│       │   ├── exercise_editor_screen.dart
│       │   ├── exercise_selector_screen.dart
│       │   ├── workout_analytics_screen.dart
│       │   ├── workout_browse_screen.dart
│       │   ├── workout_calendar_screen.dart
│       │   ├── workout_completion_screen.dart
│       │   ├── workout_detail_screen.dart
│       │   ├── workout_editor_screen.dart
│       │   ├── workout_execution_screen.dart
│       │   └── workout_search_screen.dart
│       ├── services
│       │   ├── exercise_db_service.dart
│       │   ├── voice_guidance_service.dart
│       │   ├── workout_planning_service.dart
│       │   ├── workout_service.dart
│       │   └── workout_stats_service.dart
│       └── widgets
│           ├── category_card.dart
│           ├── execution
│           │   ├── exercise_completion_animation.dart
│           │   ├── exercise_timer.dart
│           │   ├── rest_timer.dart
│           │   └── workout_progress_indicator.dart
│           ├── exercise_list_item.dart
│           └── workout_card.dart
├── firebase_options_dev.dart
├── flavors.dart
├── main.dart
├── main_dev.dart
├── main_prod.dart
├── shared
│   ├── analytics
│   │   ├── crash_reporting_service.dart
│   │   └── firebase_analytics_service.dart
│   ├── components
│   │   ├── buttons
│   │   │   ├── primary_button.dart
│   │   │   └── secondary_button.dart
│   │   ├── feedback
│   │   │   ├── feedback_button.dart
│   │   │   ├── feedback_utils.dart
│   │   │   ├── satisfaction_prompt.dart
│   │   │   └── shake_to_report.dart
│   │   └── indicators
│   │       └── loading_indicator.dart
│   ├── config
│   │   ├── app_config.dart
│   │   └── router.dart
│   ├── constants
│   │   └── app_constants.dart
│   ├── models
│   │   ├── app_user.dart
│   │   └── legal_document.dart
│   ├── navigation
│   │   ├── auth_guard.dart
│   │   └── navigation.dart
│   ├── providers
│   │   ├── analytics_provider.dart
│   │   ├── environment_provider.dart
│   │   ├── feedback_provider.dart
│   │   └── firebase_providers.dart
│   ├── repositories
│   │   ├── mock_data
│   │   │   ├── bums_workouts.dart
│   │   │   ├── full_body_workouts.dart
│   │   │   ├── index.dart
│   │   │   ├── quick_workouts.dart
│   │   │   └── tums_workouts.dart
│   │   └── mock_workout_repository.dart
│   ├── services
│   │   ├── consent_management_service.dart
│   │   ├── data_retention_service.dart
│   │   ├── environment_service.dart
│   │   ├── fallback_image_provider.dart
│   │   ├── feedback_service.dart
│   │   ├── firebase_service.dart
│   │   ├── gdpr_service.dart
│   │   ├── legal_document_service.dart
│   │   └── shake_detector_service.dart
│   └── theme
│       ├── app_theme.dart
│       ├── color_palette.dart
│       └── text_styles.dart
└── specs
    ├── 00_project_overview.md
    ├── 01_user_journeys.md
    ├── 02_design_system.md
    ├── 03_technical_architecture.md
    ├── 04_firebase_architecture.md
    ├── 05a_ai_integration.md
    ├── 05b_ai_integration.md
    ├── 06a_auth_system.md
    ├── 06b_food_scanning.md
    ├── 06c_workouts.md
    ├── 06d_social_features.md
    ├── 06d_workout_tracking_analytics.md
    ├── 06e_challenges.md
    ├── 06f_in_app_purchases.md
    ├── 07_analytics_and_monitoring.md
    ├── 08a_security_and_compliance.md
    ├── 08b_gdpr_dpia.md
    ├── 08c_gdpr_testing_plan.md
    ├── 09_implementation_plan.md
    ├── 10a_early_feedback.md
    ├── 10b_advanced_feedback.md
    ├── 11_gamification.md
    ├── 12_accessibility.md
    └── 13_ux_ui_spec.md
    
Which of these files do you want to review? 


things to do: 
