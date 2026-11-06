# Vidya Campus — School + Hostel Management

## Requirements
- Node.js 20+
- A Supabase project
- A Google Gemini API key (optional; required for the AI assistant)

## Local setup
1. Install dependencies: `npm install`
2. Copy `.env.example` to `.env.local` and fill in the Supabase URL, anon key, and Gemini API key.
3. For a new Supabase project, run `supabase/schema.sql` once in the SQL Editor. If the original schema was already applied, run `supabase/migrations/20261106_outpass_approval_scope.sql` instead.
4. Create a user through Supabase Auth. Promote the first administrator by running the commented SQL at the bottom of the schema with that user's email.
5. Start the app: `npm run dev`
6. Open http://localhost:3000.

## Deploy
Import this repository into Vercel and configure the same environment variables. Apply the Supabase schema before signing in.

## Notes
- Dashboard routes require an authenticated Supabase user.
- Row-level security is enabled on application tables. Parent and warden outpass approvals are restricted to their respective approval fields by a database trigger.
- Several dashboard modules are still placeholders marked “Coming soon”; this repository is not yet a complete school management system.
- Before production use, test the SQL policies with separate admin, teacher, student, parent, warden, and accountant accounts.
- Do not commit `.env.local` or service-role keys.
