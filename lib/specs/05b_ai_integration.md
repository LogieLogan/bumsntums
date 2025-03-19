# AI Architecture & Implementation

## 1. System Overview

### 1.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                       User Interface Layer                       │
├────────────┬───────────────────┬──────────────┬─────────────────┤
│  AI Chat   │  Workout Creator  │  Nutritional │  Workout        │
│  Screen    │  Screen           │  AI Advisor  │  Refinement     │
└────────────┴───────────────────┴──────────────┴─────────────────┘
           ▲                    ▲                    ▲
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                      State Management Layer                      │
├────────────┬───────────────────┬──────────────┬─────────────────┤
│  AI Chat   │  Workout          │  Nutrition   │  Prompt         │
│  Provider  │  Recommendation   │  Advice      │  Template       │
│            │  Provider         │  Provider    │  Provider       │
└────────────┴───────────────────┴──────────────┴─────────────────┘
           ▲                    ▲                    ▲
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Service Layer                             │
├────────────┬───────────────────┬──────────────┬─────────────────┤
│  OpenAI    │  Cache            │  Analytics   │  Conversation   │
│  Service   │  Service          │  Service     │  Manager        │
└────────────┴───────────────────┴──────────────┴─────────────────┘
           ▲                    ▲                    ▲
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Data Layer                                │
├────────────┬───────────────────┬──────────────┬─────────────────┤
│  Local     │  Firestore        │  OpenAI      │  Analytics      │
│  Storage   │  (No PII)         │  API         │  Events         │
└────────────┴───────────────────┴──────────────┴─────────────────┘
```

### 1.2 Key Components

1. **OpenAI Service**: Central service handling all AI interactions
2. **Cache Service**: Manages local and remote caching of AI responses
3. **Conversation Manager**: Handles conversation context and history
4. **Prompt Template Manager**: Manages and selects appropriate prompts

## 2. Data Flow & Privacy Protection

### 2.1 Data Flow Diagram

```
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ PII Collection│     │ Non-PII       │     │ AI Service    │
│ (Firestore)   │     │ Collection    │     │ Layer         │
│               │     │ (Firestore)   │     │               │
└───────┬───────┘     └───────┬───────┘     └───────┬───────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     │
┌───────────────┐     ┌───────────────┐            │
│ Auth Service  │     │ Fitness       │            │
│               │─────► Profile       │            │
│               │     │ Service       │            │
└───────────────┘     └───────┬───────┘            │
                              │                     │
                              │                     │
                              ▼                     │
                      ┌───────────────┐            │
                      │ AI-Safe       │            │
                      │ Profile Data  │            │
                      │ (Anonymized)  │────────────►
                      └───────────────┘
```

### 2.2 Privacy Safeguards

1. **Hard Separation**: 
   - Different Firestore collections for PII vs. non-PII data
   - Security rules prevent AI services from accessing PII collections

2. **Data Sanitization Pipeline**:
   - Fitness profile data is filtered through a sanitization service
   - Removes any potential PII before passing to AI services
   - Anonymizes user identifiers with session-specific IDs

3. **Local Processing**:
   - When possible, sensitive data is processed locally
   - Only sanitized, non-PII data is sent to external AI services

### 2.3 Rate Limiting Strategy

1. **User Tier Limits**:
   - Free tier: 10 AI interactions per day
   - Premium tier: 50 AI interactions per day

2. **Cooldown Periods**:
   - Progressive cooldown for rapid successive requests
   - Helps prevent abuse and manages costs

3. **Token Budget**:
   - Daily/monthly token usage limits by user tier
   - Dynamic adjustment of max_tokens based on remaining budget

## 3. Caching Architecture

### 3.1 Multi-level Caching Strategy

```
┌─────────────────┐
│ Request         │
└────────┬────────┘
         ▼
┌────────────────────┐     ┌─────────────────┐
│ Local Memory Cache ├────►│ Return Cached   │
│ (Hit?)             │ Yes │ Response        │
└────────┬───────────┘     └─────────────────┘
         │ No
         ▼
┌────────────────────┐     ┌─────────────────┐
│ Local Storage      ├────►│ Return Cached   │
│ Cache (Hit?)       │ Yes │ Response        │
└────────┬───────────┘     └─────────────────┘
         │ No
         ▼
┌────────────────────┐     ┌─────────────────┐
│ Firebase Cache     ├────►│ Return Cached   │
│ (Hit?)             │ Yes │ Response        │
└────────┬───────────┘     └─────────────────┘
         │ No
         ▼
┌────────────────────┐
│ OpenAI API Request │
└────────┬───────────┘
         ▼
┌────────────────────┐
│ Update Caches      │
└────────┬───────────┘
         ▼
┌────────────────────┐
│ Return Response    │
└────────────────────┘
```

### 3.2 Cache Categories

1. **Static Responses**:
   - Common questions with stable answers
   - Instruction-based queries (e.g., "How to do a push-up")
   - Long TTL (1 week+)

2. **User-Segment Responses**:
   - Responses based on user segments (beginner, intermediate, advanced)
   - Moderate TTL (1-3 days)

3. **Profile-Based Responses**:
   - Specific to anonymized profile characteristics
   - Shorter TTL (24 hours)

### 3.3 Cache Key Generation

Keys generated using a combination of:
- Intent category
- Query fingerprint (normalized query)
- User segment identifiers
- Profile attribute hashes (non-PII)

## 4. Conversation Management

### 4.1 Conversation Data Model

```dart
class Conversation {
  final String id;
  final String title;        // Generated or user-defined
  final String category;     // workout, nutrition, motivation, etc.
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;
  final List<Message> messages;
  
