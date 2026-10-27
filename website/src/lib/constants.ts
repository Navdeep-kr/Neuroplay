export const SITE_CONFIG = {
  name: "NEUROPLAY",
  tagline: "Purpose-Built Brain Training for Mental Agility",
  description:
    "NEUROPLAY delivers structured cognitive training exercises, transparent adaptive difficulty, and comprehensive performance insights — engineered with clinical integrity and zero hype.",
  url: process.env.NEXT_PUBLIC_SITE_URL || "https://neuroplay.app",
  appUrl: process.env.NEXT_PUBLIC_APP_URL || "/app/index.html",
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
  {
    id: "echo-sequence",
    title: "Echo Sequence",
    faculty: "Memory",
    facultyColor: "from-blue-500 to-indigo-600",
    summary: "Recall positional and auditory stimuli presented N steps previously in continuous streams.",
    mechanics: "A grid flashes positions in rhythmic sequence. Press Match whenever the current stimulus matches the one shown N steps back.",
    scoring: "Measures N-back working memory load, true positive detection rate, and response latency.",
    accessibility: "Dual visual and auditory markers, high contrast square indicators, spacebar and keyboard shortcut bindings.",
    version: "1.0.0",
  },
  {
    id: "constellation-recall",
    title: "Constellation Recall",
    faculty: "Memory",
    facultyColor: "from-blue-500 to-indigo-600",
    summary: "Memorize celestial star configurations and identify relocated or missing coordinates.",
    mechanics: "Observe glowing star nodes on a celestial grid for 3 seconds. After brief masking, tap the exact star that shifted location.",
    scoring: "Calculated from spatial memory precision, retention fidelity, and rapid recognition response.",
    accessibility: "Distinct star shapes (diamond, cross, star, ring), large touch zones, screen reader support.",
    version: "1.0.0",
  },
  {
    id: "trailblazer",
    title: "Trailblazer",
    faculty: "Flexibility",
    facultyColor: "from-emerald-500 to-teal-600",
    summary: "Connect alternating number and letter nodes in rapid executive sequence against the clock.",
    mechanics: "Tap scattered nodes alternating between sequential numerals and letters (1 -> A -> 2 -> B -> 3 -> C) without breaking the chain.",
    scoring: "Based on sequence completion speed, trail accuracy, and cognitive switching cost latency.",
    accessibility: "Enlarged targets with clear numerical and alphabetical tags, high contrast connecting vectors, keyboard navigation.",
    version: "1.0.0",
  },
  {
    id: "prism-shift",
    title: "Prism Shift",
    faculty: "Flexibility",
    facultyColor: "from-emerald-500 to-teal-600",
    summary: "Resolve ink color versus semantic text conflict under dynamically shifting rules.",
    mechanics: "Words appear in contrasting colored inks. Dynamically respond to either the word text or ink color as rules toggle.",
    scoring: "Computes Stroop interference resistance, decision latency, and inhibitory control accuracy under time pressure.",
    accessibility: "Symbolic color icons (triangle=red, square=blue, circle=green, diamond=yellow), high-contrast borders, 1-4 number keys.",
    version: "1.0.0",
  },
  {
    id: "tracker-horizon",
    title: "Tracker Horizon",
    faculty: "Attention",
    facultyColor: "from-amber-500 to-orange-600",
    summary: "Track multiple moving targets across dynamic trajectories simultaneously.",
    mechanics: "Track designated highlighted spheres among identical distractors as they smoothly glide and bounce across the field.",
    scoring: "Measures multi-object tracking capacity, tracking fidelity under speed, and spatial distribution accuracy.",
    accessibility: "Customizable speed profiles, distinct target trail glow, high-contrast borders, tactile tap confirmation.",
    version: "1.0.0",
  },
  {
    id: "flanker-strike",
    title: "Flanker Strike",
    faculty: "Attention",
    facultyColor: "from-amber-500 to-orange-600",
    summary: "Identify target direction while suppressing conflicting directional distractors.",
    mechanics: "A row of 5 arrows flashes rapidly. Respond to the center arrow's orientation while ignoring surrounding flanking arrows.",
    scoring: "Measures perceptual filtering speed, congruency interference effect, and selective spatial attention.",
    accessibility: "Arrow keys (Left / Right) and on-screen tactile pads, distinct color-shape cues, reduced-motion mode.",
    version: "1.0.0",
  },
  {
    id: "scale-balance",
    title: "Scale Balance",
    faculty: "Calculation",
    facultyColor: "from-fuchsia-500 to-purple-600",
    summary: "Compare numerical magnitudes and rapid mental arithmetic expressions on a balance scale.",
    mechanics: "Evaluate arithmetic expressions on balance pans to determine which side holds greater value or if both balance equally.",
    scoring: "Evaluates mathematical estimation speed, arithmetic accuracy, and magnitude discrimination under time constraints.",
    accessibility: "Large tactile buttons (Left, Equal, Right), arrow key bindings, non-flashing animations.",
    version: "1.0.0",
  },
  {
    id: "flow-math",
    title: "Flow Math",
    faculty: "Calculation",
    facultyColor: "from-fuchsia-500 to-purple-600",
    summary: "Deduce missing operators and solve rapid mental arithmetic equations.",
    mechanics: "Fill in missing operations (+, -, *, /) and numerical slots to complete simultaneous horizontal equations before timer expiry.",
    scoring: "Scored by calculation speed, constraint satisfaction efficiency, and multi-step operator complexity.",
    accessibility: "On-screen keypad, physical keyboard operator inputs (+, -, *, /), high contrast typography.",
    version: "1.0.0",
  },
  {
    id: "origami-unfold",
    title: "Origami Unfold",
    faculty: "Problem Solving",
    facultyColor: "from-indigo-500 to-blue-600",
    summary: "Mentally unfold geometric paper sheets to predict punched hole locations.",
    mechanics: "Analyze a sheet folded sequentially with punch marks. Select the correct unfolded pattern among alternatives.",
    scoring: "Assesses mental spatial folding speed, dimensional rotation accuracy, and symmetry reasoning.",
    accessibility: "Numbered fold sequence indicators, step-by-step visual unfolds in practice mode, high-contrast grid lines.",
    version: "1.0.0",
  },
  {
    id: "tower-of-chronos",
    title: "Tower of Chronos",
    faculty: "Problem Solving",
    facultyColor: "from-indigo-500 to-blue-600",
    summary: "Plan sequential disc movements to achieve target tower configurations in minimum moves.",
    mechanics: "Transfer graduated discs across three pegs to match a target goal state without placing larger discs on smaller ones.",
    scoring: "Measures lookahead planning depth, move efficiency relative to optimal solutions, and execution speed.",
    accessibility: "Tap-to-select peg mechanics, numeric keyboard shortcuts (1, 2, 3), clear disc size identifiers.",
    version: "1.0.0",
  },
  {
    id: "semantic-bridge",
    title: "Semantic Bridge",
    faculty: "Language",
    facultyColor: "from-teal-500 to-emerald-600",
    summary: "Discover the unifying fourth word that connects three seemingly disparate cues.",
    mechanics: "Inspect three prompt words (e.g., Swiss, Cottage, Cake) and identify the shared compound or associative link (Cheese).",
    scoring: "Evaluates semantic network retrieval, remote association breadth, and lexical retrieval latency.",
    accessibility: "Letter-tile reveal hints, physical keyboard typing, large readable text with syllable spacing.",
    version: "1.0.0",
  },
  {
    id: "word-rapids",
    title: "Word Rapids",
    faculty: "Language",
    facultyColor: "from-teal-500 to-emerald-600",
    summary: "Form valid lexical terms from a continuous stream of incoming letters.",
    mechanics: "Tap letter tiles across scrolling streams to construct 3-to-7 letter valid words before tiles reach the lower boundary.",
    scoring: "Scored by word length, lexical frequency rarity, vocabulary throughput, and bonus letter combinations.",
    accessibility: "Generous flow speeds, backspace and shuffle controls, high contrast sans-serif letter tiles.",
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
