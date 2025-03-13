# In-App Purchases

## Subscription Tiers
- **Free Tier:**
  - Basic workout access
  - Limited food scanning (5/day)
  - Basic progress tracking
  - Ad-supported experience
  
- **Premium Tier ($4.99/month or $49.99/year):**
  - Unlimited food scanning
  - Advanced AI workout recommendations
  - Custom workout creation
  - Ad-free experience
  - Exclusive challenges
  - Premium badge on social features
  - Detailed analytics and insights
  - 7-day free trial to boost conversion

## Implementation
- **StoreKit Integration:**
  - Product ID configuration
  - Purchase verification
  - Receipt validation
  - Subscription management
  
- **Firebase Integration:**
  - Subscription status syncing
  - Cross-platform subscription state management
  - Entitlement checking for premium features

## Subscription Management
- Upgrade/downgrade flows
- Cancellation process
- Renewal notifications
- Grace period handling
- Subscription recovery

## Entitlement Verification
- Local verification for most features
- Server-side verification for premium content access
- Offline access management
- Subscription state caching

## Free Trial Implementation
- 7-day free trial for new premium subscriptions
- Conversion tracking
- Pre-trial notification
- End-of-trial notification
- Seamless transition to paid subscription

## Analytics
- Conversion rate tracking
- Churn analysis
- Feature usage by subscription tier
- Trial-to-paid conversion rate
- Revenue reporting

## User Experience
- Clear feature comparison between tiers
- Non-intrusive premium upgrade prompts
- Value demonstration for premium features
- Friction-free purchase flow
- Subscription management screen