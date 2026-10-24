import { NextResponse } from "next/server";
import { cookies } from "next/headers";

const ADMIN_SECRET = process.env.ADMIN_ACCESS_SECRET || "neuroplay-admin-2026";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { passkey } = body;

    if (!passkey || passkey !== ADMIN_SECRET) {
      return NextResponse.json(
        { error: "Invalid admin authentication passkey." },
        { status: 401 }
      );
    }

    // Set secure server-side session cookie
    const cookieStore = await cookies();
    cookieStore.set("neuroplay_admin_session", "authenticated", {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      path: "/",
      maxAge: 60 * 60 * 4, // 4 hours
    });

    return NextResponse.json({ success: true, message: "Admin access granted." });
  } catch {
    return NextResponse.json(
      { error: "Malformed authentication request." },
      { status: 400 }
    );
  }
}
