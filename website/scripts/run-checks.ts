import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, "..");

console.log("==================================================");
console.log("  NEUROPLAY Marketing Website Automated Test Suite");
console.log("==================================================");

let passed = 0;
let failed = 0;

function test(name: string, fn: () => void) {
  try {
    fn();
    console.log(`  [PASS] ${name}`);
    passed++;
  } catch (err: any) {
    console.error(`  [FAIL] ${name}: ${err.message}`);
    failed++;
  }
}

// 1. Verify all expected public pages and admin files exist
test("All required marketing & admin page files exist", () => {
  const requiredFiles = [
    "src/app/page.tsx",
    "src/app/games/page.tsx",
    "src/app/how-it-works/page.tsx",
    "src/app/accessibility/page.tsx",
    "src/app/about/page.tsx",
    "src/app/faq/page.tsx",
    "src/app/contact/page.tsx",
    "src/app/privacy/page.tsx",
    "src/app/terms/page.tsx",
    "src/app/subscription-disclosures/page.tsx",
    "src/app/not-found.tsx",
    "src/app/error.tsx",
    "src/app/sitemap.ts",
    "src/app/robots.ts",
    "src/app/admin/page.tsx",
    "src/app/admin/login/page.tsx",
    "src/app/api/admin/login/route.ts",
    "src/app/api/admin/logout/route.ts",
  ];

  for (const file of requiredFiles) {
    const fullPath = path.join(ROOT, file);
    assert.ok(fs.existsSync(fullPath), `Expected file to exist: ${file}`);
  }
});

// 2. Verify all six games are documented in constants and pages
test("Game library contains all 6 original cognitive exercises", () => {
  const constantsPath = path.join(ROOT, "src/lib/constants.ts");
  const content = fs.readFileSync(constantsPath, "utf-8");

  const expectedGames = [
    "memory-matrix",
    "reflex-forge",
    "focus-reactor",
    "logic-labyrinth",
    "number-pulse",
    "word-weaver",
  ];

  for (const gameId of expectedGames) {
    assert.ok(content.includes(gameId), `Game ID missing from constants: ${gameId}`);
  }
});

// 3. Verify Sitemap & Robots.txt rules
test("Sitemap and Robots.txt disallow admin and expose public routes", () => {
  const robotsPath = path.join(ROOT, "src/app/robots.ts");
  const robotsContent = fs.readFileSync(robotsPath, "utf-8");
  assert.ok(robotsContent.includes('disallow: ["/admin/", "/api/"]'), "Robots must disallow /admin/ and /api/");
  assert.ok(robotsContent.includes("sitemap.xml"), "Robots must reference sitemap.xml");

  const sitemapPath = path.join(ROOT, "src/app/sitemap.ts");
  const sitemapContent = fs.readFileSync(sitemapPath, "utf-8");
  const expectedRoutes = [
    '""',
    '"/games"',
    '"/how-it-works"',
    '"/accessibility"',
    '"/about"',
    '"/faq"',
    '"/contact"',
    '"/privacy"',
    '"/terms"',
    '"/subscription-disclosures"',
  ];

  for (const route of expectedRoutes) {
    assert.ok(sitemapContent.includes(route), `Sitemap must include route: ${route}`);
  }
});

// 4. Verify Server-Side Admin Authentication Enforcement
test("Admin page enforces server-side cookie verification before render", () => {
  const adminPagePath = path.join(ROOT, "src/app/admin/page.tsx");
  const content = fs.readFileSync(adminPagePath, "utf-8");

  assert.ok(content.includes('cookies()'), "Admin page must read server cookies");
  assert.ok(content.includes("neuroplay_admin_session"), "Admin page must check admin session cookie");
  assert.ok(content.includes('redirect("/admin/login")'), "Admin page must redirect unauthenticated visitors");
});

// 5. Verify Accessibility standards in Header and Interactive components
test("Accessible navigation, skip link, and ARIA attributes are implemented", () => {
  const headerPath = path.join(ROOT, "src/components/Header.tsx");
  const headerContent = fs.readFileSync(headerPath, "utf-8");

  assert.ok(headerContent.includes('href="#main-content"'), "Header must provide skip-to-content anchor");
  assert.ok(headerContent.includes('aria-label="Main Navigation"'), "Navigation must provide aria-label");
  assert.ok(headerContent.includes("aria-expanded"), "Mobile toggle must reflect aria-expanded");

  const faqPath = path.join(ROOT, "src/app/faq/page.tsx");
  const faqContent = fs.readFileSync(faqPath, "utf-8");
  assert.ok(faqContent.includes("aria-expanded"), "FAQ accordion must include aria-expanded");
  assert.ok(faqContent.includes("aria-controls"), "FAQ accordion must link answer via aria-controls");
});

// 6. Verify Scientific Scope & Non-Medical Claims Disclaimers
test("Copy maintains clinical integrity and avoids unverified medical claims", () => {
  const filesToScan = [
    "src/app/page.tsx",
    "src/app/games/page.tsx",
    "src/app/how-it-works/page.tsx",
    "src/components/Footer.tsx",
    "src/app/about/page.tsx",
  ];

  const prohibitedPhrases = [
    "cures dementia",
    "prevents alzheimer",
    "guaranteed iq boost",
    "raises your iq by",
    "clinical diagnosis of",
  ];

  for (const relPath of filesToScan) {
    const fullPath = path.join(ROOT, relPath);
    const content = fs.readFileSync(fullPath, "utf-8").toLowerCase();

    for (const phrase of prohibitedPhrases) {
      assert.ok(!content.includes(phrase), `Prohibited marketing claim found in ${relPath}: "${phrase}"`);
    }

    assert.ok(
      content.includes("not a medical") ||
      content.includes("does not diagnose") ||
      content.includes("scientific scope") ||
      content.includes("clinical integrity"),
      `Missing explicit non-medical disclaimer in ${relPath}`
    );
  }
});

// 7. Verify JSON-LD Structured Data
test("JSON-LD schemas for Organization, SoftwareApplication, and FAQPage are present", () => {
  const sdPath = path.join(ROOT, "src/components/StructuredData.tsx");
  const content = fs.readFileSync(sdPath, "utf-8");

  assert.ok(content.includes('"@type": "Organization"'), "Organization schema missing");
  assert.ok(content.includes('"@type": "SoftwareApplication"'), "SoftwareApplication schema missing");
  assert.ok(content.includes('"@type": "FAQPage"'), "FAQPage schema missing");
});

console.log("--------------------------------------------------");
console.log(`Results: ${passed} passed, ${failed} failed`);
console.log("==================================================");

if (failed > 0) {
  process.exit(1);
}
