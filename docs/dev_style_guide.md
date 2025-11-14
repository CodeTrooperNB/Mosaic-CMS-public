# Mosaic CMS UI Style Guide

*A comprehensive design system for building consistent, polished admin interfaces*

## Overview

This style guide establishes the visual language and component patterns for Mosaic CMS. It uses a fully semantic color system with automatic dark mode support via CSS custom properties defined in `color_theme.scss`.

## Design Principles

### 1. **Consistency First**
- Use semantic component classes for all styling
- Follow established patterns for layout, spacing, and interactions
- Maintain visual hierarchy across all views

### 2. **Semantic Color System**
- All colors are defined through semantic tokens
- Automatic dark mode support without conditional classes
- Consistent theming across all components

### 3. **Content-Focused**
- Clean, uncluttered interfaces that highlight the content
- Generous whitespace and clear typography
- Subtle shadows and borders for depth without distraction

---

## Semantic Color Classes

### Base Colors
| Class | Usage | Light Mode | Dark Mode |
|-------|--------|------------|-----------|
| `bg-background` | Page background | White | Dark gray |
| `text-foreground` | Primary text | Dark gray | White |
| `bg-card` | Card/surface backgrounds | White | Dark gray |
| `text-card-foreground` | Text on cards | Dark gray | White |

### Interactive Elements
| Class | Usage | 
|-------|-------|
| `bg-primary` | Primary buttons, key actions |
| `text-primary-foreground` | Text on primary elements |
| `bg-secondary` | Secondary buttons, inactive states |
| `text-secondary-foreground` | Text on secondary elements |
| `bg-muted` | Subtle backgrounds |
| `text-muted-foreground` | Secondary/help text |

### Status Colors
| Class | Usage |
|-------|-------|
| `bg-destructive` | Delete buttons, error states |
| `text-destructive-foreground` | Text on destructive elements |
| `bg-warning` | Warning states |
| `text-warning-foreground` | Text on warning elements |
| `bg-success` | Success states |
| `text-success-foreground` | Text on success elements |

### Structure Elements
| Class | Usage |
|-------|-------|
| `border-border` | All borders |
| `bg-input` | Form inputs |
| `ring-ring` | Focus rings |

---

## Layout Patterns

### Page Structure
```erb
<% content_for :page_title, "Page Name" %>

<div class="space-y-6">
  <!-- Stats/Summary cards (optional) -->
  <!-- Main content area -->
  <!-- Secondary content areas -->
</div>
```

### Card Layout (Semantic)
```erb
<div class="bg-card border-border rounded-lg shadow-sm">
  <div class="border-b border-border px-6 py-4">
    <div class="flex items-center gap-2">
      <%= admin_icon("icon-name", class: "w-5 h-5 text-muted-foreground") %>
      <h2 class="text-lg font-semibold text-card-foreground">Section Title</h2>
    </div>
  </div>
  <div class="p-6">
    <!-- Content -->
  </div>
</div>
```

---

## View Layout Patterns

### Index Views
```erb
<% content_for :page_title, "Items" %>

<div class="space-y-6">
  <!-- 1. Stats Cards Section -->
  <div class="grid grid-cols-3 gap-4">
    <div class="bg-card border-border rounded-lg p-4 hover:shadow-sm transition-shadow">
      <div class="flex items-center justify-between">
        <div>
          <div class="text-xs font-medium text-muted-foreground uppercase tracking-wide">Total</div>
          <div class="text-2xl font-bold text-card-foreground"><%= @stats[:total] %></div>
        </div>
        <%= admin_icon("icon", class: "w-8 h-8 text-muted-foreground") %>
      </div>
    </div>
  </div>

  <!-- 2. Main Content Card -->
  <div class="bg-card border-border rounded-lg shadow-sm">
    <div class="flex items-center justify-between border-b border-border px-6 py-4">
      <div class="flex items-center gap-2">
        <%= admin_icon("icon", class: "w-5 h-5 text-muted-foreground") %>
        <h2 class="text-lg font-semibold text-card-foreground">Items</h2>
      </div>
      <%= link_to new_path, class: "btn-primary-sm" do %>
        <%= action_icon("create", class: "w-4 h-4") %>
        New Item
      <% end %>
    </div>
    <div class="p-6">
      <!-- List content or empty state -->
    </div>
  </div>
</div>
```

