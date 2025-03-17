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
   - Cache frequently used prompt templates
   - Develop and test specific prompt templates for workout generation
   
3. **Conversation Management:**
   - Use OpenAI's built-in conversation context for active sessions
   - For new conversations, include relevant previous insights in system prompt
   - Store only anonymous summaries of past interactions

4. **Cost Optimization:**
   - Batch AI requests during off-peak hours
   - Implement local caching of common responses
   - Use completion endpoints with controlled token limits
   - Set strict monthly usage caps to avoid unexpected costs
   - Consider pre-generating common workout recommendations

5. **Workout-Specific Prompting Strategy:**
   - Templates for generating personalized workouts
   - Example prompt: "Create a [duration] minute [difficulty] workout focusing on [bodyFocusAreas] for a user with [equipment] equipment. The user's fitness level is [fitnessLevel] and their goals include [goals]."
   - Templates include constraints such as:
     - Maximum number of exercises
     - Required rest periods
     - Clear instructions for each exercise
     - Proper progression structure