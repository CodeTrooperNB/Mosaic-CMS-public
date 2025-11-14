# Mosaic CMS (.junie) Project Guidelines

This document captures project-specific conventions, build/configuration notes, and testing guidance for Mosaic CMS. It is intended for advanced contributors working within the Mosaic namespace and preparing for a future engine extraction.

## Stack Snapshot
- Ruby 3.4.2, Rails 8.0.2
- DB: PostgreSQL (pg)
- Caching/Jobs: Redis + Sidekiq
- Assets: propshaft, esbuild (JS), Tailwind CSS v4 CLI (CSS)
- Hotwire: turbo-rails, stimulus-rails
- AuthZ/AuthN: Devise, Pundit
- Rich content: ActionText, ActiveStorage, tinymce-rails (integration planned)
- Phlex for views and RubyUI for UI components
- SVG pipeline: inline_svg, svg_optimizer

Key Gems of interest are grouped in Gemfile under “MOSAIC CMS GEMS”.

## Project Layout Notes
- Admin namespace routes live under /admin. See config/routes.rb.
- Admin admin base controller: app/controllers/admin/admin_controller.rb
  - Includes Pundit and Admin::SvgHelper
  - Devise enforced via authenticate_admin_user!
  - Layout: app/views/layouts/admin/admin.rb (Phlex)
- Dashboard views (Phlex):
  - app/views/admin/dashboard/index.rb
  - app/views/admin/dashboard/stats_overview.rb
  - app/views/admin/dashboard/quick_actions.rb