### New/Edit Views
```erb
<% content_for :page_title, "New Item" %>

<div class="max-w-2xl mx-auto">
  <div class="bg-card border-border rounded-lg shadow-sm">
    <div class="border-b border-border px-6 py-4">
      <div class="flex items-center gap-2">
        <%= action_icon("create", class: "w-5 h-5 text-muted-foreground") %>
        <h1 class="text-lg font-semibold text-card-foreground">Create New Item</h1>
      </div>
      <p class="text-sm text-muted-foreground mt-1">Add a new item to your collection</p>
    </div>

    <div class="p-6">
      <!-- Form content -->
    </div>
  </div>
</div>
```

### Show Views
```erb
<% content_for :page_title, @item.title %>

<div class="space-y-6">
  <!-- Main Item Info Card -->
  <div class="bg-card border-border rounded-lg shadow-sm">
    <div class="border-b border-border px-6 py-6">
      <div class="flex items-start justify-between">
        <div class="min-w-0 flex-1">
          <h1 class="text-2xl font-bold text-card-foreground"><%= @item.title %></h1>
          <p class="text-muted-foreground mt-1"><%= @item.description %></p>
        </div>
        <div class="flex items-center gap-2 ml-4">
          <!-- Action buttons -->
        </div>
      </div>
    </div>
    <div class="p-6">
      <!-- Item details -->
    </div>
  </div>

  <!-- Related Content Card -->
  <div class="bg-card border-border rounded-lg shadow-sm">
    <div class="border-b border-border px-6 py-4">
      <div class="flex items-center gap-2">
        <%= admin_icon("related", class: "w-5 h-5 text-muted-foreground") %>
        <h2 class="text-lg font-semibold text-card-foreground">Related Items</h2>
        <span class="text-sm text-muted-foreground">(<%= count %>)</span>
      </div>
    </div>
    <div class="p-6">
      <!-- Related content -->
    </div>
  </div>
</div>
```

---

## Forms & Inputs

### Form Structure
```erb
<%= form_with model: @object, local: true, class: "space-y-6" do %>
  <div class="form-group">
    <label for="field_name" class="form-label">Field Label</label>
    <input type="text" id="field_name" name="object[field]" 
           class="form-input" placeholder="Helpful placeholder" />
    <p class="form-help">Optional help text</p>
  </div>
  
  <!-- Form actions -->
  <div class="flex items-center justify-end gap-3 pt-6 border-t border-border">
    <%= link_to "Cancel", back_path, class: "btn-secondary-sm" %>
    <button type="submit" class="btn-primary-sm">
      <%= action_icon("save", class: "w-4 h-4") %>
      Save
    </button>
  </div>
<% end %>
```

### Form Field Types
```erb
<!-- Text Input -->
<input type="text" class="form-input" />

<!-- Textarea -->
<textarea class="form-textarea"></textarea>

<!-- Select -->
<select class="form-select">
  <option>Option 1</option>
</select>

<!-- Checkbox Container -->
<div class="flex items-center gap-3 p-4 bg-muted rounded-md">
  <input type="checkbox" class="form-checkbox" />
  <div>
    <label class="form-label-inline">Checkbox Label</label>
    <p class="text-xs text-muted-foreground">Helper text</p>
  </div>
</div>
```

### Error Messages
```erb
<div class="mb-6 border border-destructive/20 bg-destructive/10 rounded-md p-4">
  <div class="flex gap-3">
    <%= status_icon("error", class: "w-5 h-5 text-destructive shrink-0 mt-0.5") %>
    <div>
      <h3 class="font-medium text-destructive text-sm">Please fix the following errors:</h3>
      <ul class="mt-2 text-sm text-destructive/80 space-y-1">
        <% errors.each do |msg| %>
          <li class="flex items-start gap-1">
            <span class="text-destructive mt-1">•</span>
            <%= msg %>
          </li>
        <% end %>
      </ul>
    </div>
  </div>
</div>
```

---

## Status & Feedback

### Badges (Semantic)
```erb
<!-- Success state -->
<span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium bg-success text-success-foreground rounded-full">
  <%= status_icon("published", class: "w-3 h-3") %>
  Live
</span>

<!-- Warning state -->
<span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium bg-warning text-warning-foreground rounded-full">
  Warning
</span>

<!-- Muted state -->
<span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium bg-muted text-muted-foreground rounded-full">
  <%= status_icon("draft", class: "w-3 h-3") %>
  Draft
</span>
```

---

## Lists & Tables

