# AI Integration (OpenAI-mini)

## 5.1 Models & Use Cases
- **Text Generation (OpenAI-mini):**
  - Personalized workout recommendations
  - Fitness and nutrition advice
  - Motivational messages
  - Challenge ideas

## 5.2 Data Points for AI Decision Making
The AI model will use the following data points from the non-PII collection:
- Fitness profile (height, weight range, fitness goals)
- Fitness level and experience
- Workout history and preferences
- Dietary preferences and restrictions
- Progress data (weight tracking, workout completion)
- Feedback on previous workouts
- Target body areas for focus

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
   - Intergrate personalised system prompt with custom message from the user
   - Workout generation two step process 1. user selects AI action i.e. build personalised workout 2. user then can chat to fine tune the workout.
   
3. **Conversation Management:**
   - Use OpenAI's built-in conversation context for active sessions
   - For new conversations, include relevant previous insights in system prompt
   - Store only anonymous summaries of past interactions
   - Provide tools for users to be able to configure AI personality such as (humour level, conversational level, level of detail, friendly and approachable, playfulness) and are added to system prompts.
   - Provide stock AI personas with approachable names and defined pre made personans that are added in system prompts.
   - Ai chat function always accsible in the app bar to direct and inform the user on anything from how to use the app to what should they make for breakfast to make me a workout all using their personalised system prompt.

4. **Cost Optimization:**
   - Batch AI requests during off-peak hours
   - Implement local caching of common responses
   - Use completion endpoints with controlled token limits
   - Set strict monthly usage caps to avoid unexpected costs
   - Consider pre-generating common workout recommendations

# Additional Cost Optimization Considerations

## Current Approach
- Token limits are implemented for both chat and workout generation
- System prompts are optimized for clarity while minimizing token usage
- Response constraints are specified to guide the AI toward concise outputs

## Future Enhancements for Cost Optimization

### Caching Strategy Considerations
While a full caching system isn't implemented in the initial phase, the following considerations have been documented for future implementation:

**Challenges with Caching in Personalized AI:**
- Most prompts contain personalized system information based on user profiles
- Responses are tailored to individual fitness levels, goals, and constraints
- Simple 1:1 caching would have limited effectiveness due to these personalizations

**Potential Future Approaches:**
- **Segmented Caching:** Cache by query + key profile attributes to create user segments
- **Knowledge-Based Response Caching:** Implement selective caching for responses that are less dependent on personalization
- **Pre-Generated Content:** For common workout types, pre-generate and cache responses for different user profiles

### Current Optimization Techniques
The following techniques are implemented to manage costs without a complex caching system:

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

### Future Cost Analysis
- Implement analytics to track token usage per feature
- Establish usage patterns to identify optimization opportunities
- Consider implementing more advanced caching based on actual usage data

5. **Workout-Specific Prompting Strategy:**
   - Templates for generating personalized workouts
   - Example prompt: "Create a [duration] minute [difficulty] workout focusing on [bodyFocusAreas] for a user with [equipment] equipment. The user's fitness level is [fitnessLevel] and their goals include [goals]."
   - Templates include constraints such as:
     - Maximum number of exercises
     - Required rest periods
     - Clear instructions for each exercise
     - Proper progression structure