---
verblock: "2025-07-24:v1.0: matts - Initial chapter creation"
---
# 6. User Interface

## Design Philosophy

Anvil's user interface embraces a retro-cyberpunk aesthetic that balances nostalgia with modern usability. The design draws inspiration from terminal interfaces and early computing while leveraging modern web capabilities.

### Core Principles

1. **Clarity Over Decoration**: Function drives form
2. **Keyboard-First**: Power users can navigate entirely via keyboard
3. **Information Density**: Show relevant data without clutter
4. **Consistent Patterns**: Predictable interactions across features
5. **Progressive Disclosure**: Advanced features don't overwhelm beginners

## Visual Design

### Colour Palette

```css
/* Primary Colours */
--primary: #00ff00;        /* Matrix green */
--secondary: #ff00ff;      /* Cyberpunk magenta */
--accent: #00ffff;         /* Cyan */

/* Background Colours */
--bg-primary: #0a0a0a;     /* Near black */
--bg-secondary: #1a1a1a;   /* Dark grey */
--bg-tertiary: #2a2a2a;    /* Medium grey */

/* Text Colours */
--text-primary: #e0e0e0;   /* Light grey */
--text-secondary: #a0a0a0; /* Medium grey */
--text-muted: #606060;     /* Dark grey */

/* Status Colours */
--success: #00ff00;
--warning: #ffff00;
--error: #ff0000;
--info: #00ffff;
```

### Typography

```css
/* Font Stack */
--font-mono: 'JetBrains Mono', 'Fira Code', monospace;
--font-sans: 'Inter', system-ui, sans-serif;

/* Font Sizes */
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.125rem;   /* 18px */
--text-xl: 1.25rem;    /* 20px */
--text-2xl: 1.5rem;    /* 24px */
```

## Layout Structure

### Application Shell

```
┌──────────────────────────────────────────────────────────┐
│ Navigation Bar                                           │
│ [Logo] [Org Switcher]           [User Menu] [Settings]   │
├──────────────────────────────────────────────────────────┤
│ Breadcrumbs                                              │
│ Home > Project > Prompt Set > Prompt                     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│                    Main Content Area                     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Responsive Breakpoints

- **Mobile**: < 640px
- **Tablet**: 640px - 1024px
- **Desktop**: > 1024px

## Core Components

### Navigation

#### Organisation Switcher

```html
<div class="dropdown dropdown-end">
  <label class="btn btn-ghost btn-sm">
    <span class="text-primary">Acme Corp</span>
    <svg class="chevron-down" />
  </label>
  <ul class="dropdown-content">
    <li><a>Personal</a></li>
    <li><a>Acme Corp</a></li>
    <li class="divider"></li>
    <li><a>Manage Organisations</a></li>
  </ul>
</div>
```

#### Breadcrumbs

```html
<nav class="breadcrumbs">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/projects">Projects</a></li>
    <li><a href="/projects/123">Customer Service</a></li>
    <li class="active">Email Templates</li>
  </ol>
</nav>
```

### Forms

#### Input Fields

```html
<div class="form-control">
  <label class="label">
    <span class="label-text">Prompt Name</span>
    <span class="label-text-alt">Required</span>
  </label>
  <input type="text" 
         class="input input-bordered input-primary" 
         placeholder="Enter prompt name" />
  <label class="label">
    <span class="label-text-alt text-error">Name is required</span>
  </label>
</div>
```

#### Dynamic Parameter Form

```html
<div class="parameter-list">
  <div class="parameter-item">
    <input type="text" placeholder="Parameter name" />
    <select>
      <option>string</option>
      <option>number</option>
      <option>boolean</option>
    </select>
    <input type="checkbox" /> Required
    <button class="btn btn-ghost btn-sm">Remove</button>
  </div>
  <button class="btn btn-primary btn-sm">Add Parameter</button>
</div>
```

### Data Display

#### Project Card

```html
<div class="card bg-base-200 shadow-xl border-2 border-primary">
  <div class="card-body">
    <h2 class="card-title text-primary">Customer Service</h2>
    <p class="text-secondary">Support team prompts</p>
    <div class="stats">
      <div class="stat">
        <div class="stat-title">Prompt Sets</div>
        <div class="stat-value text-primary">12</div>
      </div>
      <div class="stat">
        <div class="stat-title">Total Prompts</div>
        <div class="stat-value text-primary">47</div>
      </div>
    </div>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">View</button>
    </div>
  </div>
</div>
```

#### Data Table

```html
<table class="table table-zebra">
  <thead>
    <tr>
      <th>Name</th>
      <th>Description</th>
      <th>Created</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="font-mono text-primary">welcome-email</td>
      <td>New user welcome message</td>
      <td>2025-07-24</td>
      <td>
        <button class="btn btn-ghost btn-xs">Edit</button>
        <button class="btn btn-ghost btn-xs">Delete</button>
      </td>
    </tr>
  </tbody>
