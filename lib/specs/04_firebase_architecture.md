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

# Exercise Database
/exercises/{exerciseId}
  - id: string
  - name: string
  - description: string
  - instructions: string
  - imageUrl: string
  - videoUrl: string (optional)
  - targetAreas: array (bums, tums, arms, etc.)
  - equipment: array (none, mat, dumbbells, etc.)
  - difficultyLevel: string (beginner, intermediate, advanced)
  - recommendedReps: number
  - recommendedSets: number
  - durationSeconds: number (for timed exercises)
  - restBetweenSets: number (seconds)
  - formTips: array (guidance for proper form)
  - commonMistakes: array (things to avoid)
  - createdAt: timestamp
  - createdBy: string (admin, system)
  - isActive: boolean
  - tags: array

/exercise_modifications/{exerciseId}/{modificationId}
  - id: string
  - exerciseId: string
  - title: string
  - description: string
  - imageUrl: string (optional)
  - videoUrl: string (optional)
  - forAccessibilityNeeds: array
  - difficultyAdjustment: string (easier, harder)
  - equipmentAlternative: string (optional)
  - createdAt: timestamp

# Workout Collections
/workouts/{workoutId}
  - id: string
  - title: string
  - description: string
  - imageUrl: string
  - youtubeVideoId: string (optional)
  - category: string (bums, tums, full body, etc.)
  - difficulty: string (beginner, intermediate, advanced)
  - durationMinutes: number
  - estimatedCaloriesBurn: number
  - featured: boolean
  - isAiGenerated: boolean
  - isUserCreated: boolean
  - originalWorkoutId: string (if this is a modification of another workout)
  - createdAt: timestamp
  - createdBy: string (admin, ai, userId)
  - updatedAt: timestamp
  - updatedBy: string (admin, ai, userId)
  - exercises: array [
      {
        id: string
        exerciseId: string (reference to exercises collection)
        name: string
        description: string
        imageUrl: string
        videoUrl: string (optional)
        sets: number
        reps: number
        durationSeconds: number (optional, if timed)
        restBetweenSeconds: number
        targetArea: string (bums, tums, etc.)
        order: number (position in workout)
        modifications: array (of modification IDs)
      }
  ]
  - warmup: array (optional warmup exercises)
  - cooldown: array (optional cooldown exercises)
  - equipment: array (none, mat, dumbbells, etc.)
  - tags: array (quick, intense, recovery, etc.)
  - downloadsAvailable: boolean (for offline access)
  - hasAccessibilityOptions: boolean
  - intensityModifications: array (options to modify intensity)
  - viewCount: number
  - completionCount: number
  - averageRating: number
  - reviewCount: number

# User Workout Interactions
/user_workout_favorites/{userId}/{workoutId}
  - addedAt: timestamp

/user_workout_history/{userId}/{entryId}
  - workoutId: string
  - title: string (denormalized for offline access)
  - category: string
  - completedAt: timestamp
  - startedAt: timestamp
  - durationMinutes: number (actual time taken)
  - caloriesBurned: number (estimated)
  - difficulty: string
  - isCompleted: boolean

/workout_logs/{userId}/{logId}
  - workoutId: string
  - startedAt: timestamp
  - completedAt: timestamp
  - duration: number (actual minutes)
  - caloriesBurned: number (calculated)
  - exercisesCompleted: array [
      {
        exerciseId: string
        exerciseName: string
        setsCompleted: number
        repsCompleted: number
        weightUsed: number (optional)
        difficultyRating: number (user rating 1-5)
        notes: string (optional)
      }
  ]
  - userFeedback: {
      rating: number (1-5)
      feltEasy: boolean
      feltTooHard: boolean
      comments: string
      energyLevel: number (1-5)
      muscleGroups: array (areas that felt worked)
      wouldDoAgain: boolean
  }
  - location: string (home, gym, etc.)
  - timeOfDay: string (morning, afternoon, evening)
  - isShared: boolean
  - privacy: string (private, followers, public)
  - isOfflineCreated: boolean
  - syncStatus: string (synced, pending)
  - analyticsData: {
      totalActiveSeconds: number
      totalRestSeconds: number
      averageHeartRate: number (if available)
      peakHeartRate: number (if available)
      caloriesSource: string (estimated, device)
  }

# Custom Workouts
/user_custom_workouts/{userId}/{workoutId}
  - (Same fields as /workouts collection)
  - isTemplate: boolean (if this is saved as a template)
  - isPublic: boolean (if shared with community)
  - parentWorkoutId: string (if based on existing workout)
  - lastUsed: timestamp

# Workout Planning & Scheduling
/workout_plans/{userId}/{planId}
  - name: string
  - description: string
  - startDate: timestamp
  - endDate: timestamp (optional)
  - createdAt: timestamp
  - isActive: boolean
  - goal: string
  - scheduledWorkouts: array [
      {
        workoutId: string
        title: string (denormalized)
        scheduledDate: timestamp
        isCompleted: boolean
        completedAt: timestamp (optional)
        isRecurring: boolean
        recurrencePattern: string (daily, weekly, etc.)
        recurrenceEndDate: timestamp (optional)
        reminderTime: timestamp
        reminderEnabled: boolean
      }
  ]