### Item Lists
```erb
<div class="space-y-3">
  <% items.each do |item| %>
    <div class="flex items-center justify-between p-4 border-border rounded-md bg-muted hover:bg-accent transition-colors group">
      <div class="flex items-center gap-4 min-w-0 flex-1">
        <div class="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
          <%= admin_icon("item-icon", class: "w-4 h-4") %>
        </div>
        <div class="min-w-0 flex-1">
          <div class="font-medium text-card-foreground truncate"><%= item.title %></div>
          <div class="text-sm text-muted-foreground truncate"><%= item.description %></div>
        </div>
      </div>
      
      <!-- Hover actions -->
      <div class="flex items-center gap-1">
        <%= link_to edit_path, 
                    class: "p-1.5 text-muted-foreground hover:text-primary hover:bg-accent rounded transition-colors",
                    title: "Edit" do %>
          <%= action_icon("edit", class: "w-4 h-4") %>
        <% end %>
      </div>
    </div>
  <% end %>
</div>
```

---

## Empty States

```erb
<div class="text-center py-12">
  <%= admin_icon("relevant-icon", class: "w-12 h-12 mx-auto mb-4 text-muted-foreground") %>
  <div class="prose prose-sm max-w-none">
    <h3 class="text-card-foreground font-medium">No items yet</h3>
    <p class="text-muted-foreground">Descriptive text about what user should do next.</p>
  </div>
  <%= link_to create_path, class: "btn-primary-sm mt-4" do %>
    <%= action_icon("create", class: "w-4 h-4") %>
    Create First Item
  <% end %>
</div>
```

---

## Component Classes Reference

### Buttons (defined in form_utility.scss)
| Class | Semantic Colors |
|-------|----------------|
| `btn-primary` | `bg-primary text-primary-foreground` |
| `btn-primary-sm` | `bg-primary text-primary-foreground` |
| `btn-secondary` | `bg-secondary text-secondary-foreground` |
| `btn-secondary-sm` | `bg-secondary text-secondary-foreground` |
| `btn-danger-sm` | `bg-destructive text-destructive-foreground` |

### Form Elements (defined in form_utility.scss)
| Class | Semantic Colors |
|-------|----------------|
| `form-input` | `bg-input border-border` |
| `form-textarea` | `bg-input border-border` |
| `form-select` | `bg-input border-border` |
| `form-label` | `text-card-foreground` |
| `form-help` | `text-muted-foreground` |
| `form-error` | `text-destructive` |

---

## Typography & Spacing

### Typography Hierarchy (Semantic)
- **Page title**: `text-lg font-semibold text-card-foreground`
- **Section title**: `text-lg font-semibold text-card-foreground`
- **Item title**: `font-medium text-card-foreground`
- **Body text**: `text-foreground` (default)
- **Muted text**: `text-muted-foreground`
- **Help text**: `text-xs text-muted-foreground`

### Spacing Scale
- **Page sections**: `space-y-6`
- **Form fields**: `space-y-4` or `space-y-6`
- **List items**: `space-y-3`
- **Button groups**: `gap-3`
- **Icon + text**: `gap-2` or `gap-3`

---

## Icons

### Usage Patterns (Semantic Colors)
- **Header icons**: `w-5 h-5 text-muted-foreground`
- **Button icons**: `w-4 h-4` (inherits button text color)
- **List item icons**: `w-4 h-4 text-muted-foreground`
- **Status icons**: `w-3 h-3` (inherits badge text color)
- **Large decorative**: `w-8 h-8` or `w-12 h-12 text-muted-foreground`

---

## Benefits of Semantic Approach

### ✅ Advantages
- **Automatic dark mode** - No conditional classes needed
- **Consistent theming** - All components automatically match
- **Easy maintenance** - Color changes in one place
- **Better semantics** - Classes describe purpose, not appearance
- **Future-proof** - Easy to add new themes or adjust colors

### 🔄 Migration Tips
- Replace `bg-white dark:bg-gray-800` with `bg-card`
- Replace `text-gray-900 dark:text-white` with `text-card-foreground`
- Replace `text-gray-500 dark:text-gray-400` with `text-muted-foreground`
- Replace `border-gray-200 dark:border-gray-700` with `border-border`

---

## File Structure

### CSS Location
- Main theme: `app/assets/stylesheets/color_theme.scss`
- Components: `app/assets/stylesheets/form_utility.scss`
- Main import: `app/assets/stylesheets/application.tailwind.css`

