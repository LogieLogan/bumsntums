# UX/Theme Specification for Workout Tracking & Analytics

## 1. Visual Design Language

### 1.1 Layout Patterns
- **Container Style**: Rounded cards (16px radius) with subtle shadows (0.05 opacity black, 10px blur, 2px y-offset)
- **Section Headers**: Icon + Title format with consistent spacing (8px between icon and text)
- **Vertical Spacing**: 32px between major sections, 12-16px between related elements
- **Content Padding**: 16px padding within container elements

### 1.2 Color Application
- **Section Headers**: Use AppColors.salmon for icons
- **Primary Actions**: AppColors.salmon as background with white text
- **Secondary Actions**: AppColors.salmon for text/border with transparent background
- **Feature Categories**: 
  - Bums: AppColors.salmon
  - Tums: AppColors.popCoral
  - Full Body: AppColors.popBlue
  - Quick: AppColors.popGreen
- **Interactive Elements Backgrounds**: Use color.withOpacity(0.1) for container backgrounds
- **Coming Soon Labels**: Solid color pills with white text

### 1.3 Typography Usage
- **Section Headers**: AppTextStyles.h3 with fontWeight: FontWeight.bold
- **Card Titles**: AppTextStyles.body with fontWeight: FontWeight.bold
- **Card Descriptions**: AppTextStyles.small with AppColors.mediumGrey
- **Stats & Metrics**: AppTextStyles.body with bold numbers, regular unit text
- **Buttons**: AppTextStyles.body with fontWeight: FontWeight.w500 (OutlinedButton) or bold (ElevatedButton)
- **Labels & Tags**: AppTextStyles.caption with appropriate weight for emphasis

## 2. Common UI Components

### 2.1 Cards
- **Standard Card**: White background, rounded corners, subtle shadow
- **Feature Card**: Gradient background, white text, subtle icon background pattern
- **Stat Card**: White background with colored accent elements for metrics
- **Category Card**: Color-tinted background (0.1 opacity) with matching icon and text

### 2.2 Buttons
- **Primary Button**: Full width, 44px height, 12px border radius, AppColors.salmon background
- **Secondary Button**: Outlined style, matching text and border color, full width
- **Action Chip**: Rounded pill style with icon + text combination
- **Icon Buttons**: Typically within a colored container with semi-transparent background

### 2.3 Interactive Elements
- **Selectable Items**: State change via background color intensity
- **Tappable Cards**: Full card is tappable with appropriate feedback
- **Progress Indicators**: Use circular or linear indicators in brand colors
- **Toggle Controls**: Maintain consistent control size with color-based state indication

## 3. Animation & Transitions

### 3.1 Page Transitions
- **Screen Entry**: FadeTransition animation (800ms, Curves.easeOut)
- **Element Loading**: Staggered animations for card elements (100ms delay between items)

### 3.2 Interactive Feedback
- **Tap Feedback**: Subtle scale or highlight effect
- **Achievement Celebrations**: Use engaging animations for milestones and streaks
- **Progress Updates**: Animate changes in metrics and statistics

## 4. UI Patterns for Workout Tracking

### 4.1 Calendar View
- Color-coded day indicators based on workout status (completed, planned, missed)
- Current day highlighted with brand accent
- Consistent date formatting and adequate touch targets

### 4.2 Analytics Visualization
- Clean, minimalist charts without excessive gridlines or decoration
- Consistent color coding between related metrics
- Appropriate spacing between chart elements
- Clear legends and minimal but sufficient labels

### 4.3 Workout Planning Interface
- Simple drag-and-drop interface for workout scheduling
- Visual distinction between suggested and user-selected workouts
- Clear indicators for recurring workouts
- Intuitive editing controls with appropriate sizing

## 5. Accessibility Considerations

### 5.1 Touch Targets
- Minimum tap target size of 44x44px for all interactive elements
- Adequate spacing between interactive elements (minimum 8px)

### 5.2 Text Legibility
- Maintain minimum text size (14sp for regular content, 12sp only for supplementary information)
- Ensure sufficient contrast ratios (4.5:1 minimum for normal text)
- Avoid relying solely on color to convey information

### 5.3 Visual Feedback
- Provide clear visual feedback for all interactions
- Ensure state changes are communicated through multiple visual cues

## 6. Responsive Behavior

### 6.1 Layout Adaptation
- Use Expanded widgets for flexible content
- Implement scrolling containers for potentially overflowing content
- Maintain consistent padding regardless of screen size

### 6.2 Orientation Support
- Optimize portrait mode as primary experience
- Ensure critical information is accessible in landscape when relevant