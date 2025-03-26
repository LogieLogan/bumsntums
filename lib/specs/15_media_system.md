Exercise Media System - Updated Technical Specification for Phase 2
1. Overview
This specification outlines the implementation of an enhanced media system for the Bums & Tums fitness app, focusing on integrating existing exercise videos with minimal app size impact.
1.1 Goals

Provide video demonstrations for core exercises
Optimize video size to reduce app bundle size
Implement proper video playback in the exercise demonstration UI
Establish a sustainable naming convention for exercise media
Create a scalable system that maps exercises to their corresponding videos

1.2 Current Status & Next Steps
ComponentStatusNext StepsExercise Media ServiceImplementedUpdate to better handle video pathsExercise Image WidgetImplementedNo changes neededExercise Demo WidgetImplementedEnhance to support video playbackAsset OptimizationNot StartedCompress videos for optimal sizeVideo-Exercise MappingNot StartedCreate mapping system for videos to exercisesExercise DatabaseImplementedExpand to match available videos
2. Video Implementation Strategy
2.1 Video Optimization
To reduce app size while maintaining video quality:

Video Compression

Compress existing MP4 videos to reduce file size
Target resolution: 480p (640x480)
Target bitrate: ~500Kbps
Target file size: Under 1MB per video
Maintain aspect ratio and frame rate


Naming Convention

Use lowercase, snake_case format for all video files
Format: exercise_name_variation.mp4
Examples:

squat_standard.mp4
glute_bridge_weighted.mp4
plank_side.mp4




Sample Frame Extraction

Generate thumbnail images from the first frame of each video
Use compressed JPG format for thumbnails
Store thumbnails in a separate folder for quick loading



2.2 Media Structure
Adapt the existing asset structure to better organize exercise media:
Copyassets/
├── videos/
│   ├── exercises/
│   │   ├── squat.mp4
│   │   ├── glute_bridge.mp4
│   │   └── ...
├── thumbnails/
│   ├── exercises/
│   │   ├── squat.jpg
│   │   ├── glute_bridge.jpg
│   │   └── ...
├── icons/
│   └── exercises/
│       └── ...
3. Integration Implementation
3.1 Exercise-Video Mapping

Mapping Strategy

Create a mapping service that associates exercise names with video paths
Implement fuzzy matching to handle slight naming variations
Allow for manual override when automatic matching fails


Fallback System

Implement cascading fallbacks:

Exact match video
Similar exercise video
Static image
Generic category placeholder





3.2 ExerciseDemoWidget Enhancement

Video Playback

Implement video player integration using the video_player package
Add controls for play/pause, replay, and mute
Implement autoplay option with user preference setting
Add loading indicator during video preparation


UI Enhancements

Thumbnail display while video is loading
Responsive layout for different screen sizes
Accessibility features (captions, playback speed)
Error states with helpful messages



3.3 ExerciseMediaService Updates

Video Path Resolution

Enhance the service to properly resolve video paths
Implement better matching between exercise names and video filenames
Add support for variations of the same exercise


Asset Availability Checking

Add method to check if a video exists for an exercise
Implement pre-flight validation of media assets
Log missing assets for future content creation



4. Exercise Database Expansion
4.1 Exercise Data Enhancement

Video Integration

Update mock exercise database to include videoPath for all exercises
Add metadata for videos (duration, has_audio, etc.)
Include thumbnail paths for faster loading


Exercise Library Expansion

Add new exercises based on available videos
Ensure all exercise data includes proper descriptions and form tips
Add difficulty levels and target muscles for all exercises



5. Implementation Plan
5.1 Phase 1: Preparation and Optimization (Week 1)

Video Assessment

Analyze existing videos for size and quality
Test sample compression to find optimal settings
Establish compression workflow


Asset Organization

Review and organize existing videos
Generate thumbnails for existing videos
Establish naming convention implementation plan



5.2 Phase 2: Core Implementation (Week 2)

Media Service Updates

Update ExerciseMediaService to better handle videos
Implement video path resolution logic
Create exercise-to-video mapping functionality


UI Implementation

Enhance ExerciseDemoWidget with video playback
Implement video controls and user interface
Add loading and error states



5.3 Phase 3: Database and Integration (Week 3)

Database Expansion

Update mock exercise database with video paths
Add new exercises based on available videos
Ensure comprehensive exercise coverage


Testing and Optimization

Test video playback on various devices
Measure and optimize app size impact
Implement performance improvements



6. Future Considerations (Post-Phase 2)

Caching Implementation

Add caching for frequently accessed videos
Implement preloading for workout sequences
Add user preference for media storage management


Cloud-Based Extended Library

Move some videos to cloud storage to reduce app size
Implement on-demand downloading with caching
Create content update mechanism
