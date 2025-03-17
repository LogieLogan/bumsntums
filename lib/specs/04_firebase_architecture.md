# Firebase Architecture

## 4.1 Firestore Collections (Enhanced Schema with PII Separation)

```
# 1. Private PII Collection - Strict access controls, never exposed to AI
/users_personal_info/{userId}
  - displayName: string
  - email: string
  - photoUrl: string (optional)
  - createdAt: timestamp
  - lastLoginAt: timestamp
  - phoneNumber: string (optional)
  - dateOfBirth: timestamp (optional, replacing age)
  - address: object {
      line1: string
      line2: string
      city: string
      state: string
      postalCode: string
      country: string
  } (optional)
  - paymentInfo: {
      subscription: {
        status: string (free, premium)
        expiresAt: timestamp
        platform: string (apple, google)
        receiptId: string
        trialUsed: boolean
      }
  }
  - appSettings: {
      notifications: boolean
      privacyLevel: string (public, followers, private)
      units: string (metric, imperial)
      theme: string
      language: string
      healthKitEnabled: boolean
      googleFitEnabled: boolean
  }

# 2. User Fitness Data - De-identified data used for AI personalization
/fitness_profiles/{userId}
  - userId: string (reference but not PII)
  - createdAt: timestamp
  - heightCm: number (optional)
  - weightKg: number (optional)
  - ageRange: string (calculated from DOB in users_personal_info)
  - fitnessLevel: string (beginner, intermediate, advanced)
  - fitnessGoals: array (weight loss, toning, strength)
  - dietaryPreferences: array (keto, vegan, etc.)
  - allergies: array (optional)
  - bodyFocusAreas: array (bums, tums, arms, etc.)
  - weeklyActivityTarget: number (minutes)
  - onboardingCompleted: boolean
  - stats: {
      workoutsCompleted: number
      totalWorkoutMinutes: number
      streakDays: number
      caloriesBurned: number (estimated)
      lastWorkoutDate: timestamp
  }
  - healthConnections: {
      lastSyncDate: timestamp
      connectedServices: array (appleHealth, googleFit)
  }

# 3. Shareable User Content - Can be shown to other users
/user_profiles_public/{userId}
  - userId: string
  - username: string (not necessarily real name)
  - avatarUrl: string
  - bio: string (optional)
  - joinedDate: timestamp
  - fitnessLevel: string
  - featuredAchievements: array
  - badgeCount: number
  - workoutCount: number
  - followersCount: number
  - followingCount: number
  - isPrivate: boolean
  - lastActiveTimestamp: timestamp

/food_scans/{userId}/{scanId}
  - createdAt: timestamp
  - productId: string (barcode or unique identifier)
  - customName: string (optional)
  - nutritionInfo: {
      calories: number
      protein: number
      carbs: number
      fat: number
      sugar: number
      fiber: number
      sodium: number
  }
  - userNotes: string (optional)
  - personalized: {
      recommendedServing: number
      dietCompatibility: array (compatible, caution, avoid)
      alternatives: array (productIds)
  }
  - isOfflineCreated: boolean
  - syncStatus: string (synced, pending)

/food_diary/{userId}/{date}
  - date: timestamp
  - entries: array [
      {
        id: string
        scanId: string (optional)
        productName: string
        servingSize: number
        mealType: string (breakfast, lunch, dinner, snack)
        timeConsumed: timestamp
        nutritionInfo: {} (copied from scan or manual entry)
        isShared: boolean
      }
  ]
  - dailyTotals: {
      calories: number
      protein: number
      carbs: number
      fat: number
  }
  - userNotes: string
  - privacy: string (private, followers, public)
  - isOfflineCreated: boolean
  - syncStatus: string (synced, pending)

/workouts/{workoutId}
  - title: string
  - description: string
  - imageUrl: string
  - youtubeVideoId: string (optional)
  - category: string (bums, tums, full body, etc.)
  - difficulty: string (beginner, intermediate, advanced)
  - duration: number (minutes)
  - caloriesBurn: number (estimated)
  - featured: boolean
  - isAiGenerated: boolean
  - createdAt: timestamp
  - createdBy: string (admin, ai, userId)
  - exercises: array [
      {
        id: string
        name: string
        description: string
        imageUrl: string
        youtubeVideoId: string (optional)
        sets: number
        reps: number
        durationSeconds: number (optional, if timed)
        restBetweenSeconds: number
        targetArea: string (bums, tums, etc.)
      }
  ]
  - equipment: array (none, mat, dumbbells, etc.)
  - tags: array (quick, intense, recovery, etc.)
  - downloadsAvailable: boolean (for offline access)

/workout_logs/{userId}/{logId}
  - workoutId: string
  - startedAt: timestamp
  - completedAt: timestamp
  - duration: number (actual minutes)
  - caloriesBurned: number (calculated)
  - exercisesCompleted: array [
      {
        exerciseName: string
        setsCompleted: number
        repsCompleted: number
        difficulty: number (user rating 1-5)
      }
  ]
  - userFeedback: {
      rating: number (1-5)
      feltEasy: boolean
      feltTooHard: boolean
      comments: string
  }
  - isShared: boolean
  - privacy: string (private, followers, public)
  - isOfflineCreated: boolean
  - syncStatus: string (synced, pending)

/user_workout_favorites/{userId}/{workoutId}
  - addedAt: timestamp

# 4. Social Interactions
/social/following/{userId}/{followedUserId}
  - followedAt: timestamp

/social/followers/{userId}/{followerUserId}
  - followedAt: timestamp

/posts/{postId}
  - userId: string
  - createdAt: timestamp
  - type: string (workout, progress, food, general)
  - content: string
  - imageUrls: array
  - youtubeVideoId: string (optional)
  - tags: array (workout names, challenge names)
  - privacy: string (public, followers, private)
  - workoutRef: string (optional)
  - challengeRef: string (optional)
  - location: geopoint (optional)
  - metrics: {
      viewCount: number
      likeCount: number
      commentCount: number
      shareCount: number
  }

/post_interactions/{postId}/likes/{userId}
  - timestamp: timestamp

/post_interactions/{postId}/comments/{commentId}
  - userId: string
  - content: string
  - createdAt: timestamp
  - likeCount: number
  - isEdited: boolean

/challenges/{challengeId}
  - title: string
  - description: string
  - imageUrl: string
  - startDate: timestamp
  - endDate: timestamp
  - type: string (workout streak, calorie goal, etc.)
  - target: number (days, workouts, etc.)
  - rewards: {
      points: number
      badge: string
      premiumDays: number (if applicable)
  }
  - createdBy: string (admin, ai)
  - isActive: boolean

/challenge_participants/{challengeId}/{userId}
  - joinedAt: timestamp
  - progress: number
  - completed: boolean
  - completedAt: timestamp (optional)
  - awardedRewards: boolean

# 5. Notifications and User Activity
/notifications/{userId}/{notificationId}
  - createdAt: timestamp
  - read: boolean
  - type: string (workout, challenge, social, system)
  - title: string
  - body: string
  - actionType: string (open workout, view challenge, etc.)
  - referenceId: string (workoutId, challengeId, etc.)
  - senderUserId: string (optional, for social notifications)

# 6. Offline Support and Sync
/sync_queue/{userId}/{operationId}
  - createdAt: timestamp
  - operationType: string (create, update, delete)
  - collectionPath: string
  - documentId: string
  - data: map
  - attempts: number
  - lastAttempt: timestamp
  - status: string (pending, processing, completed, failed)
  - errorMessage: string (optional)

/user_achievements/{userId}/{achievementId}
  - achievementId: string
  - currentProgress: number
  - targetValue: number
  - isCompleted: boolean
  - completedAt: timestamp (optional)
  - isViewed: boolean

/user_streaks/{userId}
  - currentStreak: number
  - longestStreak: number
  - lastWorkoutDate: timestamp
  - streakProtectionsRemaining: number
  - streakProtectionLastRenewed: timestamp

  /user_accessibility_preferences/{userId}
  - useHighContrast: boolean
  - reduceMotion: boolean
  - useExerciseModifications: boolean
  - textSize: string (standard, large, extraLarge)
  - accessibilityNeeds: array

/exercise_modifications/{exerciseId}/{modificationId}
  - modificationDescription: string
  - modificationImageUrl: string (optional)
  - modificationVideoUrl: string (optional)
  - forNeeds: array

# Personalization Collections
/user_preferences/{userId}
  - workoutPreferences: {
      preferredDuration: number
      preferredIntensity: string
      favoriteCategories: array
      quickStartWorkouts: array (recently used)
    }
  - uiPreferences: {
      showCelebrations: boolean
      enableHapticFeedback: boolean
      enableVoiceGuidance: boolean
      dashboardLayout: string
    }
  - accessibility: {
      useHighContrast: boolean
      reduceMotion: boolean
      useExerciseModifications: boolean
      textSize: string
      accessibilityNeeds: array
    }
```

