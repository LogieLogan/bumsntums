Using the Project Knowledge and the specs provided as your core instructions please help me build my flutter mobile ios app on the defined area of focus. 

MAIN FOCUS AREA:
phase 2 - re structure workout planning feature

project structure: 

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
│   │   │   └── recommended_workout_provider.dart
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
│       ├── data
│       │   ├── exercise_repository.dart
│       │   ├── local_exercise_repository.dart
│       │   └── sources
│       │       ├── exercise_data_source.dart
│       │       └── json_exercise_data_source.dart
│       ├── models
│       │   ├── exercise.dart
│       │   ├── plan_color.dart
│       │   ├── workout.dart
│       │   ├── workout_log.dart
│       │   ├── workout_plan.dart
│       │   ├── workout_section.dart
│       │   ├── workout_stats.dart
│       │   └── workout_streak.dart
│       ├── providers
│       │   ├── exercise_providers.dart
│       │   ├── exercise_selector_provider.dart
│       │   ├── workout_calendar_provider.dart
│       │   ├── workout_editor_provider.dart
│       │   ├── workout_execution_provider.dart
│       │   ├── workout_planning_provider.dart
│       │   ├── workout_provider.dart
│       │   └── workout_stats_provider.dart
│       ├── repositories
│       │   └── custom_workout_repository.dart
│       ├── screens
│       │   ├── all_featured_workouts_screen.dart
│       │   ├── beginner_workouts_screen.dart
│       │   ├── category_workouts_screen.dart
│       │   ├── custom_workouts_screen.dart
│       │   ├── exercise_detail_screen.dart
│       │   ├── exercise_editor_screen.dart
│       │   ├── exercise_library_screen.dart
│       │   ├── exercise_selector_screen.dart
│       │   ├── favorite_workouts_screen.dart
│       │   ├── pre_workout_setup_screen.dart
│       │   ├── workout_analytics_screen.dart
│       │   ├── workout_browse_screen.dart
│       │   ├── workout_calendar_screen.dart
│       │   ├── workout_completion_screen.dart
│       │   ├── workout_detail_screen.dart
│       │   ├── workout_editor_screen.dart
│       │   ├── workout_execution_screen.dart
│       │   ├── workout_history_screen.dart
│       │   ├── workout_plan_editor_screen.dart
│       │   ├── workout_scheduling_screen.dart
│       │   ├── workout_search_screen.dart
│       │   ├── workout_templates_screen.dart
│       │   └── workout_version_history_screen.dart
│       ├── services
│       │   ├── exercise_db_service.dart
│       │   ├── exercise_service.dart
│       │   ├── smart_plan_detector.dart
│       │   ├── voice_guidance_service.dart
│       │   ├── workout_planning_service.dart
│       │   ├── workout_service.dart
│       │   └── workout_stats_service.dart
│       └── widgets
│           ├── calendar
│           │   ├── recurring_workout_dialog.dart
│           │   └── workout_event_card.dart
│           ├── category_card.dart
│           ├── execution
│           │   ├── exercise_completion_animation.dart
│           │   ├── exercise_settings_modal.dart
│           │   ├── exercise_timer.dart
│           │   ├── rest_timer.dart
│           │   ├── set_rest_timer.dart
│           │   └── workout_progress_indicator.dart
│           ├── exercise_demo_widget.dart
│           ├── exercise_filter_bar.dart
│           ├── exercise_image_widget.dart
│           ├── exercise_list_item.dart
│           ├── exercise_type_tag.dart
│           ├── plan_badge.dart
│           ├── plan_color_picker.dart
│           ├── smart_plan_suggestion_card.dart
│           ├── workout_card.dart
│           └── workout_progress_chart.dart
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
│   │   │   ├── cardio_workouts.dart
│   │   │   ├── full_body_workouts.dart
│   │   │   ├── index.dart
│   │   │   ├── quick_workouts.dart
│   │   │   └── tums_workouts.dart
│   │   └── mock_workout_repository.dart
│   ├── services
│   │   ├── consent_management_service.dart
│   │   ├── data_retention_service.dart
│   │   ├── environment_service.dart
│   │   ├── exercise_icon_mapper.dart
│   │   ├── exercise_media_service.dart
│   │   ├── fallback_image_provider.dart
│   │   ├── feedback_service.dart
│   │   ├── firebase_service.dart
│   │   ├── gdpr_service.dart
│   │   ├── legal_document_service.dart
│   │   ├── resource_loader_service.dart
│   │   └── shake_detector_service.dart
│   ├── theme
│   │   ├── app_theme.dart
│   │   ├── color_palette.dart
│   │   └── text_styles.dart
│   └── utils
│       └── exercise_reference_utils.dart
└── specs
    ├── 00_project_overview.md
    ├── 01_user_journeys.md
    ├── 02_design_system.md
    ├── 03_technical_architecture.md
    ├── 04_firebase_architecture.md
    ├── 05a_ai_integration.md
    ├── 06a_auth_system.md
    ├── 06b_food_scanning.md
    ├── 06d_social_features.md
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
    ├── 13_ux_ui_spec.md
    ├── 14a_workouts.md
    ├── 14b_workout_tracking_analytics.md
    └── 14c_workout_map.md

Which of these files do you want to review? 


things to do: 


ideas
user journey after onboarding
- do a simple workout with two simple exercises (under 1 min)
- complete and add to plan (force adding to plan with message saying this can be removed later, have option to skip adding to plan disabled)
- Direct / take user to plan page to view exercise in the calander as done
- demonstrate workput extrapolation every day, week, month (custom) for how long?
- demonstrate workout intensity increase automation (is there a max reps/weight/sets)
- demonstrate

user should be asked how they want to do measuremens - height, body weight, exercise weight and this then sets the app for that (can be configured in edit profile section)