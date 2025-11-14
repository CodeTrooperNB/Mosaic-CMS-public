# Junie CMS Development Roadmap - Enhanced Pod System

This is a comprehensive supplement to the existing Mosaic CMS roadmap, incorporating the advanced JSONB-based pod system with external configuration and reusable pod architecture.

## **Phase 2 Enhanced: Advanced Pod Architecture**

### **Step 2.1: Design Core Model Relationships**

**Model Overview:**
- **Page**: Main content container (blog post, landing page, etc.)
- **Pod**: Reusable content sections with JSONB-stored data
- **PagePod**: Join model managing pod positioning on pages

**Relationship Structure:**
```ruby
# Page Model (1-to-many with PagePods)
class Page < ApplicationRecord
  has_many :page_pods, -> { order(:position) }, dependent: :destroy
  has_many :pods, through: :page_pods
end

# Pod Model (many-to-many with Pages via PagePods)
class Pod < ApplicationRecord
  has_many :page_pods, dependent: :destroy
  has_many :pages, through: :page_pods
  has_many_attached :attachments
  
  # JSONB field containing all pod content and structure
  # No separate PodPart model needed - everything in definition
end

# PagePod Join Model (manages positioning and page-specific overrides)
class PagePod < ApplicationRecord
  belongs_to :page
  belongs_to :pod
  
  # position: integer for ordering pods on a page
  # page_specific_data: JSONB for page-specific overrides (optional)
  # visible: boolean for showing/hiding on specific pages
end
```


**Key Benefits:**
- Pods can be reused across multiple pages
- Each page can have different ordering of the same pods
- Page-specific customizations possible without duplicating pod data
- Clean separation between pod content and page presentation

### **Step 2.2: Create Pod Definitions Configuration System**

**Purpose**: External YAML configuration allows project-specific pod types without code changes.

**Implementation Details:**
- Create `config/pod_definitions.yml` with all available pod types
- Each pod type defines its schema, field types, validation rules
- Support for nested arrays (testimonials, articles, form fields)
- Rich text fields stored directly in JSONB for lists/arrays
- Image/file attachments linked via metadata keys

**Configuration Structure:**
```yaml
# Defines available pod types, their fields, validation, and UI hints
pod_definitions:
  hero:
    name: "Hero Section"
    category: "headers"
    schema:
      title: { type: text, required: true }
      content: { type: rich_text, toolbar: "basic" }
      background_image: { type: image, crop_ratios: ["16:9"] }
```


### **Step 2.3: Implement JSONB Content Storage**

**Content Strategy:**
- All pod data stored in `pods.definition` JSONB field
- Rich text content stored as HTML strings within JSONB
- File attachments stored via ActiveStorage with metadata linking
- Schema validation based on external pod definitions

**Attachment Handling:**
- `has_many_attached :attachments` on Pod model
- Each attachment has `attachment_key` in metadata
- JSONB references attachments by key: `{ "hero_image": { "attachment_key": "hero_bg_001" } }`
- Supports multiple attachments per pod (galleries, document lists)

## **Phase 3 Enhanced: Pod Configuration Management**

### **Step 3.1: Build Pod Schema Registry**

**Component**: `Admin::PodSchemas` singleton class
- Loads and validates pod definitions from YAML
- Provides schema lookup by pod type
- Extracts field information for form building
- Supports hot-reloading in development

**Features:**
- Schema validation on application boot
- Rich text field detection for TinyMCE integration
- Image field detection for CropperJS integration
- Category-based pod organization for admin UI

### **Step 3.2: Create Dynamic Form Builder**

**Component**: `Admin::PodFormBuilder` service class
- Generates admin forms based on pod schema definitions
- Handles nested arrays (articles, testimonials, form fields)
- Integrates with TinyMCE for rich text fields
- Manages file upload fields with cropping options

**Form Rendering Logic:**
- Reads pod schema to determine field types
- Renders appropriate input types (text, rich_text, image, array)
- Handles array fields with add/remove functionality
- Validates data according to schema rules

### **Step 3.3: Implement Configuration Validation**

**Validation System:**
- Rake task: `rails admin:pod_definitions:validate`
- Checks schema syntax and required fields
- Validates field type definitions
- Ensures attachment keys are properly referenced

**Hot Reloading (Development):**
- File watcher monitors `pod_definitions.yml`
- Automatically reloads schemas on file changes
- Provides immediate feedback during development

## **Phase 4 Enhanced: Advanced Page-Pod Management**

### **Step 4.1: Build Page-Pod Association Interface**

**Pod Selection Interface:**
- Browse available pods by category
- Preview pod content before adding to page
- Search pods by name, type, or content
- Show pod usage count across pages (reusability indicator)

**Page Assembly:**
- Drag-and-drop pod ordering
- Live preview of page layout
- Toggle pod visibility per page
- Page-specific pod customizations (via page_specific_data)

### **Step 4.2: Implement Pod Positioning System**

**Position Management:**
- `PagePod.position` integer field for ordering
- Automatic position assignment on pod addition
- Bulk position updates via drag-and-drop
- Position conflicts resolution

