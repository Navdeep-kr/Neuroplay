# NEUROPLAY

## Project Overview
NEUROPLAY is a cross-platform brain-training platform delivering scientifically grounded cognitive exercises across Flutter Web, Android, and iOS, with a Next.js marketing website.

## Tech Stack

| Layer | Technology | Version Constraint |
|-------|-----------|-------------------|
| App Framework | Flutter (Dart) | Stable channel ≥ 3.27 |
| State Management | Riverpod | ^2.6.x |
| Navigation | GoRouter | ^14.x |
| Auth & Database | Supabase (Auth + PostgreSQL) | supabase_flutter ^2.x |
| Server Functions | Supabase Edge Functions (Deno) | — |
| Marketing Site | Next.js (TypeScript) | ^15.x |
| CI/CD | GitHub Actions | — |
| Package Manager (Dart) | pub | Built-in |
| Package Manager (Node) | pnpm | ^10.x |

## Repository Structure

```
neuroplay/
├── app/                          # Flutter application (monorepo root)
│   ├── lib/
│   │   ├── main.dart             # App entry point
│   │   ├── app/                  # App-level config (router, theme, providers)
│   │   ├── features/             # Feature modules (auth, home, games, profile, onboarding)
│   │   │   └── <feature>/
│   │   │       ├── data/         # Repositories, DTOs, data sources
│   │   │       ├── domain/       # Entities, value objects, interfaces
│   │   │       └── presentation/ # Screens, widgets, view models (providers)
│   │   ├── core/                 # Shared utilities, constants, extensions
│   │   └── l10n/                 # Localizations
│   ├── test/                     # Unit and widget tests
│   ├── integration_test/         # Integration tests
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   └── .env.example
├── supabase/                     # Supabase project config
│   ├── config.toml
│   ├── migrations/               # SQL migration files
│   ├── functions/                # Edge Functions (Deno/TypeScript)
│   │   └── <function-name>/
│   │       └── index.ts
│   └── seed.sql
├── website/                      # Next.js marketing site
│   ├── src/
│   │   ├── app/                  # App Router pages
│   │   ├── components/           # React components
│   │   └── lib/                  # Utilities
│   ├── public/
│   ├── package.json
│   ├── tsconfig.json
│   ├── next.config.ts
│   └── .env.example
├── .github/
│   └── workflows/
│       ├── flutter-ci.yml        # Flutter lint, test, build
│       └── website-ci.yml        # Next.js lint, test, build
├── docs/
│   ├── architecture.md
│   ├── security.md
│   └── implementation-plan.md
├── .gitignore
├── .env.example
├── LICENSE
└── README.md
```

## Prerequisites

Before you begin, ensure you have the following installed:

| Tool | Minimum Version | Installation |
|------|----------------|-------------|
| Flutter SDK | 3.27+ (stable) | [flutter.dev/get-started](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.6+ | Bundled with Flutter |
| Node.js | 22 LTS+ | [nodejs.org](https://nodejs.org/) |
| pnpm | 10.x | `npm install -g pnpm` |
| Git | 2.x | [git-scm.com](https://git-scm.com/) |
| Supabase CLI | 2.x | `npx supabase` or [supabase.com/docs/guides/cli](https://supabase.com/docs/guides/cli) |
| Android Studio | Latest | For Android builds |
| Xcode | 16+ | For iOS builds (macOS only) |

## Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/<org>/neuroplay.git
cd neuroplay
```

### 2. Environment setup
```bash
# Copy environment templates
cp .env.example .env
cp app/.env.example app/.env
cp website/.env.example website/.env

# Fill in your Supabase project credentials in each .env file
```

### 3. Flutter app
```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run -d chrome       # Web
flutter run -d <device_id>  # Android/iOS
```

### 4. Marketing website
```bash
cd website
pnpm install
pnpm dev     # http://localhost:3000
pnpm build   # Production build
pnpm test    # Run tests
```

### 5. Supabase local development
```bash
npx supabase start          # Starts local Supabase stack (Docker required)
npx supabase db reset        # Apply migrations and seed data
npx supabase functions serve # Run Edge Functions locally
```

## Development Conventions

### Naming
- **Dart files**: `snake_case.dart`
- **Dart classes**: `PascalCase`
- **Dart variables/functions**: `camelCase`
- **Dart constants**: `camelCase` (per Dart convention)
- **TypeScript/JS files**: `kebab-case.ts` or `PascalCase.tsx` (React components)
- **Database tables**: `snake_case`
- **Database columns**: `snake_case`
- **Edge Functions**: `kebab-case` directory names
- **Environment variables**: `SCREAMING_SNAKE_CASE`
- **Git branches**: `<type>/<short-description>` (e.g., `feat/auth-flow`, `fix/score-calc`)

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
<type>(<scope>): <short summary>

Types: feat, fix, docs, style, refactor, test, chore, ci
Scopes: app, website, supabase, docs, ci
```

### Testing Requirements
- All business logic must have unit tests.
- All screens must have at least one widget test.
- Critical user flows require integration tests.
- Minimum 80% code coverage target for `lib/` (excluding generated code).
- Website: component tests with React Testing Library.

### Error Handling
- Use Dart `Result` pattern (sealed classes) for expected failures.
- Wrap all Supabase calls in try-catch with typed exceptions.
- Never expose raw error details in production UI.
- Log errors with structured data (timestamp, context, stack trace).
- Edge Functions return consistent JSON error shape: `{ "error": { "code": "...", "message": "..." } }`.

## CI/CD

GitHub Actions pipelines run on every push and pull request:
- **flutter-ci.yml**: `flutter analyze` → `flutter test` → `flutter build web`
- **website-ci.yml**: `pnpm lint` → `pnpm test` → `pnpm build`

## Documentation

- [Architecture](docs/architecture.md) — System design, data flow, and component boundaries.
- [Security](docs/security.md) — Auth model, RLS policies, secret management.
- [Implementation Plan](docs/implementation-plan.md) — Phased delivery milestones with acceptance criteria.

## License

MIT — see [LICENSE](LICENSE) for details.
