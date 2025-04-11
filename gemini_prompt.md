system prompt

provde whole complete chnages of methods if they are new methods provide the entire new method. 
dont over use comments. use them only when absolutely nessesery for example at the top of file where it says the fils location.
if code is the same dont output it, unless you are doing the entire method with updates then provide the current and updated code ads a sinlge complete method
avoid usig code... //(*....*) bits when keeping the code the same. instead just dont output this aprt of the code.
If the code change is small then provide a targeted chnage to that part only, when providing target code chnages show what is chngaging and what it is chnaging to.
Any code you procide must be ready to copy. no + or - signs or sytactically wrong characters

Overview
# Bums & Tums - Project Overview

## Project Summary
**Project Name:** Bums & Tums  
**Platform:** Flutter (iOS first, Android later)  
**Backend:** Firebase (Firestore, Authentication, Cloud Functions, Firebase ML Kit, Storage)  
**AI Integration:** OpenAI API (OpenAI-mini for cost efficiency)
**Monetization:** Apple In-App Purchases  
**Target Audience:** Beginner women focused on weight loss and toning

## Vision
Bums & Tums is a fitness application designed specifically for beginner women who want to focus on weight loss and toning. The app provides personalized workout recommendations, food scanning and nutritional analysis, and a supportive community to help users achieve their fitness goals.

## Core Technologies
- **Flutter**: Cross-platform development framework
- **Firebase**: Backend services including authentication, database, and storage
- **OpenAI API**: AI-powered workout recommendations and personalized advice
- **Firebase ML Kit**: Food label and barcode scanning
- **Riverpod**: State management solution

## Key Features
- Personalized workout recommendations focused on "Bums & Tums"
- Food scanning with nutritional analysis
- Progress tracking
- Social community and challenges
- AI-powered fitness advice

## Document Index
- [01_user_journeys.md](01_user_journeys.md) - User experience flows and journeys
- [02_design_system.md](02_design_system.md) - Design guidelines and UI components
- [03_technical_architecture.md](03_technical_architecture.md) - Project structure and patterns
- [04_firebase_architecture.md](04_firebase_architecture.md) - Database schema and cloud functions
- [05_ai_integration.md](05_ai_integration.md) - OpenAI implementation details
- [06a_auth_system.md](06a_auth_system.md) - Authentication system
- [06b_food_scanning.md](06b_food_scanning.md) - Food scanning and nutrition tracking
- [06c_workouts.md](06c_workouts.md) - Workout features
- [06d_social_features.md](06d_social_features.md) - Social and community features
- [06e_challenges.md](06e_challenges.md) - Challenges system
- [06f_in_app_purchases.md](06f_in_app_purchases.md) - Subscription model
- [07_analytics_and_monitoring.md](07_analytics_and_monitoring.md) - Analytics and crash reporting
- [08_security_and_compliance.md](08_security_and_compliance.md) - Security measures and data privacy
- [09_implementation_plan.md](09_implementation_plan.md) - Development timeline and phases
- [10_early_feedback.md](10_early_feedback.md) - User testing and feedback mechanisms

Focus area (steps after thought steps): 
log workout on weekly planning screen saves workout to the day logged and updates analytics accordingly


Thought Steps to follow:
1. Review project files surrounding the focus area, trying to get a understanding of how the app works in this specific sphere of the app.
2. Ask questions based on reviewed files and request next tranch of files for review wit the goal of understanding the focus area
3. build up project/app map of intergrations, features, methods on focus area
4. Ask more questions if needed (itterate until understood)
5. Remaining focused on focus area review the current codes implementation and review if ready to take new feature.
6. Once knowledge sphere is properly understood move to focus area


This Current project structure file names (these files have been created so far and you should review them as needed)

