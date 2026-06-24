# Seenly Admin App Implementation Plan

## 1. Purpose

Build a secure Flutter-based admin application for the Seenly platform that allows authorized staff to review pending accounts, approve or reject users, and track moderation activity without exposing admin logic inside the consumer app.

This plan assumes the admin app will be maintained as a separate Flutter project so it can ship independently, stay operationally isolated, and evolve without increasing risk in the main app.

---

## 2. Product Goals

### Primary goals
- Give admins a fast, reliable workflow for reviewing pending influencer and business accounts.
- Ensure only authorized admins can access moderation actions.
- Keep all approval and rejection actions auditable.
- Support responsive layouts for desktop and tablet, with mobile usability as a secondary goal.

### Non-goals for V1
- Full customer support tooling.
- Analytics dashboards.
- In-app chat or notes between moderators.
- Bulk moderation actions.
- Advanced role hierarchies beyond basic admin access.

---

## 3. Recommended V1 Scope

### Included in V1
- Admin authentication
- Admin authorization gate
- Pending account review queue
- Search and filter for pending users
- Account detail view for influencers and businesses
- Approve and reject actions
- Rejection reason capture
- Audit history
- Basic error handling and retry states

### Deferred to V2
- Multi-role permissions such as reviewer, manager, super admin
- Email or push notification workflows on rejection
- Bulk actions
- Internal notes on profiles
- Metrics and reporting
- File/document verification uploads

---

## 4. Platform Strategy

### Recommendation
Prioritize Flutter Web plus tablet/desktop-responsive layouts first.

### Why
- Admin tools usually benefit more from larger screens and dense data layouts.
- Web deployment reduces friction for internal staff.
- Flutter still gives a path to mobile builds later if needed.

### Optional follow-up
If internal users later need moderation on the go, we can harden the same codebase for mobile with responsive layout adjustments rather than building a separate admin experience.

---

## 5. Architecture Decision

### App structure
The admin app should live in its own Flutter project, for example:

```text
seenly_admin_flutter/
|-- lib/
|   |-- app/
|   |   |-- router/
|   |   |-- theme/
|   |   `-- bootstrap/
|   |-- core/
|   |   |-- config/
|   |   |-- constants/
|   |   |-- error/
|   |   `-- utils/
|   |-- features/
|   |   |-- auth/
|   |   |-- moderation/
|   |   `-- audit_log/
|   |-- shared/
|   |   |-- widgets/
|   |   |-- models/
|   |   `-- services/
|   `-- main.dart
|-- test/
|-- pubspec.yaml
`-- .env
```

### Architectural principles
- Keep feature areas separated by domain.
- Centralize Supabase access behind services/repositories.
- Avoid putting query logic directly into UI widgets.
- Keep shared models small and specific to admin use cases.
- Prefer explicit loading, empty, success, and error states.

---

## 6. Backend & Security Requirements

This is the most important part of the project. The admin client must not rely on client-side checks alone.

### Required backend controls
- Only authenticated admins may fetch pending profiles.
- Only authenticated admins may approve or reject users.
- Every moderation action should write an audit log entry.
- Standard users must be blocked both in the UI and at the database layer.

### Admin identity model

Two acceptable options:

1. Quickest path for V1: `profiles.is_admin BOOLEAN`
2. Better long-term path: `profiles.role` or a dedicated admin role model

### Recommendation
Use `is_admin` for speed only if the backend is still simple. If Seenly expects more internal tooling later, move directly to a role-based field such as `role = admin`.

### Additional backend work recommended
- Add an `admin_audit_logs` table.
- Use `SECURITY DEFINER` RPC functions for moderation actions.
- Restrict direct table updates from the client where possible.
- Review Row Level Security policies to ensure pending user data is not exposed broadly.
- Validate allowed status transitions on the server, not just in Flutter.

---

## 7. Data Model Expectations

### Profiles data needed by the admin app
- `id`
- `email`
- `full_name`
- `username`
- `account_type` such as influencer or business
- `status` such as pending, active, rejected
- `is_admin` or `role`
- `created_at`
- `avatar_url`
- `bio`
- `instagram_handle`
- `tiktok_handle`
- `website`
- `follower_count` if available

### Audit log data
- `id`
- `admin_user_id`
- `target_user_id`
- `action` such as approved or rejected
- `reason`
- `created_at`

---

## 8. User Flows

### Flow 1: Admin login
1. Admin opens the app.
2. Admin signs in.
3. App checks the authenticated user profile.
4. If user is not an admin, app signs them out and shows an unauthorized message.
5. If user is an admin, app routes to the dashboard.

### Flow 2: Review pending user
1. Admin opens the moderation dashboard.
2. App loads pending profiles from a secure RPC.
3. Admin filters by account type, name, email, or username.
4. Admin selects a record to open the detail panel.

### Flow 3: Approve user
1. Admin reviews the profile.
2. Admin selects approve.
3. App calls a secure moderation RPC.
4. Backend updates status and writes an audit record.
5. UI removes the user from the pending queue and shows a success state.