**Page-Specific Overrides:**
- `PagePod.page_specific_data` JSONB field
- Override specific pod fields per page without duplicating pod
- Maintain pod reusability while allowing customization
- Merge pod definition with page overrides for rendering

## **Phase 5 Enhanced: Advanced Pod Management**

### **Step 5.1: Build Pod CRUD with Schema Awareness**

**Pod Creation Flow:**
1. Select pod type from available definitions
2. Dynamic form generation based on schema
3. Rich text editing with appropriate TinyMCE toolbars
4. Image upload with schema-defined crop ratios
5. Array field management (add/remove/reorder items)

**Pod Editing Interface:**
- Schema-aware form validation
- Attachment management with preview
- Rich text content extraction for search indexing
- Pod usage tracking across pages

### **Step 5.2: Implement Pod Reusability Features**

**Reusability Indicators:**
- Show pod usage count in pod index
- List pages where pod is used
- Warn before editing pods used on multiple pages
- Option to "Save as New" for creating variations

**Pod Templates:**
- Mark pods as templates for common patterns
- Template library for quick pod creation
- Pre-filled pod data based on templates
- Category-based template organization

## **Phase 6 Enhanced: Rich Content Integration**

### **Step 6.1: Advanced TinyMCE Integration**

**Schema-Driven Configuration:**
- Different toolbar configurations per field type
- Minimal, basic, and advanced toolbar options
- Field-specific TinyMCE settings from schema
- Custom plugins for pod-specific content

**Array Rich Text Handling:**
- TinyMCE editors for each array item
- Dynamic editor creation/destruction on array changes
- Content synchronization with JSONB storage
- Bulk text operations across array items

### **Step 6.2: Content Search and Indexing**

**Rich Text Extraction:**
- `Pod#all_rich_text_content` method extracts HTML from JSONB
- `Pod#searchable_text` strips HTML for plain text search
- Recursive extraction from nested arrays and objects
- Search indexing for global content search

## **Phase 7 Enhanced: Advanced Attachment Management**

### **Step 7.1: Schema-Aware Image Handling**

**Crop Ratio Configuration:**
- Crop ratios defined in pod schema per image field
- Dynamic cropping interface based on field requirements
- Multiple crop versions for responsive images
- Metadata storage for crop settings

**Attachment Organization:**
- Metadata-based attachment categorization
- Bulk attachment operations
- Unused attachment cleanup
- Image optimization based on usage context

### **Step 7.2: Multi-Attachment Support**

**Gallery Fields:**
- Array image fields for galleries/slideshows
- Bulk image upload with individual cropping
- Image reordering within arrays
- Caption and metadata per image

**Document Management:**
- File attachment fields in pod schemas
- Document preview and download interfaces
- File type validation based on schema
- Version control for document attachments

## **Phase 8 Enhanced: Content Versioning and Publishing**

### **Step 8.1: Pod Version Control**

**Version Tracking:**
- JSON diffs for pod definition changes
- Timestamp and user tracking for changes
- Rollback capability to previous versions
- Change impact analysis across pages

### **Step 8.2: Publishing Workflow**

**Draft/Published States:**
- Pod-level draft/published status
- Page-level publishing with pod dependency checking
- Scheduled publishing for content campaigns
- Preview mode with draft content

## **Phase 9 Enhanced: Performance and Optimization**

### **Step 9.1: JSONB Query Optimization**

**Database Optimization:**
- GIN indexes on JSONB fields for fast searches
- Partial indexes for common query patterns
- Query optimization for pod content searches
- Caching strategies for frequently accessed pods

### **Step 9.2: Attachment Performance**

**Image Optimization:**
- Lazy loading for pod images
- Responsive image variants
- CDN integration for attachment delivery
- Image compression based on usage context

## **Phase 10 Enhanced: Advanced Features**

### **Step 10.1: Pod Analytics**

**Usage Tracking:**
- Pod performance metrics across pages
- Content engagement analysis
- Popular pod types reporting
- Reusability effectiveness metrics

### **Step 10.2: Import/Export System**

**Content Portability:**
- Pod definition export/import
- Page structure export with pod dependencies
- Bulk pod operations
- Project-to-project content migration

## **Implementation Timeline**

**Phase 2-3 (Weeks 1-3):** Core architecture and configuration system
**Phase 4-5 (Weeks 4-6):** Admin interface and pod management  
**Phase 6-7 (Weeks 7-9):** Rich content and attachment systems
**Phase 8-10 (Weeks 10-12):** Advanced features and optimization

## **Key Technical Decisions**

1. **JSONB over separate tables**: Flexibility and performance for varying pod structures
2. **External YAML configuration**: Project-specific customization without code changes
3. **Many-to-many with join model**: Pod reusability with page-specific positioning
4. **Rich text in JSONB**: Simplified array handling and single-source storage
5. **Metadata-linked attachments**: Clean separation of binary data from structured content

This enhanced roadmap provides a robust, flexible CMS architecture that can adapt to different project requirements while maintaining code reusability and performance.