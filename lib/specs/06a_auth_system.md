# Authentication System

## Overview
The authentication system will provide secure user registration and login functionality, with multiple sign-in options and a robust profile setup process.

## Sign-up and Login Options
- Email/password authentication
- Google Sign-In
- Apple Sign-In (required for iOS apps with social login)
- Anonymous login with option to convert to full account later

## User Profile Management
- Personal information stored securely in `/users_personal_info/{userId}`
- Non-PII fitness data stored separately in `/fitness_profiles/{userId}`
- Profile photo upload and management
- Account linking capabilities (merge anonymous account with permanent account)

## Authentication Flow
1. User selects authentication method
2. After successful authentication:
   - For new users: Redirect to onboarding flow
   - For returning users: Retrieve user data and restore state
3. Set up user presence monitoring for online status

## Security Features
- Email verification
- Password reset functionality
- Session management
- Account recovery options
- Secure logout across devices

## Profile Setup Process (this should be fun and engaging)
1. Basic information collection (name, email)
2. Age, height, weight collection
3. Fitness goals selection (highlight the apps niece Bums or Tums ... or both ) (fun)
4. Dietary preferences and restrictions 
5. Body focus area targeting
6. Fitness level assessment

## Implementation Details
- Use Firebase Authentication SDK
- Implement custom user provider with Riverpod
- Create dedicated auth state stream
- Implement secure token storage
- Set up proper error handling and user feedback