This style guide ensures consistent, maintainable, and automatically themed admin interfaces throughout Mosaic CMS!
```
# Mosaic CMS UI Style Guide

*A comprehensive design system for building consistent, polished admin interfaces*

## Overview

This style guide establishes the visual language and component patterns for Mosaic CMS. It uses a fully semantic color system with automatic dark mode support via CSS custom properties defined in `color_theme.scss`.

## Design Principles

### 1. **Consistency First**
- Use semantic component classes for all styling
- Follow established patterns for layout, spacing, and interactions
- Maintain visual hierarchy across all views

### 2. **Semantic Color System**
- All colors are defined through semantic tokens
- Automatic dark mode support without conditional classes
- Consistent theming across all components

### 3. **Content-Focused**
- Clean, uncluttered interfaces that highlight the content
- Generous whitespace and clear typography
- Subtle shadows and borders for depth without distraction

---

## Semantic Color Classes

### Base Colors
| Class | Usage | Light Mode | Dark Mode |
|-------|--------|------------|-----------|
| `bg-background` | Page background | White | Dark gray |
| `text-foreground` | Primary text | Dark gray | White |
| `bg-card` | Card/surface backgrounds | White | Dark gray |
| `text-card-foreground` | Text on cards | Dark gray | White |

### Interactive Elements
| Class | Usage | 
|-------|-------|
| `bg-primary` | Primary buttons, key actions |
| `text-primary-foreground` | Text on primary elements |
| `bg-secondary` | Secondary buttons, inactive states |
| `text-secondary-foreground` | Text on secondary elements |
| `bg-muted` | Subtle backgrounds |
| `text-muted-foreground` | Secondary/help text |

### Status Colors
| Class | Usage |
|-------|-------|
| `bg-destructive` | Delete buttons, error states |
| `text-destructive-foreground` | Text on destructive elements |
| `bg-warning` | Warning states |
| `text-warning-foreground` | Text on warning elements |
| `bg-success` | Success states |
| `text-success-foreground` | Text on success elements |

### Structure Elements
| Class | Usage |
|-------|-------|
| `border-border` | All borders |
| `bg-input` | Form inputs |
| `ring-ring` | Focus rings |

---

## Layout Patterns

### Page Structure
```erb
<% content_for :page_title, "Page Name" %>

<div class="space-y-6">
  <!-- Stats/Summary cards (optional) -->
  <!-- Main content area -->
  <!-- Secondary content areas -->
</div>
```

### Card Layout (Semantic)
```erb
<div class="bg-card border-border rounded-lg shadow-sm">
  <div class="border-b border-border px-6 py-4">
    <div class="flex items-center gap-2">
      <%= admin_icon("icon-name", class: "w-5 h-5 text-muted-foreground") %>
      <h2 class="text-lg font-semibold text-card-foreground">Section Title</h2>
    </div>
  </div>
  <div class="p-6">
    <!-- Content -->
  </div>
</div>
```

---

## View Layout Patterns

### Index Views
```erb
<% content_for :page_title, "Items" %>

<div class="space-y-6">
  <!-- 1. Stats Cards Section -->
  <div class="grid grid-cols-3 gap-4">
    <div class="bg-card border-border rounded-lg p-4 hover:shadow-sm transition-shadow">
      <div class="flex items-center justify-between">
        <div>
          <div class="text-xs font-medium text-muted-foreground uppercase tracking-wide">Total</div>
          <div class="text-2xl font-bold text-card-foreground"><%= @stats[:total] %></div>
        </div>
        <%= admin_icon("icon", class: "w-8 h-8 text-muted-foreground") %>
      </div>
    </div>
  </div>

  <!-- 2. Main Content Card -->
  <div class="bg-card border-border rounded-lg shadow-sm">
    <div class="flex items-center justify-between border-b border-border px-6 py-4">
      <div class="flex items-center gap-2">
        <%= admin_icon("icon", class: "w-5 h-5 text-muted-foreground") %>
        <h2 class="text-lg font-semibold text-card-foreground">Items</h2>
      </div>
      <%= link_to new_path, class: "btn-primary-sm" do %>
        <%= action_icon("create", class: "w-4 h-4") %>
        New Item
      <% end %>
    </div>
    <div class="p-6">
      <!-- List content or empty state -->
    </div>
  </div>
</div>
```

### New/Edit Views
```erb
<% content_for :page_title, "New Item" %>

