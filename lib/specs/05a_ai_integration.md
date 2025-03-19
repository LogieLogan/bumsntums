# AI Integration (OpenAI-mini)

## 5.1 Models & Use Cases
- **Text Generation (OpenAI-mini):**
  - Personalized workout recommendations
  - Fitness and nutrition advice
  - Motivational messages
  - Challenge ideas
  - Workout refinement and iteration
  - Nutrition planning based on user goals

## 5.2 Data Points for AI Decision Making
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

## 5.3 PII Protection Strategy
1. **Strict Data Separation:**
   - AI features only access non-PII collections (`fitness_profiles`, `workout_logs`, etc.)
   - Hard separation enforced at Firebase security rules level
   - No personal identifiers ever sent to OpenAI

2. **Anonymous Context:**
   - Use OpenAI's built-in conversation management for active sessions
   - User referred to generically as "the user" not by name
   - Fitness profile sent at conversation start excludes all PII

3. **Simplified Data Architecture:**
   - Clean separation between personal and fitness data from the start
   - No complex PII filtering needed as data is never mixed

## 5.4 Implementation Approach
1. **Data Preprocessing:**
   - Only access non-PII `fitness_profiles` collection
   - Normalize numerical values (weight, height)
   - One-hot encode categorical data (diet type, fitness goals)
   
2. **Prompting Strategy:**
   - Use structured prompts with clear constraints
   - Include specific context limiting token usage
   - Develop and test specific prompt templates for workout generation
   - Integrate personalized system prompt with custom message from the user
   - Workout generation two step process: 1. user selects AI action i.e. build personalized workout 2. user then can chat to fine tune the workout
   - Implement layered prompting architecture (see section 5.7)
   
3. **Conversation Management:**
   - Use OpenAI's built-in conversation context for active sessions
   - For new conversations, include relevant previous insights in system prompt
   - Store only anonymous summaries of past interactions
   - Provide tools for users to be able to configure AI personality such as (humor level, conversational level, level of detail, friendly and approachable, playfulness) and are added to system prompts
   - Provide stock AI personas with approachable names and defined pre-made personas that are added in system prompts
   - AI chat function always accessible in the app bar to direct and inform the user on anything from how to use the app to what they should make for breakfast to make me a workout all using their personalized system prompt
   - Implement conversation limits and archiving mechanism (see section 5.8)

4. **Cost Optimization:**
   - Batch AI requests during off-peak hours
   - Implement local caching of common responses
   - Use completion endpoints with controlled token limits
   - Set strict monthly usage caps to avoid unexpected costs
   - Consider pre-generating common workout recommendations
   - Implement token usage tracking and analytics

5. **Workout-Specific Prompting Strategy:**
   - Templates for generating personalized workouts
   - Example prompt: "Create a [duration] minute [difficulty] workout focusing on [bodyFocusAreas] for a user with [equipment] equipment. The user's fitness level is [fitnessLevel] and their goals include [goals]."
   - Templates include constraints such as:
     - Maximum number of exercises
     - Required rest periods
     - Clear instructions for each exercise
     - Proper progression structure

## 5.5 Current Optimization Techniques

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

## 5.6 Workout Refinement System

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

## 5.7 Layered Prompting Architecture

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

## 5.8 Conversation Management System

To optimize for both user experience and API costs:

1. **Conversation Lifecycle:**
   - New conversations created for distinct topics
   - Conversations auto-archive after 7 days of inactivity
   - Maximum of 30 messages per conversation before suggesting a new one

2. **Storage Strategy:**
   - Local-first approach using SQLite/Hive for immediate history
   - Periodic syncing with Firebase for persistence across devices
   - Pagination for retrieving longer conversation histories

3. **Message Retention:**
   - Free tier: 10 most recent conversations stored
   - Premium tier: Unlimited conversation storage
   - Auto-pruning of older messages based on tier limits

4. **Context Window Management:**
   - Dynamic selection of which messages to include in context
   - Intelligent summarization of longer conversations
   - Priority given to user-specified important messages

## 5.9 AI Analytics and Learning Systems

1. **Usage Analytics:**
   - Track token usage by feature and user
   - Monitor query patterns and common requests
   - Identify opportunities for pre-computing or caching

2. **Feedback Collection:**
   - Explicit feedback on workout recommendations
   - Implicit feedback based on user actions (starting a workout, abandoning a workout)
   - Conversation ratings and helpfulness indicators

3. **Continuous Improvement:**
   - Regular prompt optimization based on performance data
   - Refinement of intent detection accuracy
   - Expansion of cached response categories

4. **A/B Testing Framework:**
   - Testing different prompt structures
   - Comparing response formats
   - Evaluating caching strategies