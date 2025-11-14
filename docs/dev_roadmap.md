# Mosaic CMS Development Roadmap

## **Phase 1: Foundation Setup**

### **Step 1.1: Add Required Gems**
- Add authentication, authorization, and content management gems to Gemfile
- Add image processing and rich text editing dependencies
- Add `ancestry` gem for hierarchical page structure and pod positioning
- Bundle install and configure

### **Step 1.2: Configure ActiveStorage & ActionText**
- Setup ActiveStorage for file uploads
- Configure ActionText for rich content (used for TinyMCE integration, not pod storage)
- Add image processing variants support with VIPS

### **Step 1.3: Install & Configure Devise**
- Generate Devise configuration
- Create AdminUser model with role enum (admin, editor)
- Customize Devise views for mosaic styling
- Configure authentication routes under admin namespace

### **Step 1.4: Install & Configure Pundit**
- Setup Pundit for authorization
- Create base ApplicationPolicy
- Configure role-based permissions structure

### **Step 1.5: Setup Ancestry for Hierarchical Structure**
- Configure ancestry gem for Page model (nested page structures)
- Configure ancestry gem for PagePod model (pod positioning within pages)
- Add proper indexing for ancestry columns

## **Phase 2: Enhanced Pod Architecture & External Configuration**

### **Step 2.1: Create Pod Definitions Configuration System**
- Create `config/pod_definitions.yml` with schema definitions for all pod types
- Implement `Admin::PodSchemas` singleton class for loading and managing schemas
- Add schema validation and error handling
- Create rake tasks for validating and reloading pod definitions
- Setup hot-reloading for development environment

### **Step 2.2: Generate Core Models with JSONB Storage**
- Create Page model with ancestry support for hierarchical pages
    - Basic attributes: title, slug, published, meta_description
    - Ancestry for nested page structure (parent/child relationships)
    - Published/draft status and scheduling
- Create Pod model with JSONB content storage
    - Remove PodPart concept - all content in JSONB `definition` field
    - `pod_type` field referencing external schema definitions
    - Rich text content stored directly in JSONB (not ActionText)
    - ActiveStorage attachments with metadata-based linking
    - Reusability flags and usage tracking
- Create PagePod join model for many-to-many relationship
    - Ancestry for pod positioning within pages
    - Page-specific overrides in JSONB field
    - Visibility controls per page

### **Step 2.3: Setup Enhanced Model Associations**
- Configure Page ↔ Pod many-to-many through PagePod join model
- Page ancestry for nested page structures
- PagePod ancestry for pod ordering and grouping
- Pod attachments via ActiveStorage with metadata keys
- Add proper indexing: ancestry columns, JSONB fields (GIN indexes), foreign keys

### **Step 2.4: Implement JSONB Content Management**
- Pod content validation based on external schema definitions
- Rich text extraction from JSONB for search indexing
- Attachment key management and linking system
- Content migration utilities for schema changes

## **Phase 3: Admin Interface Foundation**

### **Step 3.1: Setup Admin Namespace & Routes**
- Create admin namespace routing
- Setup admin layout using Phlex + RubyUI components
- Create admin dashboard with pod usage analytics
- Add breadcrumb navigation for hierarchical pages

### **Step 3.2: Mosaic Authentication Flow**
- Implement admin-only access control
- Create admin login/logout interface
- Setup proper redirects and flash messages
- Role-based dashboard customization

### **Step 3.3: Create Base Admin Controllers**
- ApplicationController with authentication and Pundit integration
- Base CRUD functionality with schema-aware operations
- Error handling and user feedback
- Turbo Frame support for seamless updates

## **Phase 4: Schema-Driven Pod Management**

### **Step 4.1: Build Pod Schema Registry Interface**
- Pod type selection interface with categories
- Schema browser showing available fields and types
- Pod template library for common patterns
- Schema validation feedback and error handling

### **Step 4.2: Dynamic Pod Form Generation**
- `Admin::PodFormBuilder` service for schema-aware forms
- Dynamic field rendering based on pod type schema
- Array field management (add/remove/reorder items)
- Nested form handling for complex pod structures

### **Step 4.3: Pod CRUD with Schema Integration**
- Pod creation wizard with type selection
- Schema-validated pod editing
- Rich text integration within JSONB structure
- Attachment management with schema-defined constraints
- Pod duplication and variation creation

## **Phase 5: Advanced Page-Pod Relationship Management**

### **Step 5.1: Hierarchical Page Structure**
- Page tree interface using ancestry relationships
- Drag-and-drop page reordering and nesting
- Page hierarchy breadcrumbs and navigation
- Bulk operations on page branches

### **Step 5.2: Pod Positioning with Ancestry**
- PagePod ancestry for complex pod arrangements
- Drag-and-drop pod positioning within pages
- Pod grouping and sectioning capabilities
- Visual pod layout interface

### **Step 5.3: Page-Pod Association Interface**
- Pod library browser with search and filtering
- Pod reusability indicators and usage tracking
- Page-specific pod customization via overrides
- Pod addition/removal with position management
- Live preview of page assembly

