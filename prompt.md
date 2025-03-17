Using the Project Knowledge as your core persona and instructions please help me build my flutter mobile ios app on the defined area of focus. 

Area of focus:
onboarding polish off
fitness level isnt remembered when going back to that step
workout environment - in the equipment more section the items cant be selected. Also these items need to be extended for more options focused on womens fitness like step climber and vibation plates etc.
The duration section 60 and 60+ min are both selected when selcting either of them. We can likely just keep 60+ mins.
Helath considerations section is too sensitive and should be replaced with something more vague like a capability questionair ie.. can you touch your toes?, how long would be a typical run (i don't run to an hour plus), keep it light hearted and easy to answer. The purpose is to provide clear seperation of users abilities without asking personal questions. there should be 5 to 10 questions. none all or some can be answered. 
food allergies and dietry preferences should be on their own step. instead of allergies it should be exclusions. The first and most obvious option in all cases should be none so that most users can swiftly pass this step. 
we can remove the what motivates you step. 

Project folder structure:

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
│   │   │   ├── onboarding_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── services
│   │   │   ├── firebase_auth_service.dart
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
│   │           │   └── step_progress_indicator.dart
│   │           ├── profile_setup_coordinator.dart
│   │           └── steps
│   │               ├── basic_info_step.dart
│   │               ├── body_focus_step.dart
│   │               ├── fitness_level_step.dart
│   │               ├── goals_step.dart
│   │               ├── health_and_diet_step.dart
│   │               ├── measurements_step.dart
│   │               ├── motivation_step.dart
│   │               └── workout_environment_step.dart
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
│   │   ├── services
│   │   │   ├── barcode_scanner_service.dart
│   │   │   ├── ml_kit_service.dart
│   │   │   ├── open_food_facts_service.dart
│   │   │   └── permissions_service.dart
│   │   └── widgets
│   ├── splash
│   │   └── screens
│   │       └── splash_screen.dart
│   └── workouts
│       ├── models
│       │   ├── exercise.dart
│       │   ├── workout.dart
│       │   └── workout_log.dart
│       ├── providers
│       │   ├── workout_execution_provider.dart
│       │   └── workout_provider.dart
│       ├── screens
│       │   ├── workout_browse_screen.dart
│       │   ├── workout_completion_screen.dart
│       │   ├── workout_detail_screen.dart
│       │   ├── workout_execution_screen.dart
│       │   └── workout_search_screen.dart
│       ├── services
│       │   └── workout_service.dart
│       └── widgets
│           ├── category_card.dart
│           ├── execution
│           │   ├── exercise_timer.dart
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
│   │   └── app_user.dart
│   ├── navigation
│   │   ├── auth_guard.dart
│   │   ├── home_screen.dart
│   │   └── navigation.dart
│   ├── providers
│   │   ├── analytics_provider.dart
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
│   │   ├── feedback_service.dart
│   │   ├── firebase_service.dart
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
    ├── 05_ai_integration.md
    ├── 06a_auth_system.md
    ├── 06b_food_scanning.md
    ├── 06c_workouts.md
    ├── 06d_social_features.md
    ├── 06e_challenges.md
    ├── 06f_in_app_purchases.md
    ├── 07_analytics_and_monitoring.md
    ├── 08_security_and_compliance.md
    ├── 09_implementation_plan.md
    ├── 10_early_feedback.md
    ├── 11_gamification.md
    └── 12_accessibility.md

Do you understand what we are trying to achieve?