## 4.2 Firebase Storage Structure
```
/user_assets/{userId}/profile/{filename}
/user_assets/{userId}/posts/{postId}/{filename}
/workout_assets/images/{workoutId}/{filename}
/workout_assets/thumbnails/{workoutId}/{filename} # YouTube video thumbnails
/exercise_assets/images/{exerciseId}/{filename}
/exercise_assets/thumbnails/{exerciseId}/{filename} # YouTube video thumbnails
/challenge_assets/{challengeId}/{filename}
/offline_assets/{userId}/{assetId} # Cached assets for offline use
```

## 4.3 Security Rules Approach

match /users_personal_info/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

match /fitness_profiles/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null && request.auth.uid == userId;
  
  // Admin access for AI service accounts
  allow read: if request.auth != null && request.auth.token.admin == true;
}

match /user_profiles_public/{userId} {
  // Anyone can read public profiles
  allow read: if true;
  
  // Only the owner can write to their public profile
  allow write: if request.auth != null && request.auth.uid == userId;
}

match /posts/{postId} {
  // Public posts can be read by anyone
  allow read: if resource.data.privacy == 'public';
  
  // Follower-only posts can be read by followers
  allow read: if resource.data.privacy == 'followers' && 
    exists(/databases/$(database)/documents/social/followers/$(resource.data.userId)/$(request.auth.uid));
  
  // Private posts can only be read by the owner
  allow read: if request.auth != null && resource.data.userId == request.auth.uid;
  
  // Only the owner can write to their posts
  allow write: if request.auth != null && request.auth.uid == resource.data.userId;
}

