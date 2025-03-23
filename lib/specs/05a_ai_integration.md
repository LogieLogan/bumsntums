# Consolidated AI Integration Specification

## 1. System Overview & Architecture

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

## 2. Models & Use Cases

### 2.1 Primary AI Functions
- **Text Generation (OpenAI-mini):**
  - Personalized workout recommendations
  - Fitness and nutrition advice
  - Motivational messages
  - Challenge ideas
  - Workout refinement and iteration
  - Nutrition planning based on user goals

### 2.2 Enhanced Workout-Specific AI Capabilities

#### Personalized Exercise Modifications
- **Smart Substitutions**: Suggest personalized exercise alternatives based on user equipment, fitness level, and reported limitations
- **Form Guidance**: Generate specific form cues tailored to a user's experience level
- **Progressive Overload**: Intelligent suggestions for when to increase weight, reps, or sets based on previous performance

#### Natural Language Workout Creation
- **Conversation-Based Workouts**: Allow users to describe what they want in natural language
- **Workout Refinement**: Enable natural language adjustments to workouts
- **Equipment Adaptation**: Dynamically adjust workouts based on available equipment

#### Contextual Exercise Instructions
- **Experience-Aware Coaching**: Provide more detailed instructions for beginners, more advanced cues for experienced users
- **Real-Time Adjustment**: Generate alternative instructions if a user reports difficulty
- **Personalized Motivation**: Create motivational prompts based on user preferences

#### Smart Recovery Recommendations
- **Fatigue Analysis**: Analyze workout intensity to suggest appropriate recovery periods
- **Active Recovery Suggestions**: Generate tailored active recovery workouts
- **Sleep Integration**: Provide workout modifications based on reported sleep quality

#### Workout Planning Intelligence
- **Balanced Program Design**: Generate well-balanced weekly plans considering muscle recovery
- **Goal Alignment**: Intelligently distribute workouts aligned with fitness goals
- **Adaptive Scheduling**: Adjust recommendations based on actual adherence patterns

#### Personalized Progress Insights
- **Pattern Recognition**: Identify trends in workout performance
- **Achievement Spotlighting**: Highlight specific achievements in a conversational way
- **Plateau Detection**: Recognize stalled progress and suggest modifications

#### In-Workout Adaptation
- **Real-Time Difficulty Adjustment**: Suggest modifications during workouts based on exertion
- **Time-Constrained Adaptations**: Intelligently compress or expand workouts for time constraints
- **Energy-Level Responsiveness**: Adjust intensity based on reported energy levels

## 3. Data Points for AI Decision Making

The AI model will use the following data points from the non-PII collection:
- Fitness profile (height, weight range, fitness goals)
- Fitness level and experience
- Workout history and preferences
- Dietary preferences and restrictions
- Progress data (weight tracking, workout completion)
- Feedback on previous workouts
- Target body areas for focus
- Workout environment and available equipment
- Health conditions and limitations

## 4. Data Flow & Privacy Protection

### 4.1 Data Flow Diagram

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

### 4.2 Privacy Safeguards

1. **Strict Data Separation:**
   - AI features only access non-PII collections (`fitness_profiles`, `workout_logs`, etc.)
   - Hard separation enforced at Firebase security rules level
   - No personal identifiers ever sent to OpenAI

2. **Anonymous Context:**
   - Use OpenAI's built-in conversation management for active sessions
   - User referred to generically as "the user" not by name
   - Fitness profile sent at conversation start excludes all PII

3. **Data Sanitization Pipeline**:
   - Fitness profile data is filtered through a sanitization service
   - Removes any potential PII before passing to AI services
   - Anonymizes user identifiers with session-specific IDs

4. **Local Processing**:
   - When possible, sensitive data is processed locally
   - Only sanitized, non-PII data is sent to external AI services

### 4.3 Rate Limiting Strategy

1. **User Tier Limits**:
   - Free tier: 10 AI interactions per day
   - Premium tier: 50 AI interactions per day

2. **Cooldown Periods**:
   - Progressive cooldown for rapid successive requests
   - Helps prevent abuse and manages costs

