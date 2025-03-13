# Firebase Architecture

## 4.1 Firestore Collections (Enhanced Schema with PII Separation)

```
# PII Collection - Secured and isolated from AI features
/users_personal_info/{userId}
  - name: string
  - email: string
  - photoUrl: string (optional)
  - createdAt: timestamp
  - lastActive: timestamp
  - address: string (optional)
  - phoneNumber: string (optional)
  - paymentMethods: array (if applicable)
  - subscription: {
      status: string (free, premium)
      expiresAt: timestamp (optional)
      platform: string (apple, google)
      receiptId: string (optional)
  }
  - settings: {
      notifications: boolean
      privacyLevel: string (public, friends, private)
      units: string (metric, imperial)
  }

# Non-PII Collection - Available for AI features
/fitness_profiles/{userId}
  - profileId: string (random ID, not sequential)
  - ageRange: string (e.g., "25-34", not exact age)
  - height: number
  - weight: number
  - fitnessLevel: string (beginner, intermediate, advanced)
  - fitnessGoals: array (weight loss, toning, strength)
  - dietaryPreferences: array (keto, vegan, etc.)
  - allergies: array (optional)
  - bodyFocusAreas: array (bums, tums, arms, etc.)
  - stats: {
      workoutsCompleted: number
      totalWorkoutMinutes: number
      streakDays: number
      caloriesBurned: number (estimated)
  }

/food_scans/{scanId}
  - userId: reference
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

/food_diary/{diaryId}
  - userId: reference
  - date: timestamp
  - entries: array [
      {
        scanId: reference (optional)
        productName: string
        servingSize: number
        mealType: string (breakfast, lunch, dinner, snack)
        nutritionInfo: {} (copied from scan or manual entry)
      }
  ]
  - dailyTotals: {
      calories: number
      protein: number
      carbs: number
      fat: number
  }

/workouts/{workoutId}
  - title: string
  - description: string
  - imageUrl: string
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
        name: string
        description: string
        imageUrl: string
        videoUrl: string (optional)
        sets: number
        reps: number
        duration: number (if timed)
        restBetween: number (seconds)
        targetArea: string (bums, tums, etc.)
      }
  ]
  - equipment: array (none, mat, dumbbells, etc.)
  - tags: array (quick, intense, recovery, etc.)

/workout_logs/{logId}
  - userId: reference
  - workoutId: reference
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
  - participants: array (userIds)
  - createdBy: string (admin, ai)
  - isActive: boolean

/posts/{postId}
  - userId: reference
  - createdAt: timestamp
  - type: string (workout, progress, food, general)
  - content: string
  - imageUrls: array
  - videoUrl: string (optional)
  - tags: array (workout names, challenge names)
  - privacy: string (public, friends, private)
  - interactions: {
      likes: number
      comments: number
  }
  - workoutRef: reference (optional)
  - challengeRef: reference (optional)

/comments/{commentId}
  - postId: reference
  - userId: reference
  - createdAt: timestamp
  - content: string
  - likes: number

/notifications/{notificationId}
  - userId: reference
  - createdAt: timestamp
  - read: boolean
  - type: string (workout, challenge, social, system)
  - title: string
  - body: string
  - actionType: string (open workout, view challenge, etc.)
  - referenceId: string (workoutId, challengeId, etc.)
```

## 4.2 Firebase Storage Structure
```
/user_images/{userId}/profile/{filename}
/user_images/{userId}/posts/{postId}/{filename}
/workout_images/{workoutId}/{filename}
/workout_videos/{workoutId}/{filename}
/exercise_images/{exerciseId}/{filename}
/exercise_videos/{exerciseId}/{filename}
/challenge_images/{challengeId}/{filename}
```

## 4.3 Firebase Cloud Functions

### Authentication Functions
- `onUserCreate`: Initializes user profile and settings when a new user signs up
- `cleanupUserData`: Handles data cleanup when a user deletes their account

### Nutrition Functions
- `processScannedFood`: Processes OCR data and enriches it with nutritional analysis
- `generateFoodRecommendations`: Creates personalized food recommendations based on goals
- `createWeeklyNutritionReport`: Summarizes weekly food intake and provides insights

### Workout Functions
- `generateAiWorkout`: Creates personalized workouts using OpenAI
- `processWorkoutCompletion`: Updates user stats and generates follow-up recommendations
- `suggestNextWorkout`: Recommends next workout based on history and progress

### Social Functions
- `processNewPost`: Handles content moderation and notification triggers
- `handleUserFollowAction`: Updates relevant feeds when users follow/unfollow

### Challenge Functions
- `createWeeklyChallenge`: Automatically generates weekly challenges
- `updateChallengeProgress`: Updates leaderboard and progress tracking
- `awardChallengeBadges`: Handles reward distribution when challenges complete

### Maintenance Functions
- `scheduledDataBackup`: Creates periodic backups of critical user data
- `cleanupOldTempFiles`: Removes temporary files older than 24 hours