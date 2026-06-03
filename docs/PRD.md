# GRIT - Product Requirements Document (PRD)

## 1. Executive Summary
**GRIT** is a premium, high-fidelity fitness application engineered for serious lifters. Eschewing the bloated, social-media-style approach of typical fitness apps, GRIT focuses on minimal friction, maximum data density, and strict adherence to structured training paradigms in a purely local-first environment.

## 2. Objectives & Success Metrics (KPIs)
- **Primary Objective:** Provide an unbreakable, distraction-free environment for tracking progressive overload.
- **KPI 1 (Session Completion Rate):** Target >95% of initiated workouts marked as completed without abandonment.
- **KPI 2 (Timer Adherence):** Measure the percentage of rest timers allowed to expire naturally vs. skipped, indicating accurate rest tracking.
- **KPI 3 (Retention):** Weekly Active User (WAU) retention across 12-week macrocycles.

## 3. Target Audience
- **Primary:** Powerlifters, bodybuilders, and experienced gym-goers who require precise volume tracking and rest management.
- **Secondary:** Intermediate lifters transitioning from ad-hoc workouts to structured routines.

## 4. User Stories & Acceptance Criteria

### Epic: Active Workout Engine
**Story 1:** As a lifter, I want to start a workout exclusively from a predefined routine so that my volume is accurately tracked against my historical data.
- *Acceptance Criteria:* User cannot start a workout without a `routineId`. UI prevents backward navigation into an empty workout state.

**Story 2:** As a lifter, I want my rest timer adjustments to persist throughout the workout so that I don't have to manually change it after every set.
- *Acceptance Criteria:* Modifying the timer globally updates the provider state. Subsequent sets default to the new overridden value.

**Story 3:** As a lifter, I want to swiftly discard an exercise block using a tactile gesture so that I don't break my focus navigating menus.
- *Acceptance Criteria:* Implement a "Slide to Discard" interaction with haptic feedback. Deletion is instantaneous in the UI (optimistic update).

### Epic: Profile & Analytics
**Story 4:** As a lifter, I want to visualize my muscle volume balance so that I can identify lagging body parts.
- *Acceptance Criteria:* Display a dynamic Radar/Spider chart. Axis data must dynamically generate from the actual logged workouts. Exclude warmup sets.

## 5. Non-Functional Requirements
- **Performance:** App must render consistently at 60/120fps (device dependent). Zero UI thread blocking during database writes.
- **Environment:** UI must remain legible in high-luminance (harsh gym lighting) environments.
- **Offline First:** 100% of core functionality must operate without an active internet connection.

## 6. Out of Scope (V1)
- Social feeds and workout sharing.
- Guided video tutorials for exercises.
- Cloud synchronization and cross-device syncing (unless implemented via local file export/import).