### Flow 4: Reject user
1. Admin reviews the profile.
2. Admin selects reject.
3. App prompts for an optional or required reason.
4. App calls a secure moderation RPC.
5. Backend updates status and writes an audit record.
6. UI removes the user from the pending queue and shows a success state.

---

## 9. Feature Breakdown

### A. Authentication and authorization
- Email/password login for V1
- Session persistence
- Admin role check after login
- Unauthorized access handling

### B. Moderation dashboard
- Tabs or segmented control for influencers and businesses
- Search input
- Status counts
- Refresh action
- Empty state and error state

### C. Profile review panel
- Account summary
- Social handles with external links
- Business website link when applicable
- Created date
- Key metadata required for moderation

### D. Moderation actions
- Approve action
- Reject action with reason capture
- Loading state during submission
- Optimistic or post-success refresh behavior

### E. Audit history
- Historical list of moderation actions
- Filters by admin, action type, and date if easy to support
- Link back to reviewed user if useful

---

## 10. UX Guidance

### Design direction
- Clean, admin-focused visual system
- High readability
- Dense but not cluttered information layout
- Responsive behavior centered on web and tablet

### UX recommendations
- Use a two-pane layout on wide screens: queue on the left, details on the right.
- Keep moderation actions fixed and easy to reach.
- Show clear state labels for pending, approved, and rejected.
- Make external profile links easy to open without copying text.
- Use confirmation only where it reduces risk, especially for rejection.

---

## 11. State Management & App Services

### Recommended packages
- `supabase_flutter`
- `flutter_riverpod` or the team's preferred state solution
- `go_router`
- `flutter_dotenv`
- `intl`

### Suggested layers
- `services`: raw Supabase and RPC calls
- `repositories`: shape and validate data for features
- `controllers/providers`: drive UI state
- `widgets/screens`: presentation only

If the team already prefers Provider, we can keep Provider instead of Riverpod to reduce setup friction. The main goal is separation of concerns, not package churn.

---

## 12. Database Work Plan

### Minimum required changes
- Add `is_admin` or `role` to profiles
- Add or confirm `status` enum/field values
- Create secure RPC for fetching pending profiles
- Create secure RPC for approving/rejecting users
- Add audit log table

### Strong recommendation
Replace a generic `update_user_status(user_id, new_status)` function with action-specific server functions such as:
- `approve_profile(target_user_id UUID)`
- `reject_profile(target_user_id UUID, reason TEXT)`

This reduces misuse, improves auditability, and makes permissions easier to reason about.

---

## 13. Delivery Phases

### Phase 0: Backend preparation
- Confirm admin identity strategy
- Add schema changes
- Create RPCs
- Add audit logging
- Validate RLS and permissions

### Phase 1: App foundation
- Create Flutter admin project
- Configure environment loading
- Add router, theme, and auth bootstrap
- Set up Supabase client

### Phase 2: Auth and access control
- Build login screen
- Implement session restore
- Implement admin gate
- Add unauthorized handling

### Phase 3: Moderation dashboard
- Build pending queue UI
- Add filters and search
- Add responsive layouts
- Add loading, empty, and error states

### Phase 4: Detail review and actions
- Build profile detail view
- Add approve flow
- Add reject flow with reason
- Refresh queue after action

### Phase 5: Audit history
- Build audit log page
- Add simple filtering if supported

### Phase 6: Hardening
- Add tests
- Test edge cases
- Validate security assumptions
- Prepare deployment

---

## 14. Testing Strategy

### Unit tests
- Auth gate rejects non-admin users
- Model parsing handles missing optional fields
- Moderation controllers emit correct loading and success states
- Reject flow requires reason if product rules require it

### Integration tests
- Login and route to dashboard for admin
- Login rejection path for non-admin
- Pending profiles load correctly
- Approve action removes user from the queue
- Reject action removes user from the queue and stores reason

### Manual QA
- Try admin and non-admin accounts
- Verify status changes in Supabase
- Verify audit records are created
- Verify external links open correctly
- Verify layout on desktop, tablet, and narrow screens

---

## 15. Acceptance Criteria for V1

V1 is complete when:
- An admin can sign in successfully.
- A non-admin is blocked in both UI and backend.
- Pending influencer and business accounts can be reviewed.
- An admin can approve a pending user.
- An admin can reject a pending user with a stored reason if required.
- Every moderation action is recorded in an audit log.
- The dashboard works well on web and tablet layouts.

---

## 16. Open Decisions

These decisions should be confirmed before implementation begins:

1. Should V1 support only email/password login for admins?
2. Is rejection reason optional or required?
3. Should rejected users receive any notification in V1?
4. Is the first release web-only, or should mobile packaging be included immediately?
5. Do we want a simple `is_admin` flag for speed, or a role field for future growth?

---

## 17. Final Recommendation

The strongest V1 path is:
- Separate Flutter admin project
- Web-first responsive admin UI
- Email/password auth only
- Server-enforced admin RPCs
- Audit logging from day one
- Focused moderation workflow before adding analytics or broader internal tools

This keeps the first release secure, small in scope, and fast to deliver while leaving room for future admin capabilities.
