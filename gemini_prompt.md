## Vision
Bums & Tums is a fitness application designed specifically for beginner women who want to focus on weight loss and toning. The app provides personalized workout recommendations, food scanning and nutritional analysis, and a supportive community to help users achieve their fitness goals.

## Core Technologies
- **Flutter**: Cross-platform development framework
- **Firebase**: Backend services including authentication, database, and storage
- **OpenAI API**: AI-powered workout recommendations and personalized advice
- **Firebase ML Kit**: Food label and barcode scanning
- **Riverpod**: State management solution

FOCUS AREA:
Using the current project sturcture and implementation plan get to know the app code base by requesting files.
Once you have what you need to provide exceptional app development support specifically for THIS app please then please report back your findings ONLY when you have an indepth hollisting understanding

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
│   │   │   └── ai_service_provider.dart
│   │   ├── screens
│   │   │   ├── ai_chat_screen.dart
│   │   │   └── chat_sessions_list_screen.dart
│   │   └── services
│   │       ├── ai_service.dart
│   │       ├── chat_session_service.dart
│   │       ├── firebase_vertexai_service.dart
│   │       └── personality_engine.dart
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
│       │   ├── workout_log_detail_screen.dart
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
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
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
    └── 14c_workout_map.md

here is the implementation plan to date 

# Implementation Plan

## 9.1 Phased Approach

### Phase 1: MVP Foundation (Weeks 1-5)
- Core app architecture setup
- Authentication and user profile
- Basic workout library
- Food scanning (barcode only)
- Firebase analytics integration
- Set up FlutterFire CLI and Firebase configuration
- Implement basic Riverpod state management structure
- Set up early feedback mechanisms

**To-Do List:**
- [x] Set up project with latest stable Flutter version
- [x] Initialize Firebase with FlutterFire CLI
- [x] Set up project structure following the architecture plan
- [x] Create base theme and design system components
- [x] Implement authentication flows
- [x] Set up Riverpod providers and state management
- [x] Implement basic profile creation
- [x] Create workout data models and repositories
- [x] Set up analytics tracking with Firebase
- [x] Implement crash reporting with Crashlytics
- [x] Create barcode scanning MVP with Open Food Facts API
- [x] Implement basic workout display and execution
- [x] Complete data privacy impact assessment
- [x] Create feedback collection tools and processes

### Phase 2: Core Features (Weeks 6-10)
- OCR implementation for nutrition labels
- Basic AI workout recommendations
- User progress tracking
- Improved UI/UX refinement
- Define OpenAI prompt templates
- Implement cost optimization for AI features
- accessibility
- Profile page

**To-Do List:**
- [ ] Implement OCR for nutrition labels
- [ ] Set up OpenAI service token limits and caching
- [x] Create and test prompt templates for workout recommendations
- [x] Add progress tracking features
- [ ] Implement conversion funnels in analytics
- [ ] Build food diary and nutrition tracking
- [x] Enhance workout execution experience
- [x] Implement GDPR/CCPA data handling compliance
- [x] Create data export and deletion functionality
- [ ] Implement accessibility features
- [ ] Polish up app bar on all tabs. curently all have the same chat fucntion but each screen should have their own. i.e. home chat, workout screen action button with drop downs for my templates, my workouts. Aslo the app bar always says bums and tums when it shoudl only say this on the home tab and then on wrkouts its hould be wrokout and scna scna and weekly plan
- [ ] weekly pan screen shouldnt need to be tab view and should just be weekly plan screen as the app bar title and then the res tof the screent he weekly plan view. again an action bar here instead of chat with relevant actions for this screen. 
- [x] Implement profile page features
- [ ] Set up TestFlight/Firebase App Distribution for testing
      - dev and prod app icons (appicon is done using flutter_launcher_icons )
      - review lauch screen I have a splsh screen but in xcode the lauch screen is blank

### Phase 3: Social & Advanced Features (Weeks 11-14)
- Social features implementation
- Gamification
- Challenge system
- Subscription implementation
- Advanced AI personalization
- Extended workout library
- Create your own workout feature. AI or manual
- Cross-platform testing
- Optimize AI costs and usage
- Account verification / anti platform abuse measures


**To-Do List:**
- [ ] Implement user profile and social features
- [ ] Create post creation and interaction system
- [ ] Build challenge creation and participation features
- [ ] Expand workout library with more content
- [ ] Enhance AI personalization based on user feedback
- [ ] Implement accessibility features and testing
- [ ] Conduct cross-platform testing
- [ ] Optimize performance for lower-end devices
- [ ] Create moderation system for social content
- [ ] Refine analytics and tracking
- [ ] Implement gamification features
- [ ] Set up in-app purchase with free trial option
- [ ] Create subscription management system

### Phase 4: Polishing & Launch Preparation (Weeks 15-18)
- Performance optimization
- Bug fixing and UX improvements
- Final security audits
- App Store submission preparation
- Marketing materials preparation
- Accessibility improvements
- User feedback incorporation

**To-Do List:**
- [ ] Conduct thorough performance optimization
- [ ] Run security audit and address findings
- [ ] Implement final UI/UX refinements
- [ ] Complete comprehensive accessibility testing
- [ ] Analyze beta testing feedback and prioritize final changes
- [ ] Review and finalize data retention policies
- [ ] Conduct final data privacy compliance check
- [ ] Prepare App Store assets and description
- [ ] Create marketing materials and screenshots
- [ ] Set up open beta testing program
- [ ] Prepare rollout strategy and timeline
- [ ] Create post-launch monitoring dashboard
- [ ] Document codebase and architecture
- [ ] Create system for ongoing user feedback collection

## 9.2 Testing Strategy

### Unit Testing
- Provider/State Management tests
- Service layer tests
- Utility function tests
- Mock API response handling

### Widget Testing
- Component rendering tests
- Interactive element testing
- Screen navigation tests
- Theme and style conformity

### Integration Testing
- End-to-end feature flows
- Firebase integration tests
- API communication tests
- Device permission handling

### Accessibility Testing
- Screen reader compatibility
- Contrast ratio checks
- Touch target size verification
- Keyboard navigation support
- Color blindness simulation tests

## 9.3 CI/CD Pipeline
- GitHub Actions for automated builds
- Test automation on PR creation
- Firebase Test Lab integration
- Automated versioning

## 9.4 Post-Launch Strategy

### Monitoring & Support
- Real-time analytics monitoring
- User feedback collection
- Crash reporting triage
- Regular maintenance updates

### Feature Expansion
- Community feature enhancements
- Additional workout categories
- Enhanced AI capabilities
- Partner integrations (fitness trackers, etc.)
- Android platform expansion

Do you understand the app, your role, the next steps and how we are meant to get there? 

