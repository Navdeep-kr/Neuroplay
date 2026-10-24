export const SITE_CONFIG = {
  name: "NEUROPLAY",
  tagline: "Purpose-Built Brain Training for Mental Agility",
  description:
    "NEUROPLAY delivers structured cognitive training exercises, transparent adaptive difficulty, and comprehensive performance insights — engineered with clinical integrity and zero hype.",
  url: process.env.NEXT_PUBLIC_SITE_URL || "https://neuroplay.app",
  appUrl: process.env.NEXT_PUBLIC_APP_URL || "http://127.0.0.1:8080",
  links: {
    github: "https://github.com/neuroplay",
    supportEmail: "support@neuroplay.app",
    privacyEmail: "privacy@neuroplay.app",
  },
};

export interface GameInfo {
  id: string;
  title: string;
  faculty: "Memory" | "Flexibility" | "Attention" | "Problem Solving" | "Calculation" | "Language";
  facultyColor: string;
  summary: string;
  mechanics: string;
  scoring: string;
  accessibility: string;
  version: string;
}

export const GAMES_DATA: GameInfo[] = [
  {
    id: "memory-matrix",
    title: "Memory Matrix",
    faculty: "Memory",
    facultyColor: "from-blue-500 to-indigo-600",
    summary: "Reproduce briefly presented spatial tile patterns under escalating grid sizes.",
    mechanics: "A grid displays an illuminated pattern for 2.5 seconds. Replicate the highlighted tiles accurately without mistapping distractor positions.",
    scoring: "Score combines pattern completion percentage, speed-to-first-tile, and mistake penalties across 10 progressive rounds.",
    accessibility: "High-contrast border outlines, dual pattern identification markers (symbols inside tiles), keyboard grid navigation with arrow and number keys.",
    version: "1.0.0",
  },
  {
    id: "reflex-forge",
    title: "Reflex Forge",
    faculty: "Flexibility",
    facultyColor: "from-emerald-500 to-teal-600",
    summary: "Match evolving visual symbols against rapid contextual rule shifts.",
    mechanics: "Incoming symbols must be classified based on either shape or color, with rule switches indicated by unambiguous cues.",
    scoring: "Evaluates rapid cognitive switching latency, accuracy under time pressure, and rule compliance consistency.",
    accessibility: "Non-color-only matching (tactile icon glyphs alongside color fills), reduced-motion mode with non-flashing rule indicators, Left/Right arrow key shortcuts.",
    version: "1.0.0",
  },
  {
    id: "focus-reactor",
    title: "Focus Reactor",
    faculty: "Attention",
    facultyColor: "from-amber-500 to-orange-600",
    summary: "Identify fleeting target stimuli amongst high-salience visual distractors.",
    mechanics: "Scan dynamic fields to tap validated target items while suppressing impulses to respond to visually similar distractors.",
    scoring: "Measures d-prime visual sensitivity, false alarm rate, and sustained attentional vigilance over continuous 60-second trials.",
    accessibility: "Configurable distractor density, distinct geometric silhouettes, Spacebar and mouse/touch trigger support, complete motion stabilization.",
    version: "1.0.0",
  },
  {
    id: "logic-labyrinth",
    title: "Logic Labyrinth",
    faculty: "Problem Solving",
    facultyColor: "from-purple-500 to-violet-600",
    summary: "Formulate optimal traversal paths through topological constraint mazes.",
    mechanics: "Navigate from start to destination satisfying sequential gate keys, directional locks, and bounded step budgets.",
    scoring: "Scored by path optimality relative to the mathematical shortest validated path, reasoning deliberation time, and backtrack minimization.",
    accessibility: "Full directional keyboard control (Arrow keys or WASD), route preview breadcrumbs, high contrast node markers, no countdown timers in practice mode.",
    version: "1.0.0",
  },
  {
    id: "number-pulse",
    title: "Number Pulse",
    faculty: "Calculation",
    facultyColor: "from-cyan-500 to-blue-600",
    summary: "Solve mental arithmetic chains and infer progression laws in numerical sequences.",
    mechanics: "Solve multi-step computational chains with localized numeral formats and deduce arithmetic rules under bounded intervals.",
    scoring: "Calculated from arithmetic speed, multi-operand complexity rating, and sequence interpolation accuracy.",
    accessibility: "Localized number formatting, on-screen numpad or physical numeric keyboard input, generous timeout tolerances, clear audio confirmation chimes.",
    version: "1.0.0",
  },
  {
    id: "word-weaver",
    title: "Word Weaver",
    faculty: "Language",
    facultyColor: "from-rose-500 to-pink-600",
    summary: "Construct linguistic associations and solve lexical anagram challenges.",
    mechanics: "Form valid lexical chains using curated, versioned open vocabulary databases while evaluating semantic similarity.",
    scoring: "Weighted by word length, semantic relationship distance, vocabulary breadth, and anagram resolution speed.",
    accessibility: "Readable sans-serif letter tiles, full physical typing support with automatic backspace handling, screen reader aria-labels on all letters.",
    version: "1.0.0",
  },
];

export const FAQ_ITEMS = [
  {
    question: "Does NEUROPLAY claim to raise IQ or cure cognitive conditions?",
    answer:
      "No. NEUROPLAY is transparent about its scientific scope. Our exercises are structured cognitive games designed to challenge memory, attention, executive control, problem-solving, calculation, and verbal fluency. We strictly refrain from making unsupported claims about increasing general intelligence (IQ), preventing dementia, or diagnosing medical conditions.",
  },
  {
    question: "Can I play NEUROPLAY without creating an account?",
    answer:
      "Yes. We offer a full guest experience right in your browser or mobile app. Guest sessions persist locally on your device without transmitting personal identifiers. You can upgrade to a synced account at any point to back up your progress across devices.",
  },
  {
    question: "How does the transparent adaptive difficulty work?",
    answer:
      "Unlike opaque algorithms, NEUROPLAY difficulty adjustments are bounded, deterministic, and documented. Each game evaluates recent valid accuracy and median response latencies using exponential smoothing. Adjustments are capped to prevent erratic jumps from a single poor trial, and the exact algorithm version and adjustment reason are saved with each session result.",
  },
  {
    question: "What is your data privacy and retention policy?",
    answer:
      "We believe you own your cognitive telemetry. We do not sell user data or include third-party advertising trackers. You can export your complete training history, XP events, and preferences in standard JSON format at any time directly from the settings screen, or request permanent deletion with a single click.",
  },
  {
    question: "What platforms are supported?",
    answer:
      "NEUROPLAY is accessible as a modern progressive web application across modern browsers (Chrome, Edge, Firefox, Safari) and as native mobile applications for iOS and Android.",
  },
  {
    question: "How are streaks calculated?",
    answer:
      "We operate under an honest, zero-manipulation streak policy. Streaks reflect consecutive UTC calendar days with completed cognitive sessions. We do not use deceptive 'freeze' tokens, manipulative push notifications, or artificial continuity across missed days.",
  },
];

export const NAV_LINKS = [
  { label: "Games", href: "/games" },
  { label: "How It Works", href: "/how-it-works" },
  { label: "Accessibility", href: "/accessibility" },
  { label: "About", href: "/about" },
  { label: "FAQ", href: "/faq" },
  { label: "Contact", href: "/contact" },
];
