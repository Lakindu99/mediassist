# MediAssist — Project Guide for Claude Code

> Read this file fully at the start of every session. It defines what this
> project is, how it must be built, and the standards every change must meet.

---

## 1. Project Identity

- **App name:** MediAssist
- **Type:** Final-year undergraduate research project — BSc (Hons) Computer Science, University of Bedfordshire
- **Research title:** A Mobile-Based Medication and Appointment Reminder Application with an Adaptive User Interface to Reduce Cognitive Load among Elderly Users
- **Student:** Sachintha Lakindu Ekanayake (ID 2542027) — *learning developer, needs clear explanations*
- **Supervisor:** Ms. Nideshika Ellepola
- **Application ID:** `com.sachintha.mediassist`
- **Goal of the student:** First-class grade, Best Performance Award, and a National ICT Awards entry. Build to that standard.

---

## 2. Research Objective (the "why" behind every decision)

Investigate how **adaptive user-interface techniques reduce cognitive load and improve usability for elderly users** managing medication schedules and medical appointments.

Every UI, UX, and code decision must serve two priorities:
1. **Elderly usability** — simple, clear, forgiving, accessible.
2. **Cognitive-load reduction** — fewer steps, fewer choices per screen, less to remember.

If a proposed solution does not support these goals, it is the wrong solution.

---

## 3. ⭐ CRITICAL ARCHITECTURE RULE — One codebase, two modes

This is the most important rule in the project. **Do not violate it.**

- There is **ONE Flutter codebase**. A single boolean flag, `adaptiveMode`, switches the entire adaptive system on or off at runtime.
- **Static mode** (`adaptiveMode = false`) = a normal, fixed app. This is the experimental **control condition**.
- **Adaptive mode** (`adaptiveMode = true`) = the same app PLUS behaviour tracking, the Adaptive UI Engine, personalization, and lightweight ML.
- **Everything else — screens, data models, features, reminders, business logic — must be IDENTICAL between the two modes.** The *only* difference between Static and Adaptive is the adaptive layer.
- **Never** create duplicate screens or a second project for the two modes. Always gate adaptive behaviour behind the `adaptiveMode` flag.

**Reason:** The research compares Static vs Adaptive in a controlled experiment (NASA-TLX, task-completion time, error rate, 7 participants with personas). Keeping one codebase with a single toggle guarantees the only variable that changes is the adaptive layer — a clean, defensible experiment.

---

## 4. Technology Stack (do not substitute without asking the student)

- **Framework:** Flutter 3.44.x / Dart 3.x
- **State management:** **Provider** (chosen for simplicity and viva-defensibility; do NOT introduce Bloc/Riverpod unless the student asks)
- **Backend:** Firebase — **Authentication**, **Cloud Firestore**, **Cloud Messaging (FCM)**
- **Scheduled reminders:** `flutter_local_notifications` (medication/appointment alarms must fire at exact times, offline). FCM is only for caregiver push alerts.
- **Date/time:** `intl`, `timezone`
- **Charts (caregiver view / adaptive insights):** `fl_chart`
- **Lightweight ML (Phase 2 only):** a small **Decision Tree** — either simple thresholds hand-written in Dart, or trained offline in Python (scikit-learn) and ported as rules. Keep it genuinely lightweight.

---

## 5. System Architecture (5 layers — from the contextual report)

1. **User Layer** — Elderly User (primary), Caregiver (secondary)
2. **Presentation Layer** — Auth UI, Dashboard, Medication UI, Appointment UI, Reminder UI, Adaptive UI components
3. **Application Logic Layer** — Medication module, Appointment module, Reminder module, **Adaptive UI Engine**, **Personalization Engine**, Notification Controller
4. **Backend / Cloud Services** — Firebase Auth, Cloud Firestore, FCM
5. **Data Storage** — User data, Medication records, Appointment records, Reminder data, Adaptive-preference data

---

## 6. Folder Structure (feature-first — keep code organised here)

```
lib/
├── main.dart                 # app entry point
├── app.dart                  # root widget, theme, providers
├── core/
│   ├── theme/                # colours, text styles, adaptive theming
│   ├── constants/
│   ├── services/             # firebase, notifications, behaviour tracking
│   ├── widgets/              # reusable adaptive-aware widgets (AppButton, AppText)
│   └── adaptive/             # Adaptive UI Engine + ML (Phase 2)
├── features/
│   ├── auth/                 # register, login, profile
│   ├── dashboard/
│   ├── medication/           # add / edit / delete / view
│   ├── appointment/
│   ├── reminders/
│   ├── caregiver/
│   └── settings/             # accessibility settings
└── models/                   # Medication, Appointment, AppUser, etc.
```

---

## 7. Accessibility & Elderly-UX Standards (non-negotiable defaults)

These apply in BOTH modes. Adaptive mode enhances them dynamically; static mode keeps them at sensible fixed defaults.

- **Touch targets:** minimum 48×48 dp (larger in adaptive mode).
- **Font size:** large by default (≥ 18sp body text), scalable.
- **Contrast:** meet WCAG AA minimum; aim for AAA. High-contrast option in settings.
- **Navigation:** shallow and simple. Minimise steps and choices per screen.
- **Labels:** icon **plus** text. Plain language, no technical jargon.
- **Layout:** generous spacing, uncluttered, one primary action per screen where possible.
- **Safety:** confirmation dialogs for destructive actions (e.g. deleting a medication).
- **Feedback:** clear visual confirmation after every action.

---

## 8. Build Order (follow strictly — static first, then adaptive)

**Phase 1 — Static app (build and finish this first):**
Auth (register / login / logout / profile) → Dashboard → Medication CRUD → Appointment CRUD → Local scheduled reminders → Notifications (snooze, mark-as-taken) → Caregiver monitoring → static Accessibility settings.

**Phase 2 — Adaptive layer (only after Phase 1 is stable):**
Behaviour-tracking service → rule-based Adaptive UI Engine (font scaling, high contrast, simplified navigation, layout reprioritisation) → personalization & recommendations → lightweight Decision Tree on collected logs.

**Phase 3 — Evaluation support:**
Tools/screens to support the Static-vs-Adaptive study (task flows, optional logging export).

---

## 9. Behaviour Signals (adaptive mode silently logs these)

Hesitation frequency, task-completion time, error / mis-tap rate, font & contrast usage, navigation depth. These feed the rule-based engine and the Decision Tree.

---

## 10. Coding Conventions

- Write **clear, readable code** with comments that explain the *why* (the student must understand and defend every line in a viva — no black-box solutions).
- Build **small, reusable, adaptive-aware widgets** (e.g. `AppButton`, `AppText` that read `adaptiveMode` and user preferences) so adaptation is centralised, not scattered.
- Keep each feature in its own folder under `lib/features/`.
- **Never** commit secrets or Firebase config files containing keys (use `.gitignore`).
- Prefer the **simplest** solution that meets the research goal within undergraduate scope. Avoid over-engineering.

---

## 11. How to Work With the Student

- The student is **learning to code** — explain what each change does, in plain language, before or alongside the code.
- Move **one feature at a time**; confirm it runs before starting the next.
- The student must be able to **understand and defend** all work (academic integrity + viva). Teach, don't just deliver.
- Test device is a **physical Android tablet** (good for elderly-UX testing). No emulator.