├── app.dart
├── features
│   ├── ai
│   │   ├── models
│   │   │   ├── ai_context.dart
│   │   │   ├── conversation.dart
│   │   │   ├── message.dart
│   │   │   ├── personality_settings.dart
│   │   │   └── prompt_template.dart
│   │   ├── providers
│   │   │   ├── ai_chat_provider.dart
│   │   │   ├── ai_service_provider.dart
│   │   │   └── openai_provider.dart
│   │   ├── screens
│   │   │   └── ai_chat_screen.dart
│   │   └── services
│   │       ├── context_service.dart
│   │       ├── conversation_manager.dart
│   │       ├── openai_service.dart
│   │       ├── personality_engine.dart
│   │       └── prompt_engine.dart
│   ├── ai_workout_creation
│   │   ├── models
│   │   │   └── creation_step.dart
│   │   ├── provider
│   │   │   └── workout_generation_provider.dart
│   │   ├── screens
│   │   │   └── ai_workout_screen.dart
│   │   └── widgets
│   │       ├── category_selection_step.dart
│   │       ├── custom_request_step.dart
│   │       ├── duration_selection_step.dart
│   │       ├── equipment_selection_step.dart
│   │       ├── generating_step.dart
│   │       ├── parameter_summary_sheet.dart
│   │       ├── refinement_result.dart
│   │       ├── refinement_step.dart
│   │       ├── welcome_step.dart
│   │       └── workout_result.dart
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
│   ├── workout_analytics
│   │   ├── data
│   │   │   └── achievement_definitions.dart
│   │   ├── models
│   │   │   ├── workout_achievement.dart
│   │   │   ├── workout_analytics_filters.dart
│   │   │   ├── workout_analytics_timeframe.dart
│   │   │   └── workout_stats.dart
│   │   ├── providers
│   │   │   ├── achievement_provider.dart
│   │   │   ├── workout_insights_provider.dart
│   │   │   └── workout_stats_provider.dart
│   │   ├── screens
│   │   │   ├── achievements_screen.dart
│   │   │   └── workout_analytics_screen.dart
│   │   ├── services
│   │   │   └── workout_stats_service.dart
│   │   └── widgets
│   │       ├── achievement_tile.dart
│   │       ├── achievements_summary_card.dart
│   │       ├── analytics_chart_card.dart
│   │       ├── analytics_stat_card.dart
│   │       ├── body_focus_chart.dart
│   │       ├── period_selector.dart
│   │       ├── personal_records_section.dart
│   │       ├── unit_preference_toggle.dart
│   │       ├── workout_calendar_heatmap.dart
│   │       └── workout_progress_chart.dart
│   ├── workout_planning
│   │   ├── index.dart
│   │   ├── models
│   │   │   ├── planner_item.dart
│   │   │   ├── scheduled_workout.dart
│   │   │   └── workout_plan.dart
│   │   ├── providers
│   │   │   └── workout_planning_provider.dart
│   │   ├── repositories
│   │   │   └── workout_planning_repository.dart
│   │   ├── screens
│   │   │   ├── weekly_planning_screen.dart
│   │   │   └── workout_scheduling_screen.dart
│   │   └── widgets
│   │       ├── day_schedule_card.dart
│   │       ├── logged_workout_item_widget.dart
│   │       ├── scheduled_workout_item.dart
│   │       └── workout_day_header.dart
│   └── workouts
│       ├── data
│       │   ├── exercise_repository.dart
│       │   ├── local_exercise_repository.dart
│       │   └── sources
│       │       ├── exercise_data_source.dart
│       │       └── json_exercise_data_source.dart
│       ├── models
│       │   ├── exercise.dart
│       │   ├── workout.dart
│       │   ├── workout_category_extensions.dart
│       │   ├── workout_log.dart
│       │   ├── workout_section.dart
│       │   └── workout_streak.dart
│       ├── providers
│       │   ├── exercise_providers.dart
│       │   ├── exercise_selector_provider.dart
│       │   ├── workout_editor_provider.dart
│       │   ├── workout_execution_provider.dart
│       │   └── workout_provider.dart
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
│       │   ├── workout_browse_screen.dart
│       │   ├── workout_completion_screen.dart
│       │   ├── workout_detail_screen.dart
│       │   ├── workout_editor_screen.dart
│       │   ├── workout_execution_screen.dart
│       │   ├── workout_history_screen.dart
│       │   ├── workout_search_screen.dart
│       │   └── workout_templates_screen.dart
│       ├── services
│       │   ├── exercise_db_service.dart
│       │   ├── exercise_service.dart
│       │   ├── voice_guidance_service.dart
│       │   ├── workout_execution_helper_service.dart
│       │   └── workout_service.dart
│       └── widgets
│           ├── category_card.dart
│           ├── editor
│           │   ├── equipment_and_tags_section.dart
│           │   ├── section_card.dart
│           │   └── workout_basic_info_form.dart
│           ├── execution
│           │   ├── between_sets_screen.dart
│           │   ├── between_sets_timer.dart
│           │   ├── exercise_completion_animation.dart
│           │   ├── exercise_content_widget.dart
│           │   ├── exercise_info_sheet.dart
│           │   ├── exercise_settings_modal.dart
│           │   ├── exercise_timer.dart
│           │   ├── exit_confirmation_dialog.dart
│           │   ├── rep_based_exercise_content.dart
│           │   ├── rest_period_widget.dart
│           │   ├── rest_timer.dart
│           │   ├── workout_bottom_controls.dart
│           │   ├── workout_progress_indicator.dart
│           │   └── workout_top_bar.dart
│           ├── exercise_demo_widget.dart
│           ├── exercise_filter_bar.dart
│           ├── exercise_image_widget.dart
│           ├── exercise_list_item.dart
│           ├── exercise_type_tag.dart
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
│   │   ├── crash_reporting_provider.dart
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
│   │   ├── shake_detector_service.dart
│   │   └── unit_conversion_service.dart
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
    ├── 14b_workout_analytics.md
    ├── 14b_workout_planning.md
    └── 14c_workout_map.md

Which of these files do you want to review? 


Starting files: 