3. **Token Budget**:
   - Daily/monthly token usage limits by user tier
   - Dynamic adjustment of max_tokens based on remaining budget

## 5. Implementation Approaches

### 5.1 Data Preprocessing
- Only access non-PII `fitness_profiles` collection
- Normalize numerical values (weight, height)
- One-hot encode categorical data (diet type, fitness goals)

### 5.2 Prompting Strategy
- Use structured prompts with clear constraints
- Include specific context limiting token usage
- Develop and test specific prompt templates for workout generation
- Integrate personalized system prompt with custom message from the user
- Workout generation two step process: 1. user selects AI action i.e. build personalized workout 2. user then can chat to fine tune the workout
- Implement layered prompting architecture

### 5.3 Conversation Management
- Use OpenAI's built-in conversation context for active sessions
- For new conversations, include relevant previous insights in system prompt
- Store only anonymous summaries of past interactions
- Provide tools for users to configure AI personality (humor level, detail level, etc.)
- Provide stock AI personas with approachable names
- AI chat function always accessible in the app bar
- Implement conversation limits and archiving mechanism

### 5.4 Cost Optimization
- Batch AI requests during off-peak hours
- Implement local caching of common responses
- Use completion endpoints with controlled token limits
- Set strict monthly usage caps to avoid unexpected costs
- Consider pre-generating common workout recommendations
- Implement token usage tracking and analytics

### 5.5 Workout-Specific Prompting Strategy
- Templates for generating personalized workouts
- Example prompt: "Create a [duration] minute [difficulty] workout focusing on [bodyFocusAreas] for a user with [equipment] equipment. The user's fitness level is [fitnessLevel] and their goals include [goals]."
- Templates include constraints such as:
  - Maximum number of exercises
  - Required rest periods
  - Clear instructions for each exercise
  - Proper progression structure

## 6. Caching Architecture

### 6.1 Multi-level Caching Strategy

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

### 6.2 Cache Categories

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

### 6.3 Cache Key Generation

Keys generated using a combination of:
- Intent category
- Query fingerprint (normalized query)
- User segment identifiers
- Profile attribute hashes (non-PII)

## 7. Current Optimization Techniques

1. **Token Optimization:** 
   - Carefully crafted prompts to use fewer tokens while maintaining quality
   - Removal of unnecessary context from system prompts
   - Structured output requirements to minimize verbosity

2. **Response Limits:** 
   - Strict max_tokens limits for different types of responses
   - Different limits based on feature (chat vs. workout generation)

3. **Rate Limiting:** 
   - User-based quotas to prevent API abuse
   - Cooling periods for rapid successive requests

## 8. Workout Refinement System

The workout refinement system allows users to iteratively improve AI-generated workouts:

1. **Refinement Capabilities:**
   - Exercise swapping: Replace specific exercises with alternatives
   - Difficulty adjustment: Make specific parts easier or harder
   - Duration modification: Extend or shorten workout duration
   - Equipment changes: Adapt exercises based on available equipment
   - Focus area emphasis: Adjust emphasis on specific muscle groups

2. **Refinement Flow:**
   - Initial workout generation using user's profile
   - User reviews workout and can:
     - Accept as-is
     - Request specific modifications
     - Regenerate completely
   - AI responds with modified workout preserving unaffected parts
   - Iterative refinement continues until user is satisfied

3. **Refinement Context Handling:**
   - Original workout stored as context for refinement requests
   - User feedback incorporated into subsequent generations
   - System learns from refinement patterns to improve initial recommendations

## 9. Layered Prompting Architecture

The AI system uses a layered approach to prompting to optimize results:

1. **Base Layer: User Profile**
   - Contains fitness level, goals, and constraints
   - Always included in system prompt
   - Minimal and token-optimized

2. **Context Layer: Conversation History**
   - Includes relevant previous interactions
   - Limited to last N messages based on token budget
   - Prioritizes most recent and most relevant messages

3. **Intent Layer: Interaction Type**
   - Specialized prompts based on detected intent
   - Categories include: workout advice, nutrition guidance, motivation, etc.
   - Tailors system behavior to specific use case

4. **Response Layer: Output Formatting**
   - Structured output requirements for consistent parsing
   - Format varies by interaction type (JSON for workouts, conversational for chat)
   - Includes validation requirements