<div class="max-w-2xl mx-auto">
  <div class="bg-card border-border rounded-lg shadow-sm">
    <div class="border-b border-border px-6 py-4">
      <div class="flex items-center gap-2">
        <%= action_icon("create", class: "w-5 h-5 text-muted-foreground") %>
        <h1 class="text-lg font-semibold text-card-foreground">Create New Item</h1>
      </div>
      <p class="text-sm text-muted-foreground mt-1">Add a new item to your collection</p>
    </div>

    <div class="p-6">
      <!-- Form content -->
    </div>
  </div>
</div>
```

### Show Views
```erb
<% content_for :page_title, @item.title %>

<div class="space-y-6">
  <!-- Main Item Info Card -->
  <div class="bg-card border-border rounded-lg shadow-sm">
    <div class="border-b border-border px-6 py-6">
      <div class="flex items-start justify-between">
        <div class="min-w-0 flex-1">
          <h1 class="text-2xl font-bold text-card-foreground"><%= @item.title %></h1>
          <p class="text-muted-foreground mt-1"><%= @item.description %></p>
        </div>
        <div class="flex items-center gap-2 ml-4">
          <!-- Action buttons -->
        </div>
      </div>
    </div>
    <div class="p-6">
      <!-- Item details -->
    </div>
  </div>

  <!-- Related Content Card -->
  <div class="bg-card border-border rounded-lg shadow-sm">
    <div class="border-b border-border px-6 py-4">
      <div class="flex items-center gap-2">
        <%= admin_icon("related", class: "w-5 h-5 text-muted-foreground") %>
        <h2 class="text-lg font-semibold text-card-foreground">Related Items</h2>
        <span class="text-sm text-muted-foreground">(<%= count %>)</span>
      </div>
    </div>
    <div class="p-6">
      <!-- Related content -->
    </div>
  </div>
</div>
```

---

## Forms & Inputs

### Form Structure
```erb
<%= form_with model: @object, local: true, class: "space-y-6" do %>
  <div class="form-group">
    <label for="field_name" class="form-label">Field Label</label>
    <input type="text" id="field_name" name="object[field]" 
           class="form-input" placeholder="Helpful placeholder" />
    <p class="form-help">Optional help text</p>
  </div>
  
  <!-- Form actions -->
  <div class="flex items-center justify-end gap-3 pt-6 border-t border-border">
    <%= link_to "Cancel", back_path, class: "btn-secondary-sm" %>
    <button type="submit" class="btn-primary-sm">
      <%= action_icon("save", class: "w-4 h-4") %>
      Save
    </button>
  </div>
<% end %>
```

### Form Field Types
```erb
<!-- Text Input -->
<input type="text" class="form-input" />

<!-- Textarea -->
<textarea class="form-textarea"></textarea>

<!-- Select -->
<select class="form-select">
  <option>Option 1</option>
</select>

<!-- Checkbox Container -->
<div class="flex items-center gap-3 p-4 bg-muted rounded-md">
  <input type="checkbox" class="form-checkbox" />
  <div>
    <label class="form-label-inline">Checkbox Label</label>
    <p class="text-xs text-muted-foreground">Helper text</p>
  </div>
</div>
```

### Error Messages
```erb
<div class="mb-6 border border-destructive/20 bg-destructive/10 rounded-md p-4">
  <div class="flex gap-3">
    <%= status_icon("error", class: "w-5 h-5 text-destructive shrink-0 mt-0.5") %>
    <div>
      <h3 class="font-medium text-destructive text-sm">Please fix the following errors:</h3>
      <ul class="mt-2 text-sm text-destructive/80 space-y-1">
        <% errors.each do |msg| %>
          <li class="flex items-start gap-1">
            <span class="text-destructive mt-1">•</span>
            <%= msg %>
          </li>
        <% end %>
      </ul>
    </div>
  </div>
</div>
```

---

## Status & Feedback

### Badges (Semantic)
```erb
<!-- Success state -->
<span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium bg-success text-success-foreground rounded-full">
  <%= status_icon("published", class: "w-3 h-3") %>
  Live
</span>

<!-- Warning state -->
<span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium bg-warning text-warning-foreground rounded-full">
  Warning
</span>

<!-- Muted state -->
<span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium bg-muted text-muted-foreground rounded-full">
  <%= status_icon("draft", class: "w-3 h-3") %>
  Draft
