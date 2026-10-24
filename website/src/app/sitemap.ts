import { MetadataRoute } from "next";
import { SITE_CONFIG } from "@/lib/constants";

export default function sitemap(): MetadataRoute.Sitemap {
  const routes = [
    "",
    "/games",
    "/how-it-works",
    "/accessibility",
    "/about",
    "/faq",
    "/contact",
    "/privacy",
    "/terms",
    "/subscription-disclosures",
  ];

  const now = new Date("2026-10-24T00:00:00.000Z");

  return routes.map((route) => ({
    url: `${SITE_CONFIG.url}${route}`,
    lastModified: now,
    changeFrequency: route === "" || route === "/games" ? "daily" : "weekly",
    priority: route === "" ? 1.0 : route === "/games" || route === "/how-it-works" ? 0.8 : 0.6,
  }));
}
