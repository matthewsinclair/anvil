# Design - ST0002: Basic Phoenix Web Shell Setup

## Approach

The implementation will follow a component-based approach, drawing from the Laksa project's patterns:

1. **Theme First**: Configure DaisyUI with a custom 8-bit/retro theme
2. **Component Architecture**: Build reusable components (header, footer, user menu)
3. **Progressive Enhancement**: Start with basic functionality, enhance as needed
4. **Minimal Dependencies**: Use only what's already in the project

## Design Decisions

### Theme Choice: 8-bit/Retro
- **Rationale**: Reflects the "anvil" metaphor - a tool for forging/crafting
- **Implementation**: Custom DaisyUI theme with terminal-inspired colors
- **Typography**: Favor monospace fonts for that terminal feel

### Component Structure
- **Separate Components**: Each UI element (header, footer, user menu) as its own module
- **Composition**: App layout composes these components
- **State Management**: Leverage Phoenix's assigns for session state

### Authentication Flow
- **Use Existing**: Leverage Ash Authentication already configured
- **Simple Routes**: Standard /sign-in, /sign-out patterns
- **Session Awareness**: Components react to current_user presence

## Architecture

```
lib/anvil_web/
├── components/
│   ├── layouts/
│   │   └── app.html.heex       # Main layout with header/footer
│   └── common/
│       ├── user_menu_component.ex    # Avatar dropdown menu
│       ├── footer_component.ex       # Site footer
│       └── component_helpers.ex      # Shared helpers (gravatar)
├── controllers/
│   └── page_html/
│       └── home.html.heex      # Updated home page
└── router.ex                   # Route definitions
```

## Alternatives Considered

### LiveView Components vs Function Components
- **Chosen**: Function components for simplicity
- **Alternative**: LiveView components for interactivity
- **Rationale**: Keep it simple for basic UI elements

### Theme Approach
- **Chosen**: Single custom DaisyUI theme
- **Alternative**: Multiple themes with switcher
- **Rationale**: Simplicity and focused aesthetic

### Layout Structure
- **Chosen**: Simple header → content → footer
- **Alternative**: Sidebar navigation like Laksa
- **Rationale**: Anvil needs less navigation complexity initially