5. **Safety Layer: Constraints and Limitations**
   - Health and safety guidelines
   - Exercise modification requirements
   - Appropriate difficulty levels based on user profile

## 10. Conversation Management

### 10.1 Conversation Data Model

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

### 10.2 Conversation Lifecycle

- New conversations created for distinct topics
- Conversations auto-archive after 7 days of inactivity
- Maximum of 30 messages per conversation before suggesting a new one

### 10.3 Storage Strategy

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

### 10.4 Message Retention
- Free tier: 10 most recent conversations stored
- Premium tier: Unlimited conversation storage
- Auto-pruning of older messages based on tier limits

### 10.5 Context Window Management
- Dynamic selection of which messages to include in context
- Intelligent summarization of longer conversations
- Priority given to user-specified important messages
- Always include the last 3 messages
- Include all pinned messages
- Fill remaining context with most relevant messages
- Use deterministic selection algorithm to ensure consistency

## 11. Prompt Template System

### 11.1 Template Structure

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

### 11.2 Template Storage

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

### 11.3 Template Categories

1. **General Chat**: Base templates for general conversation
2. **Workout Generation**: Templates for creating workouts
3. **Workout Refinement**: Templates for modifying existing workouts
4. **Nutrition Advice**: Templates for dietary recommendations
5. **Motivation**: Templates for encouragement and adherence
6. **Educational**: Templates for explaining fitness concepts

### 11.4 A/B Testing Integration

- Templates can have multiple active versions
- Analytics track performance metrics by template version
- Automatic rotation based on performance

## 12. Feedback System

### 12.1 Feedback Types

1. **Explicit Feedback**:
   - Thumbs up/down on AI responses
   - Specific workout feedback (too easy, just right, too hard)
   - Helpfulness ratings

2. **Implicit Feedback**:
   - Starting a recommended workout
   - Completing a recommended workout
   - Abandoning a workout early
   - Follow-up questions (indicating unclear response)

### 12.2 Feedback Data Model

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

### 12.3 Storage Model

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

## 13. Analytics Integration

### 13.1 Events to Track

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

### 13.2 Custom Dimensions

- `user_fitness_level`
- `user_goals`
- `interaction_category`
- `template_version`
- `subscription_tier`

### 13.3 Cost Tracking

- Track token usage by feature, template, and user
- Monitor costs against budget
- Alert on unusual usage patterns

## 14. AI Analytics and Learning Systems

1. **Usage Analytics:**
   - Track token usage by feature and user
   - Monitor query patterns and common requests
   - Identify opportunities for pre-computing or caching

2. **Feedback Collection:**
   - Explicit feedback on workout recommendations
   - Implicit feedback based on user actions
   - Conversation ratings and helpfulness indicators

3. **Continuous Improvement:**
   - Regular prompt optimization based on performance data
   - Refinement of intent detection accuracy
   - Expansion of cached response categories

4. **A/B Testing Framework:**
   - Testing different prompt structures
   - Comparing response formats
   - Evaluating caching strategies

## 15. Implementation Plan for Phase 2

### 15.1 Phase 2a (Current Focus)

1. **Core Infrastructure**:
   - Implement conversation management system
   - Build caching architecture
   - Create prompt template system

2. **Features**:
   - Enhance workout generation with refinement
   - Add conversation persistence
   - Implement feedback collection
   - Implement personalized exercise modifications
   - Create natural language workout creation interface

### 15.2 Phase 2b (Next Steps)

1. **Optimization**:
   - Deploy caching strategy
   - Implement token usage tracking
   - Optimize prompt templates
   - Develop contextual exercise instructions
   - Implement workout planning intelligence

2. **Features**:
   - Advanced nutrition recommendations
   - Integration with food scanning
   - Workout history analysis
   - In-workout adaptation capabilities
   - Smart recovery recommendations

### 15.3 Phase 2c (Final Steps)

1. **Advanced Features**:
   - Implement streaming responses
   - Add voice interaction
   - Create fitness education Q&A system
   - Develop personalized progress insights
   - Release advanced workout adaptation features