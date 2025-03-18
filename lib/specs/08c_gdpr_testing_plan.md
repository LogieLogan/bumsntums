# GDPR Functionality Testing Plan

## 1. Data Export Testing

### Test Case 1.1: Basic Export Functionality
- **Description**: Test that a user can export their data
- **Steps**:
  1. Log in as a test user
  2. Navigate to Profile → Privacy & Data Settings
  3. Click "Export My Data"
  4. Verify the share dialog appears with a JSON file
- **Expected Result**: A JSON file containing all user data is created and shared

### Test Case 1.2: Export Content Verification
- **Description**: Verify that the exported data contains all required information
- **Steps**:
  1. Export data as in Test Case 1.1
  2. Open the JSON file and verify it contains:
     - Personal information
     - Fitness profile data
     - Food scans
     - Workout logs
     - Other relevant user data
- **Expected Result**: The JSON file contains complete user data in a readable format

## 2. Data Deletion Testing

### Test Case 2.1: Account Deletion Process
- **Description**: Test that a user can delete their account
- **Steps**:
  1. Log in as a test user
  2. Navigate to Profile → Privacy & Data Settings
  3. Click "Delete My Account"
  4. Confirm deletion in the dialog
  5. Verify redirect to login screen
- **Expected Result**: User is logged out and redirected to login screen

### Test Case 2.2: Data Deletion Verification
- **Description**: Verify that user data is properly deleted from the database
- **Steps**:
  1. Set up a test user with data in all collections
  2. Perform account deletion as in Test Case 2.1
  3. Using Firebase Console, check all collections for any remaining user data
- **Expected Result**: No user data remains in any collection

### Test Case 2.3: Auth Account Deletion
- **Description**: Verify that the Firebase Auth account is properly deleted
- **Steps**:
  1. Delete account as in Test Case 2.1
  2. Attempt to log in with the deleted account credentials
- **Expected Result**: Login attempt fails because the account no longer exists

## 3. Data Retention Testing

### Test Case 3.1: Data Retention Policy Implementation
- **Description**: Verify that old data is automatically cleaned up according to retention policies
- **Steps**:
  1. Set up test data with timestamps older than retention periods
  2. Trigger the data retention service
  3. Check that old data has been deleted
- **Expected Result**: Only data within retention periods remains

## 4. Consent Management Testing

### Test Case 4.1: Initial Consent Collection
- **Description**: Verify that consent is properly collected during onboarding
- **Steps**:
  1. Create a new account
  2. Go through the onboarding process
  3. Verify consent options are presented
  4. Accept some options and decline others
  5. Complete onboarding
  6. Check the user_consents collection for correct values
- **Expected Result**: Consent options are saved correctly in the database

### Test Case 4.2: Consent Update
- **Description**: Verify that users can update their consent options
- **Steps**:
  1. Log in as a test user
  2. Navigate to consent settings
  3. Change consent options
  4. Verify changes are saved
- **Expected Result**: Updated consent options are saved correctly