</span>
```

---

## Lists & Tables

### Item Lists
```erb
<div class="space-y-3">
  <% items.each do |item| %>
    <div class="flex items-center justify-between p-4 border-border rounded-md bg-muted hover:bg-accent transition-colors group">
      <div class="flex items-center gap-4 min-w-0 flex-1">
        <div class="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
          <%= admin_icon("item-icon", class: "w-4 h-4") %>
        </div>
        <div class="min-w-0 flex-1">
          <div class="font-medium text-card-foreground truncate"><%= item.title %></div>
          <div class="text-sm text-muted-foreground truncate"><%= item.description %></div>
        </div>
      </div>
      
      <!-- Actions (always visible) -->
      <div class="flex items-center gap-1">
        <%= link_to edit_path, 
                    class: "p-1.5 text-muted-foreground hover:text-primary hover:bg-accent rounded transition-colors",
                    title: "Edit" do %>
          <%= action_icon("edit", class: "w-4 h-4") %>
        <% end %>
      </div>
    </div>
  <% end %>
</div>
```

---

## Empty States

```erb
<div class="text-center py-12">
  <%= admin_icon("relevant-icon", class: "w-12 h-12 mx-auto mb-4 text-muted-foreground") %>
  <div class="prose prose-sm max-w-none">
    <h3 class="text-card-foreground font-medium">No items yet</h3>
    <p class="text-muted-foreground">Descriptive text about what user should do next.</p>
  </div>
  <%= link_to create_path, class: "btn-primary-sm mt-4" do %>
    <%= action_icon("create", class: "w-4 h-4") %>
    Create First Item
  <% end %>
</div>
```

---

## Component Classes Reference

### Buttons (defined in form_utility.scss)
| Class | Semantic Colors |
|-------|----------------|
| `btn-primary` | `bg-primary text-primary-foreground` |
| `btn-primary-sm` | `bg-primary text-primary-foreground` |
| `btn-secondary` | `bg-secondary text-secondary-foreground` |
| `btn-secondary-sm` | `bg-secondary text-secondary-foreground` |
| `btn-danger-sm` | `bg-destructive text-destructive-foreground` |

### Form Elements (defined in form_utility.scss)
| Class | Semantic Colors |
|-------|----------------|
| `form-input` | `bg-input border-border` |
| `form-textarea` | `bg-input border-border` |
| `form-select` | `bg-input border-border` |
| `form-label` | `text-card-foreground` |
| `form-help` | `text-muted-foreground` |
| `form-error` | `text-destructive` |

---

## Typography & Spacing

### Typography Hierarchy (Semantic)
- **Page title**: `text-lg font-semibold text-card-foreground`
- **Section title**: `text-lg font-semibold text-card-foreground`
- **Item title**: `font-medium text-card-foreground`
- **Body text**: `text-foreground` (default)
- **Muted text**: `text-muted-foreground`
- **Help text**: `text-xs text-muted-foreground`

### Spacing Scale
- **Page sections**: `space-y-6`
- **Form fields**: `space-y-4` or `space-y-6`
- **List items**: `space-y-3`
- **Button groups**: `gap-3`
- **Icon + text**: `gap-2` or `gap-3`

---

## Icons

### Usage Patterns (Semantic Colors)
- **Header icons**: `w-5 h-5 text-muted-foreground`
- **Button icons**: `w-4 h-4` (inherits button text color)
- **List item icons**: `w-4 h-4 text-muted-foreground`
- **Status icons**: `w-3 h-3` (inherits badge text color)
- **Large decorative**: `w-8 h-8` or `w-12 h-12 text-muted-foreground`

---

## Interactions
- Index item actions/icons are always visible (no hover-only opacity). Use hover to adjust color/background only.
- Drag-and-drop sorting must use an explicit handle: add `.drag-handle` to the handle element and configure SortableJS with `handle: '.drag-handle'`.

---

## Benefits of Semantic Approach

### ✅ Advantages
- **Automatic dark mode** - No conditional classes needed
- **Consistent theming** - All components automatically match
- **Easy maintenance** - Color changes in one place
- **Better semantics** - Classes describe purpose, not appearance
- **Future-proof** - Easy to add new themes or adjust colors

### 🔄 Migration Tips
- Replace `bg-white dark:bg-gray-800` with `bg-card`
- Replace `text-gray-900 dark:text-white` with `text-card-foreground`
- Replace `text-gray-500 dark:text-gray-400` with `text-muted-foreground`
- Replace `border-gray-200 dark:border-gray-700` with `border-border`

---

## File Structure

### CSS Location
- Main theme: `app/assets/stylesheets/color_theme.scss`
- Components: `app/assets/stylesheets/form_utility.scss`
- Main import: `app/assets/stylesheets/application.tailwind.css`

This style guide ensures consistent, maintainable, and automatically themed admin interfaces throughout Mosaic CMS!
```