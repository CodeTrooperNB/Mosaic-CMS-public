# Mosaic CMS Pod Guide

This guide explains how Pods work in Mosaic CMS, how to define Pod schemas in YAML, validate and reload them during development, and how to generate presentation partials for each pod type.

Pods are reusable, JSONB-backed content blocks. Their shape is declared in YAML and loaded by Admin::PodSchemas. Pages link to Pods via PagePods with an explicit order (position).


## Where pod definitions live
- Primary location: config/pod_definitions.yml (project-specific; recommended)

Admin::PodSchemas will load config/pod_definitions.yml. It will raise clear errors if file doesn't exist or the YAML structure is invalid.

## File structure and keys
The YAML must parse to a Hash and contain a top-level key pod_definitions mapping pod_type keys to definitions.
```yaml
Top-level shape:

pod_definitions:
  <pod_type_key>:
    name: "Human Name"
    description: "Optional description"
    category: "content | headers | media | social_proof | marketing | navigation | support | ..."
    icon: "optional icon name"
    schema:
      <field_name>:
        type: text | rich_text | image | select | boolean | number | date | email | url | array | object
        label: "Field label"
        required: true|false
        default: <default value>
        help: "Help text"
        placeholder: "Placeholder"
        options: # for select fields
          - value: "left"
            label: "Left"
      # For arrays and objects, see examples below
```
A separate categories section may be present at the root to provide labels for category groupings used by the admin UI:
```yaml
categories:
  content: "Content"
  headers: "Headers"
  media: "Media"
```

## Example pod definitions

A minimal text block with alignment options:
```yaml
pod_definitions:
  basic_text:
    name: "Basic Text Block"
    description: "Simple text content with rich text formatting"
    category: "content"
    icon: "text"
    schema:
      content:
        type: rich_text
        label: "Content"
        required: true
        toolbar: "basic"
        placeholder: "Enter your content here..."
      text_align:
        type: select
        label: "Text Alignment"
        options:
          - { value: "left",   label: "Left" }
          - { value: "center", label: "Center" }
          - { value: "right",  label: "Right" }
        default: "left"
```
An image gallery using arrays and nested objects:
```yaml
pod_definitions:
  image_gallery:
    name: "Image Gallery"
    description: "Responsive grid of images with captions"
    category: "media"
    icon: "gallery"
    schema:
      title:
        type: text
        label: "Title"
      images:
        type: array
        label: "Images"
        item:
          type: object
          schema:
            image:
              type: image
              label: "Image"
              required: true
              crop_ratios: ["1:1", "16:9", "4:3"]
            caption:
              type: text
              label: "Caption"
              placeholder: "Optional"
```

## Validating and reloading definitions
Rake tasks are available to help during development:
- Validate the YAML shape: bin/rails mosaic:pod_definitions:validate
- Reload the singleton after changes: bin/rails mosaic:pod_definitions:reload

Under the hood, Admin::PodSchemas loads the file and verifies:
- The root is a Hash
- pod_definitions exists and is a Hash
- Every pod has name, category, and schema keys
- Every field has a type

If validation fails, clear error messages will be raised (see app/services/admin/pod_schemas.rb).


## Programmatic access (Admin::PodSchemas)
The singleton exposes these class methods for convenience:
- Admin::PodSchemas.available_types -> Array of pod_type keys
- Admin::PodSchemas.schema_for(:pod_type) -> Hash schema for a type
- Admin::PodSchemas.categories -> Hash of category labels
- Admin::PodSchemas.validate! -> raises if invalid
- Admin::PodSchemas.reload! -> reloads from disk


## Generating presentation partials from definitions
A Rails generator is provided to scaffold ERB partials for each pod type using the YAML schema. It creates display templates you can customize.

Run:
- bin/rails generate pods

Output:
- app/views/pods/shared/_<pod_key>.html.erb for each defined pod

Generation behavior:
- Skips files that already exist (idempotent)
- Emits semantic wrapper classes (e.g., pod-hero-banner, hero-banner-title)
- Handles field types including arrays and objects by nesting appropriate loops/blocks
- Adds a header comment with pod metadata at the top of each partial

You can safely edit generated partials. Re-running the generator will not override existing files.


## Using pods in views
How you render a pod depends on your page composition layer. A common pattern is to render by pod_type and pass the JSONB definition as data:
```erb
<%# in a page template or presenter %>
<% @page.page_pods.order(:position).each do |pp| %>
  <% pod = pp.pod %>
  <%= render "pods/shared/#{pod.pod_type}", data: pod.definition %>
<% end %>
```
Ensure generated partials expect a local data Hash containing the pod’s fields.


## Authoring tips
- Prefer snake_case keys for pod types and field names
- Keep pods small and composable; avoid giant catch-alls
- Put UI hints (help, placeholders) in YAML rather than hard-coding in views
- For image fields used with ActiveStorage, include clear naming (e.g., hero_image) and crop guidelines in the schema
- For arrays, prefer pluralized field names (e.g., testimonials) with item schemas


## Troubleshooting
- Error: "pod_definitions.yml not found in config/ or docs/" — add config/pod_definitions.yml or ensure docs copy exists
- Error: "pod_definitions.yml must have a 'pod_definitions' Hash" — ensure the root key is pod_definitions, not pods
- Generator says a file exists — this is expected for edited partials; delete to regenerate if needed
- Changes not reflected — run bin/rails mosaic:pod_definitions:reload (in dev) or restart the server
