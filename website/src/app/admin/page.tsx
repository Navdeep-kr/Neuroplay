import React from "react";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { AdminDashboardClient } from "./AdminDashboardClient";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Admin Console",
  robots: {
    index: false,
    follow: false,
  },
};

export default async function AdminPage() {
  const cookieStore = await cookies();
  const adminCookie = cookieStore.get("neuroplay_admin_session");

  // Server-side authentication enforcement
  if (!adminCookie || adminCookie.value !== "authenticated") {
    redirect("/admin/login");
  }

  return (
    <div className="py-12 md:py-16 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <AdminDashboardClient />
    </div>
  );
}