/workout_reminders/{userId}/{reminderId}
  - workoutId: string
  - workoutTitle: string
  - scheduledDate: timestamp
  - reminderTime: timestamp
  - message: string
  - isRead: boolean
  - isCustomMessage: boolean
  - deliveryStatus: string (pending, sent, failed)

# Workout Feedback & Analytics
/workout_feedback/{feedbackId}
  - userId: string (anonymized)
  - workoutId: string
  - isAiGenerated: boolean
  - timestamp: timestamp
  - completionPercentage: number (0-100)
  
  // Core feedback metrics (1-5 scale)
  - difficultyRating: {
      value: number (1=Too Easy, 3=Just Right, 5=Too Hard)
      comment: string (optional)
    }
  - enjoymentRating: {
      value: number (1-5)
      comment: string (optional)
    }
  - personalizationRating: {
      value: number (1-5)
      comment: string (optional)
    }
  
  // Workout-specific metrics
  - intensityBySegment: {
      warmup: number (1-5)
      main: number (1-5)
      cooldown: number (1-5)
    }
  - exerciseFeedback: [
      {
        exerciseId: string
        name: string
        difficultyRating: number (1-5)
        enjoymentRating: number (1-5)
        formConfidence: number (1-5)
        comment: string (optional)
      }
    ]
  
  // Physical response metrics
  - physicalResponse: {
      sweatLevel: number (1-5)
      muscleFailure: boolean
      painPoints: array (e.g., ["knees", "lower back"])
      energyAfter: number (1-5, 1=depleted, 5=energized)
    }
  
  // Context information
  - userContext: {
      fitnessLevel: string
      bodyFocusAreas: array
      goals: array
      equipmentUsed: array
      location: string
      timeOfDay: string
    }
  
  // Follow-up intentions
  - userIntentions: {
      willRepeat: boolean
      willModify: boolean
      recommendationLikelihood: number (1-5)
    }

/workout_aggregate_feedback/{workoutId}
  - id: string
  - workoutId: string
  - isAiGenerated: boolean
  - feedbackCount: number
  - averageRatings: {
      difficulty: number
      enjoyment: number
      personalization: number
      intensity: number
    }
  - difficultyDistribution: {
      tooEasy: number (percentage)
      justRight: number (percentage)
      tooHard: number (percentage)
    }
  - completionRate: number (percentage)
  - popularityScore: number
  - targetAudience: {
      fitnessLevels: array
      primaryGoals: array
      idealEquipment: array
    }
  - mostChallenging: array (exercise names)
  - mostEnjoyed: array (exercise names)
  - leastEnjoyed: array (exercise names)
  - updatedAt: timestamp

/exercise_feedback/{exerciseId}
  - id: string
  - exerciseName: string
  - feedbackCount: number
  - averageRatings: {
      difficulty: number
      enjoyment: number
      formConfidence: number
    }
  - difficultyByFitnessLevel: {
      beginner: number
      intermediate: number 
      advanced: number
    }
  - commonPainPoints: array
  - substitutionPreferences: array
  - updatedAt: timestamp

# User Analytics
/user_workout_analytics/{userId}
  - totalWorkoutsCompleted: number
  - totalWorkoutMinutes: number
  - workoutsByCategory: {
      bums: number
      tums: number
      fullBody: number
      cardio: number
      // etc.
    }
  - workoutsByDifficulty: {
      beginner: number
      intermediate: number
      advanced: number
    }
  - workoutsByDayOfWeek: array [number] (index 0 = Sunday)
  - workoutsByTimeOfDay: {
      morning: number
      afternoon: number
      evening: number
    }
  - averageWorkoutDuration: number
  - longestStreak: number
  - currentStreak: number
  - caloriesBurned: number
  - lastUpdated: timestamp
  - weeklyAverage: number
  - monthlyTrend: array
  - completionRate: number (percentage of started workouts that were completed)
  - favoriteWorkouts: array (top 5 workoutIds by usage)
  - favoriteExercises: array (top 5 exerciseIds by usage)

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
/workout_assets/thumbnails/{workoutId}/{filename}
/exercise_assets/images/{exerciseId}/{filename}
/exercise_assets/videos/{exerciseId}/{filename}
/exercise_assets/modifications/{exerciseId}/{modificationId}/{filename}
/user_workout_assets/{userId}/{workoutId}/{filename} // For user-created workouts
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

Workout Execution Offline Strategy

Pre-download Selected Workouts

Allow users to download favorite workouts
Store complete workout data in local database
Cache all exercise images and descriptions
Prioritize critical execution assets


Offline Workout Execution

Full support for starting and completing workouts offline
Store workout logs in local database
Queue completed workout data for sync when online
Maintain all workout interactions offline


Seamless Sync

Background sync of completed workouts when connectivity returns
Conflict resolution for simultaneously edited custom workouts
Progress preservation even if app is closed during offline period
Prioritize sync of workout completion data over other interactions



Workout Planning Offline Strategy

Local Calendar Storage

Store workout schedule in local database
Allow modification of future workout plans offline
Maintain notifications functionality offline


Reminder Handling

Manage workout reminders locally
Ensure notifications work without connectivity
Queue notification interaction data for later sync



Custom Workout Creation Offline Support

Local Exercise Library Cache

Store frequently used exercises for offline access
Allow creation of custom workouts offline
Support editing of user-created workouts without connectivity


Asset Management

Optimize storage use with limited offline assets
Clear strategy for asset removal when storage limits are reached
User control over which assets are prioritized for offline use