## **Phase 6: Rich Content Integration**

### **Step 6.1: TinyMCE Integration with JSONB Storage**
- Install and configure TinyMCE with schema-aware toolbars
- Rich text editing directly integrated with JSONB fields
- Custom TinyMCE configurations per field type from schema
- Array-based rich text handling for lists and collections
- Content extraction and search indexing

### **Step 6.2: Schema-Driven Content Forms**
- Dynamic form generation based on pod schema definitions
- Field validation according to schema rules
- Conditional field display based on schema conditions
- Rich text, image, and array field specialized interfaces

### **Step 6.3: Content Search and Indexing**
- Full-text search across JSONB pod content
- Rich text extraction for search indexing
- Advanced filtering by pod type, content type, and usage
- Saved search functionality for common queries

## **Phase 7: Advanced Attachment Management**

### **Step 7.1: Schema-Aware Image Handling**
- Install and configure CropperJS v1.6.2
- Create Stimulus controller for schema-driven cropping
- Crop ratios and constraints from pod schema definitions
- Multi-size image generation for responsive design

### **Step 7.2: Metadata-Linked Attachment System**
- Attachment key generation and management
- JSONB to ActiveStorage linking via metadata
- Bulk attachment operations and cleanup
- Attachment reuse across pods and pages

### **Step 7.3: Gallery and Multi-Attachment Support**
- Array-based image fields for galleries and slideshows
- Document attachment fields with validation
- Attachment organization and metadata editing
- Usage tracking and orphaned attachment cleanup

## **Phase 8: Authorization & Permissions**

### **Step 8.1: Create Enhanced Pundit Policies**
- PagePolicy with ancestry-aware permissions (admin: all, editor: create/edit own branch)
- PodPolicy with reusability considerations (admin: all, editor: create/edit/reuse)
- PagePodPolicy for join model permissions
- AdminUserPolicy (admin only)

### **Step 8.2: Implement Role-Based UI**
- Conditional navigation based on permissions and hierarchy
- Hide/show action buttons per role and context
- Graceful permission denied handling
- Role-specific dashboard views

## **Phase 9: Advanced Features**

### **Step 9.1: Content Search & Analytics**
- Global search across pages and pods with JSONB content
- Pod usage analytics and performance tracking
- Popular pod types and reusability metrics
- Content effectiveness reporting

### **Step 9.2: Content Versioning & Publishing**
- Pod version tracking with JSONB diff storage
- Page publishing workflow with pod dependency checking
- Scheduled publishing using ActiveJob and Sidekiq
- Draft/published states with preview functionality

### **Step 9.3: Import/Export & Migration Tools**
- Pod definition import/export for project portability
- Page structure export with pod dependencies
- Schema migration tools for pod definition changes
- Bulk content operations and transformations

## **Phase 10: Performance & Polish**

### **Step 10.1: JSONB Query Optimization**
- GIN indexes on JSONB fields for fast content searches
- Partial indexes for common query patterns
- Query optimization for complex pod content searches
- Caching strategies for frequently accessed content

### **Step 10.2: UI/UX Enhancements**
- Responsive admin interface with mobile support
- Loading states and progress indicators
- Advanced error handling and user feedback
- Accessibility improvements and keyboard navigation

### **Step 10.3: Testing & Documentation**
- Comprehensive test suite for schema-driven functionality
- API documentation for future engine conversion
- User guide for pod schema definition
- Performance benchmarks and optimization guidelines

## **Enhanced Technical Stack Summary**

**Core Gems Added:**
- `ancestry` - Hierarchical page and pod positioning
- `devise` - Authentication
- `pundit` - Authorization
- `image_processing` - ActiveStorage variants with VIPS
- `tinymce-rails` - Rich text editor integration

**Optional Enhancement Gems:**
- `inline_svg` - Inline SVG rendering
- `svg_optimizer` - SVG optimization
- `pg_search` - Advanced PostgreSQL text search

**JavaScript Dependencies:**
- `cropperjs@1.6.2` - Schema-aware image cropping
- `tinymce` - Rich text editing with JSONB integration
- `sortablejs` - Drag-and-drop for pod positioning

**Key Architectural Decisions:**
- **JSONB Content Storage**: All pod content in single JSONB field for flexibility
- **External Schema Configuration**: YAML-based pod definitions for project customization
- **Ancestry for Positioning**: Hierarchical structures for both pages and pod positioning
- **Metadata-Linked Attachments**: Clean separation of binary data from structured content
- **Schema-Driven Forms**: Dynamic UI generation based on external configuration

**Database Design:**
- Pages with ancestry for hierarchical structure
- Pods with JSONB definition field and ActiveStorage attachments
- PagePods join model with ancestry for positioning and page-specific overrides
- GIN indexes on JSONB fields for performance
- Foreign key constraints and proper indexing throughout

This enhanced roadmap provides a robust, schema-driven CMS architecture that adapts to project requirements while maintaining performance and reusability. The ancestry gem enables sophisticated content organization, while external pod definitions ensure flexibility without code changes.