# 💪 Pushup Alarm - iOS App

An iOS alarm app that requires you to complete 10 pushups to dismiss the alarm! Uses Apple's Vision framework for real-time pose detection through your iPhone's camera.

## Features

- ⏰ Set alarms with a simple, beautiful interface
- 📸 Camera-based pushup detection using Vision framework
- 🎯 Real-time upper-body tracking (arms + head) via Vision keypoints
- ✅ Works with the phone on the floor — no need for legs/hips in frame
- 🔊 Persistent alarm sound until you complete 10 pushups
- 🧪 Test mode to try pushup detection without setting an alarm

## Requirements

- **iOS 17.0+** (uses latest Vision and SwiftUI features)
- **Xcode 15.0+** (with Swift 5.9+)
- **Physical iPhone device** (camera access required; simulator won't work for testing)
- **Apple Developer account** (free account works for personal testing)

## Installation & Setup

### 1. Transfer Files to Your Mac

Download or copy the entire `PushupAlarm` project folder to your Mac.

### 2. Open in Xcode

1. Double-click `PushupAlarm.xcodeproj` to open in Xcode
2. Wait for Xcode to index the project

### 3. Configure Signing

1. Select the project in the navigator (top item)
2. Select the "PushupAlarm" target
3. Go to "Signing & Capabilities" tab
4. Select your **Team** from the dropdown
   - If you don't have a team, click "Add Account" and sign in with your Apple ID
5. Xcode will automatically generate a bundle identifier like `com.yourname.PushupAlarm`

### 4. Connect Your iPhone

1. Connect your iPhone to your Mac via USB
2. Unlock your iPhone and trust the computer if prompted
3. In Xcode, select your iPhone from the device dropdown (top toolbar)

### 5. Build & Run

1. Click the ▶️ Play button in Xcode (or press `Cmd + R`)
2. The first time you run:
   - On your iPhone, go to **Settings > General > VPN & Device Management**
   - Tap your Apple ID and select "Trust"
3. The app will launch on your iPhone!

## How to Use

### Setting an Alarm

1. Open the app
2. Use the time picker to select your alarm time
3. Tap **"Set Alarm"**
4. Lock your phone or close the app - the alarm will still trigger

### When the Alarm Goes Off

1. The app will open automatically (or you can tap the notification)
2. The alarm sound will play persistently
3. Place the phone on the floor facing you and get into pushup position:
   - Keep your head and arms visible to the front camera
   - Legs/hips do not need to be in frame
   - Make sure there's good lighting
4. Perform 10 pushups:
   - The app tracks elbow bend plus head position
   - Lower until your elbows bend / head drops toward your hands
   - Push back up to arm extension
5. After 10 valid pushups, the alarm dismisses automatically!

### Testing Pushup Detection

Before your first alarm, try the detection:
1. Tap **"Test Pushup Detection"** at the bottom of the main screen
2. This lets you practice and see how the detection works
3. No alarm sound in test mode
4. Tap the ❌ button to exit

## Technical Details

### How Pushup Detection Works

The app uses Apple's Vision framework with the following approach:

1. **Upper-body Pose Detection**: `VNDetectHumanBodyPoseRequest` tracks the nose/neck plus shoulders, elbows, and wrists (hips/legs are ignored)

2. **Depth Score**: Combines elbow bend, shoulder-to-wrist distance, and head-to-hand proximity into a smoothed 0…1 “how low are you” score

3. **Dropout Tolerance**: When the chest fills the camera at the bottom and Vision briefly loses joints, the detector holds the down state instead of failing

4. **Pushup Recognition**:
   - **Down**: depth crosses the low threshold (sets a “reached bottom” flag)
   - **Up**: depth crosses the high threshold
   - **Rep counted**: after a bottom has been reached, the next up counts — even if frames pass through neutral or briefly lose the pose

### Architecture

```
PushupAlarmApp.swift      - App entry point, notification permissions
ContentView.swift          - Main UI with alarm scheduling
AlarmManager.swift         - Handles alarm scheduling, notifications, audio
PushupDetector.swift       - Vision-based pose detection & counting logic
CameraView.swift           - AVFoundation camera setup & video feed
AlarmChallengeView.swift   - Fullscreen pushup challenge UI
```

## Troubleshooting

### Camera Not Working

- Make sure you're testing on a **physical device** (not simulator)
- Check that camera permissions are granted:
  - Settings > Privacy & Security > Camera > PushupAlarm (should be ON)

### Alarm Not Triggering

- Ensure notifications are enabled:
  - Settings > Notifications > PushupAlarm
  - Allow Notifications should be ON
- Make sure the alarm time is in the future
- Check that the app has permission to play sounds

### Pushups Not Being Counted

- **Lighting**: Ensure good lighting so the camera can see you clearly
- **Framing**: Place the phone on the floor so your head and arms are in frame (legs optional)
- **Angle**: Face the front camera; keep both wrists visible if you can
- **Form**: Go through a clear down and up — bent elbows, then full extension
- **Speed**: Don't rush - give the detector time to register each position

### Build Errors in Xcode

- Make sure you're using **Xcode 15+** and targeting **iOS 17+**
- Clean build folder: Product > Clean Build Folder (Cmd + Shift + K)
- Delete derived data: Xcode > Preferences > Locations > Derived Data > Delete
- Restart Xcode

## Customization Ideas

Want to modify the app? Here are some ideas:

- **Change rep count**: Edit `requiredPushups` in `AlarmChallengeView.swift`
- **Different exercises**: Modify angle thresholds in `PushupDetector.swift` for squats, jumping jacks, etc.
- **Snooze feature**: Add a "5 more pushups for 5 min snooze" button
- **Recurring alarms**: Modify `AlarmManager` to support daily repeating alarms
- **Difficulty levels**: Add settings for 5, 10, 15, or 20 pushups
- **Stats tracking**: Save completed workouts to show weekly totals

## Privacy & Permissions

- **Camera**: Used only for real-time pushup detection, no images/videos are saved
- **Notifications**: Required to trigger the alarm
- All processing happens on-device, no data is sent to servers

## Known Limitations

- App must be installed on device (can't run from background without being installed)
- Camera must see your head and at least one full arm (shoulder → elbow → wrist)
- Works best with good lighting conditions
- Front camera is used (mirrored view)
- Only portrait orientation supported

## Credits

Built using:
- **SwiftUI** - Modern declarative UI framework
- **Vision Framework** - Apple's machine learning-based body pose detection
- **AVFoundation** - Camera access and video processing
- **UserNotifications** - Alarm scheduling and notifications

## License

Free to use and modify for personal use. Have fun and stay fit! 💪

---

**Questions or Issues?**

This is a standalone project with no ongoing support, but the code is well-commented. Check the inline comments in each Swift file for implementation details.