- Phlex base: app/views/base.rb with Views::Base < Components::Base
- SVG helper: app/helpers/admin/svg_helper.rb (see Usage caveats below)
- Devise UI is intentionally plain ERB HTML (not Phlex) under app/views/admin/devise/* and layout app/views/layouts/admin/auth.html.erb.

Planned core models per roadmap: Page, Pod, PagePod (join model for positioning/association). PodPart is removed in the enhanced JSONB-based design; all pod content lives in a single JSONB field on Pod.

## Build and Run
Prereqs:
- PostgreSQL running and reachable via environment (DATABASE_URL or standard Rails config)
- Redis running (for Sidekiq and caching)

Install & setup:
1. bundle install
2. yarn install
3. bin/rails db:prepare
4. Build assets once (CI) or watch (dev):
   - JS: yarn build
   - CSS: yarn build:css
5. Dev server + asset watchers: bin/dev (Procfile.dev spawns web/js/css)

Notes:
- bin/setup performs bundler check, yarn install, db:prepare, clears logs/tmp, then execs bin/dev unless --skip-server.
- ActionText and ActiveStorage are in the stack; ensure storage and migrations are prepared when enabling their features.
- Sidekiq web UI is mounted at /admin/sidekiq (dev: open; prod: requires admin authentication). See config/routes.rb.

## Views and Layouts (ERB)
- Admin layout: app/views/layouts/admin/admin.html.erb. Controllers under Admin render standard ERB templates by default.
- Standard Rails conventions for ERB views/partials are used (e.g., app/views/admin/pages/*.html.erb, app/views/admin/pods/*.html.erb).
- Keep business logic in controllers/services; views remain declarative and minimal.

## UI Style Guide
- Authoritative reference: docs/dev_style_guide.md. Treat it as the source of truth for admin UI patterns (layouts, components, states) and ensure dark mode parity for every change.
- CSS utilities implemented in app/assets/stylesheets/form_utility.scss under @layer components. Classes include:
  - Buttons: btn-primary, btn-primary-sm, btn-secondary, btn-secondary-sm, btn-danger-sm (prefer -sm variants for most actions)
  - Forms: form-group, form-label, form-label-inline, form-input, form-textarea, form-select, form-checkbox, form-help, form-error
  - Badges: badge-success, badge-gray, badge-warning, badge-danger
- Build integration: application.tailwind.css must import ./form_utility.scss (and placeholders color_theme.scss, inline-icons.css). Compile via Tailwind v4 CLI (yarn build:css). Re-run after SCSS changes.
- Usage: Prefer these utilities over ad‑hoc Tailwind in ERB for consistency; follow the style guide for: error blocks, field‑level errors, empty states, hover actions and confirmation prompts.

Common view patterns (match sections in docs/dev_style_guide.md):
- Index pages: three-part layout (optional stats grid, main card with title + primary action, list with hover actions). Header icons: w-5 h-5 text-gray-500 dark:text-gray-300. Primary action button: btn-primary-sm.
- New/Edit pages: centered single card. Header with icon + title; description in muted text. Re-render with status: :unprocessable_entity to show error summary and field-level errors (use form-error); action row aligned right with btn-primary-sm and btn-secondary-sm.
- Show pages: multi-card layout separating main details and related content. Include counts in section headers when applicable. Provide inline actions to Edit/Delete with confirmation.

Dark mode requirements:
- Every card: bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm
- Card header: border-b border-gray-200 dark:border-gray-700 px-6 py-4
- Text: primary text-gray-900 dark:text-white; secondary text-gray-600 dark:text-gray-400; muted text-gray-500 dark:text-gray-400
- Icons: text-gray-500 dark:text-gray-300 for headers; text-gray-400 dark:text-gray-500 for list items

Forms & Errors:
- Structure fields using form-group/label/input classes. Error summary block precedes the form when resource.errors.any?. For field errors, apply red border focus classes and render form-error below the input. Include help text via form-help when no errors.
- Submit/cancel row: flex items-center justify-end gap-3 pt-6 border-t with btn-primary-sm and btn-secondary-sm.

Lists & Trees:
- Item rows: flex items-center justify-between p-4 border rounded-md bg-gray-50 dark:bg-gray-700/50 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors group; place hover-only actions in an opacity-0 group-hover:opacity-100 container.
- Hierarchical lists (page tree): indent children using ml-8 + border-l for branches; use admin_icon("document-text", class: "w-4 h-4 text-gray-400 dark:text-gray-500").

Empty states:
- Centered block with large muted icon, concise heading, and guidance paragraph; include a btn-primary-sm to the creation path.

Spacing & Typography:
- Page sections: space-y-6. Form fields: space-y-4. Lists: space-y-3. Button groups: gap-3. Icon + text: gap-2/3. Titles: text-lg font-semibold; item titles: font-medium; help text: text-xs text-gray-500 dark:text-gray-400.

Responsive tips:
- Stacking of buttons handled automatically; use min-w-0 flex-1 for truncation; avoid hover-only affordances on touch critical actions.

Do/Don’t checklist (apply during PR review):
- Do: prefer -sm buttons; confirm destructive actions; include loading/disabled states when relevant; use semantic HTML/labels; add hover transitions; group related actions; always include dark mode classes; test light/dark themes.
- Don’t: mix button styles; invent new ad‑hoc styles; forget error states/empty states; use colors outside the palette; overcrowd; omit dark mode.

File structure expectations:
- Views: app/views/admin/{pages,pods,admin_users}/* following patterns above; use partials for list nodes (e.g., _node.html.erb for trees).
- CSS: keep additions in form_utility.scss under @layer components; dark theme tokens in color_theme.scss; inline icon tweaks in inline-icons.css.

## SVG/Icon Usage
- Helper module: Admin::SvgHelper
  - admin_svg(path, options={}) -> inline_svg_tag with sensible defaults
  - admin_icon(name, options={}) -> convenience for admin icon set
  - mosaic_logo(name, options={}) -> convenience for logo assets
  - status_icon(status, options={}), action_icon(action, options={}) -> semantic helpers
- Assets are under app/assets/images/admin/** (e.g., admin/logos/mosaic-logo.svg, admin/icons/status/warning.svg).
- Usage caveat: admin_icon(name) builds a path under admin/icons/admin/#{name}.svg. Pass a bare icon name (e.g., "menu", "home"), not a full path. If passing a full path is necessary for a one-off, prefer admin_svg to avoid double-prefixing.

## AuthN/AuthZ
- Devise is configured with devise_for :admin_users under path admin/auth.
- Admin::AdminController enforces authenticate_admin_user! and role gate via ensure_admin_access (admin/editor).
- Pundit is mixed-in at the admin controller. Provide policies as you add resources.
- Pundit baseline in place: ApplicationPolicy (admin/editor defaults), AdminUserPolicy (admin-only), and PagePolicy (placeholder mirroring ApplicationPolicy for now). For index actions, prefer `policy_scope(Model)` and `authorize Model` rather than authorizing a collection.

## Testing
Framework: Minitest (rails/test_help). No rspec-rails is included (rspec under vendor/ is unrelated to this app).

Run all tests:
- bin/rails test

Add a new test:
1. Create test/test_helper.rb if not present (see example below—already added by this documentation process and verified).
2. Place tests under test/ following Rails conventions (e.g., test/models, test/controllers, test/helpers).
3. Use rails/test_help. For view/helper tests that rely on inline_svg helpers, include InlineSvg::ActionView::Helpers explicitly.

Example (verified locally): test/helpers/admin/svg_helper_test.rb

require "test_helper"

class MosaicSvgHelperTest < ActionView::TestCase
  include InlineSvg::ActionView::Helpers
  include Admin::SvgHelper

  test "admin_svg renders inline svg for existing asset" do
    html = admin_svg("admin/logos/mosaic-logo.svg", class: "h-4 w-4")
    assert_includes html, "<svg"
    assert_includes html, "h-4 w-4"
  end
end

Minimal test helper (test/test_helper.rb):

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # shared helpers
end

How we executed it:
- bin/rails test
- Output: 1 runs, 4 assertions, 0 failures, 0 errors, 0 skips

Guidelines for adding tests:
- Prefer fast, isolated tests. For Phlex components, test rendered output strings and key markers/classes.
- For Pundit, add policy unit tests under test/policies as policies are introduced.
- For controllers under Admin, test authentication/authorization filters and basic rendering status.

## Development Tips
- Tailwind v4 CLI is used; utilities are merged via tailwind_merge gem where appropriate. Keep class strings canonical to ease diffs.
- Keep Phlex view classes small; split sections into separate view classes (as done with StatsOverview and QuickActions) for reusability.
- When adding pages/pods/pod_parts, design associations with future engine extraction in mind (namespaced tables, clear FKs and indices). Follow roadmap’s Phase 2.
- Turbo frames are encouraged for admin UX (fast in-place updates); Stimulus is available for interactivity (e.g., future CropperJS controller per roadmap Phase 7).
- Sidekiq configuration is present; ensure REDIS_URL is configured in non-dev environments.

## Engine-readiness
- Keep everything in the Admin namespace (controllers, helpers, models, views) to ease extraction to a mountable engine.
- Avoid global initializers when a namespaced configuration would suffice.

## Slugs with FriendlyID
- Gem: friendly_id (~> 5.5) is added and used on Page.
- Page model: extend FriendlyId; friendly_id :title, use: :slugged. It generates the slug into pages.slug when blank, based on title.
- Manual slug still supported: if a slug is provided (e.g., via the New Page form), FriendlyID will not override it. We only auto-generate when slug is blank, or when the title changes and slug remains blank.
- Controller lookups updated to Page.friendly.find so both ID and slug work interchangeably in URLs and nested routes.
- No history table is enabled for now; if you later need slug history, run the FriendlyID generator to add friendly_id_slugs and update Page to use :history.

## Known/Watch-outs
- Icon helper contract: Use admin_icon with simple icon names mapped to admin/icons/admin/*.svg. For logos or any non-admin icon path, use admin_svg or a specific helper (mosaic_logo).
- Ensure devise routes under mosaic/auth remain aligned with UI and redirects in Admin::AdminController#ensure_admin_access.

## Roadmap Reference
See docs/dev_roadmap.md for phased milestones (models, admin CRUD, TinyMCE, CropperJS, Pundit, etc.). Build iteratively and keep admin UI in Phlex + RubyUI.

## Phase 3: Admin Interface Foundation
- Dashboard: Admin::DashboardController renders the Phlex layout (Views::Layouts::Admin::Admin) and the dashboard view (Views::Admin::Dashboard::Index) directly using phlex-rails. It disables Rails layout with layout false and composes the layout component explicitly.
- Navigation-ready endpoints: Added basic index routes/controllers/views for Pages and Pods under /mosaic so the sidebar links don’t 404. Controllers inherit Admin::AdminController and render Phlex pages within the Mosaic layout. These are placeholders for upcoming CRUD in later phases.
- Rendering pattern: In these controllers, we render the layout as a component, passing current_user and page_title, then render the page’s Phlex component within the block.

## Phase 4: Schema-Driven Pod Management (Foundation)
- Routes: pods now include :new and :create for creating pods.
- UI: New Pod page shows a type selection UI grouped by categories from PodSchemas, and a minimal creation form when a type is chosen.
- Persistence: Create action stores a new Pod with the selected pod_type and a JSON definition (entered as raw JSON for now).
- Future: Dynamic forms will be provided by Admin::PodFormBuilder; a stub service exists to outline the interface.

## Phase 5: Advanced Page–Pod Relationship Management (Foundation)
- Routes: pages now include :new, :create, :show. Nested page_pods routes (:create, :destroy) under a page provide linking/unlinking.
- Pages index shows a simple hierarchical tree using ancestry (no drag-and-drop yet).
- Page show displays the ordered list of linked pods (PagePods.position) and a minimal form to add an existing Pod; removal supported.
- Positioning: new PagePods get position = (current max position for the page) + 1.
- Authorization: uses ApplicationPolicy defaults (admin/editor). Fine-grained PagePolicy can be added in Phase 8.

## Enhanced Pod System (JSONB + External Schemas)
- Current source of truth for pod definitions: config/pod_definitions.yml when present; falls back to docs/pod_definitions.yml. During Phase 2, prefer creating config/pod_definitions.yml to override the docs copy for project-specific schemas.
- Registry and form builder (planned):
  - Admin::PodSchemas singleton will load/validate YAML, provide lookups by pod_type, detect rich_text/image fields, and support dev hot-reloading.
  - Admin::PodFormBuilder will render dynamic admin forms based on schema, including nested arrays, TinyMCE for rich_text, and image fields with crop ratios.
- JSONB storage strategy:
  - Pod stores all content under a single JSONB column (e.g., pods.definition). No PodPart model.
  - ActiveStorage attachments are linked by metadata keys referenced from JSONB. Arrays and nested objects are supported.
  - Rich text is stored as HTML strings inside JSONB; extraction utilities will be needed for search indexing.
- Ownership model and linking/positioning:
  - Pod is the source of truth for content; PagePod is strictly for linking a Pod to a Page and positioning (with ancestry + position).
  - Page-specific adjustments should be small, optional overrides stored in PagePod.page_specific_data; avoid duplicating core pod content there.
  - Pod usage is tracked automatically via PagePod using a counter cache to pods.usage_count.
- Schema shape (from the YAML):
  - Each pod has: name, category, and schema: field_name -> { type: text|rich_text|image|select|boolean|array|object, required?, default, options, help, placeholder }.
  - Image fields often include crop_ratios and accept lists; arrays contain item schemas with nested fields.
  - Categories are defined at the end of the YAML (e.g., content, headers, media, social_proof, marketing, navigation, support, etc.). Use category labels for UI grouping.
- Development workflow (until the registry is implemented):
  - Edit docs/pod_definitions.yml and keep YAML valid. Prefer descriptive, snake_case pod_type keys.
  - Validate manually with a YAML linter (e.g., ruby -ryaml -e 'YAML.load_file("docs/pod_definitions.yml")') or IDE validation.
  - Keep field naming consistent with future form builder expectations (e.g., image fields use *_image, arrays pluralized with clear item schemas).
  - Avoid breaking changes to existing pod types; if necessary, plan migration utilities.
- Rake tasks:
  - Validate: bin/rails mosaic:pod_definitions:validate
  - Reload (dev): bin/rails mosaic:pod_definitions:reload
- Testing guidance (to add when code exists):
  - Unit tests for Admin::PodSchemas: load/validation errors, field extraction (rich_text/image/arrays), category listing.
  - Service tests for PodFormBuilder: rendering per field type, arrays add/remove, required validation handling.
  - Model tests for Pod: JSONB validations against schemas; attachment key linking behavior.
- Conventions and pitfalls:
  - Prefer small, composable pod schemas; keep UI hints (help, placeholders) in YAML rather than code.
  - For icons and logos used within pod content, continue using Admin::SvgHelper helpers in Phlex views.
  - Plan for GIN indexes on JSONB and ancestry indexes as described in docs/dev_roadmap.md.
  - JSONB search indexes in place:
    - pods.definition: GIN (jsonb) + GIN tsvector over definition::text for simple full-text search.
    - page_pods.page_specific_data: GIN (jsonb) + GIN tsvector over page_specific_data::text.
    - pg_trgm extension enabled for potential trigram indexes if we need faster ILIKE/substring search patterns.
    - Prefer jsonb containment/exists for structured filters (e.g., where("definition @> ?", { key: "value" }.to_json)). For free text, use to_tsvector @@ plainto_tsquery.