match /sync_queue/{userId}/{operationId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

## 4.4 Firebase Cloud Functions

### Authentication Functions
- `onUserCreate`: Initializes user documents across collections
- `onUserDelete`: Handles data cleanup and anonymization

### Profile Management
- `syncPublicProfile`: Keeps public profile in sync with fitness profile (non-PII fields only)
- `calculateAgeRange`: Updates the ageRange field in fitness_profiles based on dateOfBirth from users_personal_info

### Fitness Data Functions
- `processWorkoutCompletion`: Updates user stats, generates recommendations
- `generatePersonalizedWorkout`: Creates AI workouts based on fitness profile
- `weeklyProgressReport`: Generates insights from workout and nutrition data

### Health Integration Functions
- `syncAppleHealthData`: Integrates data from Apple Health
- `syncGoogleFitData`: Integrates data from Google Fit
- `processHealthImportedData`: Normalizes and stores data from third-party health services

### Social Functions
- `handleFollow`: Updates follower/following collections and sends notifications
- `processNewPost`: Handles share notifications and metrics updates
- `calculatePostEngagement`: Updates engagement metrics

### Nutrition Functions
- `processScannedFood`: Enhances nutrition data from barcodes or images
- `analyzeNutritionTrends`: Provides insights on dietary habits

### Offline Sync
- `processSyncQueue`: Handles operations queued during offline usage
- `generateOfflineAssetCache`: Prepares assets for offline access
- `cleanupOldOfflineData`: Removes outdated offline cached data

### Privacy and Compliance
- `exportUserData`: Creates GDPR-compliant export of user data
- `anonymizeAccount`: Handles data anonymization for account deletion

## 4.5 Offline Support Strategy

The app implements a comprehensive offline strategy:

1. **Local Database**: Utilizes SQLite or Hive for local storage of:
   - Active workout programs
   - Recently viewed workouts
   - User's own workout logs
   - Current day's food diary
   - Essential user profile information

2. **Sync Queue**:
   - Operations performed while offline are stored in a local queue
   - When connectivity resumes, operations are synchronized with Firestore
   - The `/sync_queue/{userId}/{operationId}` collection tracks sync status

3. **Asset Caching**:
   - Essential images and workout descriptions are cached for offline viewing
   - YouTube video thumbnails are cached, with a note that videos require connectivity
   - Workout instructions are fully available offline

4. **Progressive Data Loading**:
   - App prioritizes loading critical functionality first
   - Background sync processes handle non-essential data when connectivity allows

5. **Conflict Resolution**:
   - Timestamp-based conflict resolution for simultaneous online/offline edits
   - Server timestamps are used as the source of truth
   - Users are notified of conflicts that require manual resolution