</table>
```

### Modals and Overlays

#### Command Palette (Cmd+K)

```html
<dialog class="modal" open>
  <div class="modal-box bg-base-300 border-2 border-primary">
    <input type="text" 
           placeholder="Search or jump to..." 
           class="input input-bordered w-full" />
    <div class="command-results">
      <div class="result-item">Projects</div>
      <div class="result-item">Prompt Sets</div>
      <div class="result-item">Recent Prompts</div>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop">
    <button>close</button>
  </form>
</dialog>
```

## Page Layouts

### Dashboard

```
┌────────────────────────────────────────────────────────┐
│ Welcome back, user@example.com                         │
├────────────────────────────────────────────────────────┤
│ Quick Stats                                            │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │
│ │ 3 Projects  │ │ 12 Sets     │ │ 47 Prompts  │        │
│ └─────────────┘ └─────────────┘ └─────────────┘        │
├────────────────────────────────────────────────────────┤
│ Recent Activity                                        │
│ - Updated "Welcome Email" prompt (2 hours ago)         │
│ - Created "Support Responses" set (Yesterday)          │
│ - Added team member jane@example.com (3 days ago)      │
└────────────────────────────────────────────────────────┘
```

### Prompt Editor

```
┌────────────────────────────────────────────────────────┐
│ Edit Prompt: Welcome Email                             │
├───────────────────────────┬────────────────────────────┤
│ Template Editor           │ Parameters                 │
│                           │                            │
│ ┌───────────────────────┐ │ ┌───────────────────────┐  │
│ │ Hello {{ name }},     │ │ │ name    string    ✓   │  │
│ │                       │ │ │ company string    ✓   │  │
│ │ Welcome to            │ │ │                       │  │
│ │ {{ company }}!        │ │ │ [+ Add Parameter]     │  │
│ │                       │ │ └───────────────────────┘  │
│ └───────────────────────┘ │                            │
│                           │ Validation                 │
│ ┌───────────────────────┐ │ ┌───────────────────────┐  │
│ │ [Save] [Preview]      │ │ │ ✓ Template valid      │  │
│ └───────────────────────┘ │ │ ✓ All vars defined    │  │
│                           │ └───────────────────────┘  │
└───────────────────────────┴────────────────────────────┘
```

## Interaction Patterns

### Keyboard Shortcuts

| Shortcut         | Action                  |
|------------------|-------------------------|
| Cmd/Ctrl + K     | Open command palette    |
| Cmd/Ctrl + S     | Save current form       |
| Cmd/Ctrl + Enter | Submit form             |
| Esc              | Close modal/cancel      |
| /                | Focus search            |
| g then p         | Go to projects          |
| g then s         | Go to settings          |
| ?                | Show keyboard shortcuts |

### Form Validation

1. **Real-time Validation**: As user types
2. **Inline Errors**: Below affected fields
3. **Summary Errors**: At form top for submission
4. **Success States**: Green checkmarks for valid fields

### Loading States

```html
<!-- Skeleton loader for content -->
<div class="skeleton h-32 w-full"></div>

<!-- Spinner for actions -->
<button class="btn btn-primary loading">
  <span class="loading loading-spinner"></span>
  Saving...
</button>
```

### Empty States

```html
<div class="empty-state text-center py-12">
  <svg class="mx-auto h-12 w-12 text-secondary" />
  <h3 class="mt-2 text-lg font-medium">No prompts yet</h3>
  <p class="mt-1 text-secondary">Get started by creating your first prompt.</p>
  <div class="mt-6">
    <button class="btn btn-primary">Create Prompt</button>
  </div>
</div>
```

## Accessibility

### ARIA Labels

```html
<button aria-label="Delete prompt" class="btn btn-ghost">
  <svg aria-hidden="true" />
</button>
```

### Focus Management

- Trap focus in modals
- Skip to content link
- Logical tab order
- Focus visible indicators

### Screen Reader Support

- Semantic HTML structure
- Proper heading hierarchy
- Form label associations
- Status announcements

## Mobile Considerations

### Touch Targets

- Minimum 44x44px touch areas
- Adequate spacing between interactive elements

### Responsive Tables

```html
<!-- Stack on mobile -->
<div class="card md:hidden">
  <div class="card-body">
    <h3>Welcome Email</h3>
    <p class="text-sm text-secondary">Created: 2025-07-24</p>
    <div class="card-actions">
      <button class="btn btn-sm">Edit</button>
    </div>
  </div>
</div>
```

### Mobile Navigation

- Hamburger menu for main nav
- Bottom tab bar for common actions
- Swipe gestures for navigation

## Performance

### Optimisations

1. **Code Splitting**: Load features on demand
2. **Image Optimisation**: WebP with fallbacks
3. **Font Loading**: FOUT strategy
4. **CSS Purging**: Remove unused styles
5. **Lazy Loading**: Defer non-critical resources

### Perceived Performance

1. **Skeleton Screens**: Show structure immediately
2. **Optimistic Updates**: Update UI before server confirms
3. **Progressive Enhancement**: Core features work without JS
4. **Instant Feedback**: Immediate response to interactions