  // Additional metadata
  final Map<String, dynamic> metadata;
}

class Message {
  final String id;
  final String content;
  final String role;  // 'user' or 'assistant'
  final DateTime timestamp;
  final bool isPinned; // Important messages to always keep in context
  final Map<String, dynamic> metadata; // Token usage, etc.
}
```

### 4.2 Storage Model

**Firestore Collections**:
```
/conversations/{userId}/{conversationId}
  - id
  - title
  - category
  - createdAt
  - lastMessageAt
  - messageCount
  - summary (auto-generated)
  - metadata

/conversations/{userId}/{conversationId}/messages/{messageId}
  - id
  - content
  - role
  - timestamp
  - isPinned
  - metadata
```

**Local Storage**:
- Recent conversations cached in local database
- Pagination strategy for retrieving messages
- Background sync with Firestore

### 4.3 Context Window Management

1. **Message Selection Strategy**:
   - Always include the last 3 messages
   - Include all pinned messages
   - Fill remaining context with most relevant messages
   - Use deterministic selection algorithm to ensure consistency

2. **Smart Summarization**:
   - Generate summaries for longer conversations
   - Include summary in system prompt when context window is limited
   - Custom prompt for generating concise, relevant summaries

## 5. Prompt Template System

### 5.1 Template Structure

```dart
class PromptTemplate {
  final String id;
  final String name;
  final String systemPrompt;
  final String version;
  final String category;
  final Map<String, String> variables;
  final List<String> requiredUserAttributes;
  final Map<String, dynamic> metadata;
  
  String build(Map<String, dynamic> userData, {Map<String, String>? customVars}) {
    // Template variable replacement logic
  }
}
```

### 5.2 Template Storage

Templates stored in Firestore for dynamic updates:
```
/ai_templates/{templateId}
  - id
  - name
  - systemPrompt
  - version
  - category
  - variables (map)
  - requiredUserAttributes (array)
  - metadata
```

### 5.3 Template Categories

1. **General Chat**: Base templates for general conversation
2. **Workout Generation**: Templates for creating workouts
3. **Workout Refinement**: Templates for modifying existing workouts
4. **Nutrition Advice**: Templates for dietary recommendations
5. **Motivation**: Templates for encouragement and adherence
6. **Educational**: Templates for explaining fitness concepts

### 5.4 A/B Testing Integration

- Templates can have multiple active versions
- Analytics track performance metrics by template version
- Automatic rotation based on performance

## 6. Feedback System

### 6.1 Feedback Types

1. **Explicit Feedback**:
   - Thumbs up/down on AI responses
   - Specific workout feedback (too easy, just right, too hard)
   - Helpfulness ratings

2. **Implicit Feedback**:
   - Starting a recommended workout
   - Completing a recommended workout
   - Abandoning a workout early
   - Follow-up questions (indicating unclear response)

### 6.2 Feedback Data Model

```dart
class AIFeedback {
  final String id;
  final String userId;
  final String responseId;
  final String promptTemplateId;
  final String feedbackType;
  final int rating;
  final String? comment;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}
```

### 6.3 Storage Model

```
/ai_feedback/{feedbackId}
  - id
  - userId
  - responseId
  - promptTemplateId
  - feedbackType
  - rating
  - comment
  - timestamp
  - metadata
```

## 7. Analytics Integration

### 7.1 Events to Track

1. **Usage Events**:
   - `ai_conversation_started`
   - `ai_message_sent`
   - `ai_response_received`
   - `ai_workout_generated`
   - `ai_workout_refined`
   - `ai_workout_started`
   - `ai_workout_completed`

2. **Performance Events**:
   - `ai_response_time`
   - `token_usage`
   - `cache_hit_rate`
   - `prompt_template_usage`

3. **Feedback Events**:
   - `ai_response_feedback`
   - `ai_workout_feedback`

### 7.2 Custom Dimensions

- `user_fitness_level`
- `user_goals`
- `interaction_category`
- `template_version`
- `subscription_tier`

### 7.3 Cost Tracking

- Track token usage by feature, template, and user
- Monitor costs against budget
- Alert on unusual usage patterns

## 8. Implementation Plan

### 8.1 Phase 2a (Current Focus)

1. **Core Infrastructure**:
   - Implement conversation management system
   - Build caching architecture
   - Create prompt template system

2. **Features**:
   - Enhance workout generation with refinement
   - Add conversation persistence
   - Implement feedback collection

### 8.2 Phase 2b (Next Steps)

1. **Optimization**:
   - Deploy caching strategy
   - Implement token usage tracking
   - Optimize prompt templates

2. **Features**:
   - Advanced nutrition recommendations
   - Integration with food scanning
   - Workout history analysis

### 8.3 Phase 2c (Final Steps)

1. **Advanced Features**:
   - Implement streaming responses
   - Add voice interaction
   - Create fitness education Q&A system