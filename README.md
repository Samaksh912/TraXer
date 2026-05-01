# TraXer 💰

A seamless, intelligent expense tracker built with Flutter. TraXer combines local-first performance with Supabase cloud sync to make financial tracking effortless and private.

![TraXer Banner](https://via.placeholder.com/1200x500.png?text=TraXer+App+Preview)
## ✨ Features

* **⚡ Zero-Lag Performance:** Built on **Isar Database**, offering instant read/write operations and full offline capability.
* **☁️ Secure Cloud Sync:** Powered by **Supabase Auth + Postgres + RLS**, with per-user data isolation.
* **🎨 Dynamic Gradient UI:** * Beautiful, glassmorphic dialogs for adding Income/Expenses.
    * Context-aware animations (Red for Expense, Green for Income).
    * Smooth "Sliding Bubble" tabs for transaction switching.
* **🌗 Adaptive Theming:** Full support for **Dark Mode** and **Light Mode** with carefully curated color palettes.
* **📊 Smart Categorization:** Dedicated categories for Income vs. Expenses with visual "Chips" for easy scanning.
* **🔍 Full-Text Search:** (In Progress) Instantly find transactions by title or category without network latency.
* **🗣️ Voice Integration:** (Coming Soon) Seamless voice-to-text entry for rapid logging.

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Local Database:** [Isar](https://isar.dev/) (NoSQL, ACID compliant, highly optimized for mobile)
* **Cloud Backend:** [Supabase](https://supabase.com/) (Auth + Postgres + Row Level Security)
* **State Management:** `setState` & `ValueNotifier` (Clean architecture)
* **UI Components:** Custom animated widgets, `GoogleFonts`, `Intl`.

## 📸 Screenshots

| Home Dashboard | Add Expense (Dark) | Add Income (Light) |
|:---:|:---:|:---:|
| ![Home](https://via.placeholder.com/300x600?text=Home+Screen) | ![Add Dark](https://via.placeholder.com/300x600?text=Dialog+Dark) | ![Add Light](https://via.placeholder.com/300x600?text=Dialog+Light) |
## 🚀 Getting Started

### Prerequisites
* Flutter SDK (Latest Stable)
* Android Studio / VS Code
* Android Emulator or Physical Device

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/yourusername/traxer.git](https://github.com/yourusername/traxer.git)
    cd traxer
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate Isar Code:**
    This project uses Isar code generation. Run this command to generate the database schema:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4. **Create your local `.env` file:**
   Copy the example file and fill in your Supabase values.
   ```bash
   cp .env.example .env
   ```

   Then set:
   ```env
   SUPABASE_URL=YOUR_SUPABASE_URL
   SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```

5. **Provision Supabase schema:**
   Apply the SQL in `supabase/migrations/20260423_001_initial_traxer_schema.sql` to your Supabase project (SQL Editor or CLI).

6. **Run the app:**
    ```bash
    flutter run
    ```