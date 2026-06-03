# GRIT - Technical Flow & Logic

## 1. Active Workout Lifecycle
The following flowchart illustrates the strict, routine-bound state machine for an active session.

```mermaid
stateDiagram-v2
    [*] --> Dashboard
    Dashboard --> RoutineSelection : User navigates to Workout Tab
    RoutineSelection --> ActiveWorkout : User selects Routine (Routine ID validated)
    
    state ActiveWorkout {
        [*] --> Idle
        Idle --> LoggingSet : User inputs Weight & Reps
        LoggingSet --> RestTimerActive : Set marked Complete
        RestTimerActive --> BackgroundNotification : App Paused
        BackgroundNotification --> RestTimerActive : App Resumed
        RestTimerActive --> Idle : Timer Expires / User Skips
    }
    
    ActiveWorkout --> SessionSummary : User taps "Finish"
    SessionSummary --> Dashboard : Session persisted to DB
```

## 2. Rest Timer & Background Notification Sequence
Because Flutter execution pauses when the app is backgrounded, the timer logic relies on calculating time deltas and scheduling OS-level notifications.

```mermaid
sequenceDiagram
    actor User
    participant UI as Flutter UI
    participant Timer as TimerService
    participant OS as Local Notifications

    User->>UI: Completes Set
    UI->>Timer: startRest(duration)
    Timer-->>UI: Update Timer UI (Countdown)
    
    User->>UI: Backgrounds App
    UI->>Timer: OnPause Lifecycle Event
    Timer->>Timer: Record Timestamp.now()
    Timer->>OS: Schedule Notification (Timestamp.now() + remaining)
    
    OS-->>User: "Rest Complete" (Push Notification)
    
    User->>UI: Foreground App
    UI->>Timer: OnResume Lifecycle Event
    Timer->>OS: Cancel Pending Notifications
    Timer->>Timer: Calculate Elapsed (now - pauseTimestamp)
    Timer-->>UI: Resolve State (Expired or Update Countdown)
```

## 3. Muscle Volume Radar Chart Calculation Pipeline
Data flows from the local SQLite database to the chart UI via a highly optimized Riverpod provider.

```mermaid
graph TD
    A[User Adjusts Period Toggle: 4W/8W/12W] --> B[Invalidate muscleVolumeProvider]
    B --> C[Query SQLite: SELECT sets WHERE date >= Period AND is_warmup = 0]
    C --> D[Join EXERCISE_MUSCLE_TAGS]
    D --> E[Aggregate: SUM(weight * reps) GROUP BY muscle_name]
    E --> F[Convert to User Preferred Unit KG/LBS]
    F --> G[Sort DESC & Limit to Top 10 Muscles]
    G --> H[Calculate Axis Max: Round Up to nearest 1000]
    H --> I[Render fl_chart RadarChart]
```
