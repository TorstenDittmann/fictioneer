# Fictioneer Product Documentation

## Product Overview

**Fictioneer** is a distraction-free, AI-assisted desktop writing application purpose-built for fiction writers. It combines minimalist design with intelligent organizational tools and AI-powered writing assistance to help novelists focus on their craft.

### Product Name & Branding
- **Name**: Fictioneer
- **Tagline**: The AI Writing Environment for Novelists
- **Type**: Desktop Application
- **Target Users**: Fiction writers, novelists, short story authors, creative writers

---

## Core Product Pillars

### 1. Distraction-Free Writing Environment
The primary value proposition—a clean, minimalist interface that eliminates visual and cognitive clutter.

**Key Characteristics:**
- Minimal UI that fades into the background during writing sessions
- Focus mode that hides all interface elements except the text editor
- AI-powered writing assistance for continuous writing or rephrasing
- Customizable, carefully designed themes optimized for long writing sessions
- Beautiful typography that prioritizes readability and writing comfort

**User Benefit**: Writers can enter and maintain a deep focus state (flow) without fighting UI complexity or distractions.

### 2. Intelligent Project Organization
Structured file management designed specifically for long-form fiction writing.

**Core Components:**
- **Projects**: Single `.fictioneer` file format containing entire story
- **Chapters**: Top-level organizational units for book structure
- **Scenes**: Sub-units within chapters for detailed scene-level organization
- **Notes**: Built-in system for character development, plot planning, world-building
- **Statistics**: Real-time word/character counting at project, chapter, and scene levels
- **Recent Items**: Quick access to recently edited scenes

**Organizational Features:**
- Visual project overview with hierarchical structure display
- Word count statistics at multiple levels (project, chapter, scene)
- Scene metadata tracking (date created, last edited, word count)
- Color-coding and tagging capabilities for scene organization
- Easy scene reordering and restructuring

**User Benefit**: Writers can focus on writing while Fictioneer handles the organizational complexity of long-form narratives without requiring external project management tools.

### 3. AI-Powered Writing Assistant
Intelligent writing support that respects creative voice and style.

**AI Capabilities:**
- **Context-Aware Continuation**: Suggests story continuations based on story context, not just the last sentence
- **Voice Preservation**: AI learns and respects the writer's unique voice and style
- **Writer's Block Assistance**: Provides contextual suggestions to overcome creative blocks
- **Story Understanding**: Maintains awareness of plot, characters, and narrative continuity
- **Non-Intrusive Design**: Suggestions are offers, not replacements—writer maintains full creative control

**Integration Points:**
- Quick-access suggestion generation while writing
- Customizable suggestion generation parameters
- Ability to accept, modify, or reject suggestions seamlessly
- Optional AI assistance that can be toggled on/off

**Technical Foundation:**
- Powered by `apps/intelligence` service (Bun + Hono API)
- Uses OpenRouter API for LLM capabilities
- Privacy-focused: processes stories locally with no external storage
- Intelligent context window management for story awareness

**User Benefit**: Writers get creative support that enhances rather than replaces their work, helping overcome writer's block while maintaining artistic vision.

### 4. Seamless Project Management
Professional file handling and backup capabilities.

**File Management:**
- **Single File Format**: Entire project (text, structure, metadata) stored in one `.fictioneer` file
- **Automatic Saving**: Continuous auto-save prevents data loss
- **Portable Projects**: Easy backup, sharing, and version control
- **Export Options**: Export to RTF and TXT formats for manuscript preparation
- **Recent Projects**: Quick-access list for returning to active projects

**User Benefit**: Writers never worry about losing work and can easily share, backup, or submit manuscripts without technical complexity.

### 5. Professional Writing Tools
Essential features for manuscript development and preparation.

**Writing Tools:**
- Real-time word counting (project, chapter, scene levels)
- Character counting with and without spaces
- Writing statistics dashboard
- Scene-level metadata (word count, creation date, edit date)
- Chapter statistics aggregation
- Professional typography and formatting

**Export & Distribution:**
- RTF export for manuscript submission to agents/publishers
- TXT export for maximum compatibility
- Formatted output ready for professional review

**User Benefit**: Writers have professional-grade manuscript preparation tools without needing separate applications.

---

## Target Audience

### Primary Users

#### 1. **Novelists and Fiction Writers**
- Writing novels, novellas, or long-form fiction
- Need organizational structure for complex narratives
- Benefit from chapter/scene hierarchy
- Want professional manuscript management
- **Pain Points Addressed**: Complexity of Word/Google Docs for long documents, lack of fiction-specific organization

#### 2. **Minimalist Writers**
- Overwhelmed by feature-heavy word processors
- Value simplicity and focus over functionality
- Prefer clean, distraction-free interfaces
- Resist tools that encourage procrastination (formatting, complexity)
- **Pain Points Addressed**: UI clutter, unnecessary features, context-switching costs

#### 3. **Writers Seeking AI Assistance**
- Want intelligent writing support without over-reliance
- Struggle with writer's block occasionally
- Appreciate tools that respect creative vision
- Want suggestions without AI controlling narrative
- **Pain Points Addressed**: Generic AI tools that ignore voice/style, AI that overwrites rather than assists

#### 4. **Productivity-Focused Creators**
- Know they work better in distraction-free environments
- Track productivity through word count metrics
- Need reliable, stable tools
- Value flow state and deep work
- **Pain Points Addressed**: Notifications breaking focus, UI complexity, unreliable auto-save

### Secondary Users

- **Writing Coaches/Instructors**: Teaching writing students in minimalist methodology
- **NaNoWiMo Participants**: Need focused environment during writing month
- **Writing Communities**: Members seeking alternative to mainstream word processors
- **Indie Authors**: Self-publishing and want professional-grade tools

---

## Competitive Differentiation

### What Makes Fictioneer Different

#### 1. **Purpose-Built for Fiction**
- Every feature designed specifically for fiction writing, not general documents
- Chapter/scene structure inherent to the tool, not bolted on
- Character tracking and story awareness built into organization
- Story-aware AI that understands narrative context
- Contrast: General word processors (Word, Google Docs) treat all writing equally

#### 2. **Intelligent Simplicity**
- Powerful capabilities hidden behind clean interface
- Features emerge only when needed
- No bloat or feature creep
- Every UI element serves writing, not tool exploration
- Contrast: Feature-rich tools (Scrivener, WordPerfect) overwhelm with options

#### 3. **Respectful AI Integration**
- AI is assistant, not author
- Maintains writer's voice and style
- Contextual suggestions improve over time
- Complete creative control remains with writer
- Contrast: Generic AI writing tools that ignore style, ChatGPT interfaces requiring manual prompting

#### 4. **Cross-Platform Native Experience**
- Desktop application (not web-dependent or limited)
- Built with Tauri for lightweight, fast performance
- Native integration with operating system
- Reliable offline operation
- Contrast: Browser-based tools (Google Docs, Notion) with latency and sync issues

#### 5. **Privacy-First Design**
- Stories remain on user's computer
- No cloud storage of creative work
- Optional AI uses privacy-respecting OpenRouter API
- User maintains complete data ownership
- Contrast: Cloud-based tools analyzing and storing user content

#### 6. **Single File Format**
- Entire project in one `.fictioneer` file
- Easy backup, version control, sharing
- No complex file hierarchies to manage
- Portable between computers and operating systems
- Contrast: Scrivener's complex folder structures, Word's multiple files

---

## Key Features Detailed

### Feature: Focus Mode
- Hides all UI elements except text editor
- Customizable font sizes and colors
- Full-screen writing experience
- One-keystroke toggle to show/hide UI
- Optional typewriter mode (cursor centered on screen)

### Feature: Chapter & Scene Organization
- Hierarchical project structure (Project → Chapter → Scene)
- Drag-and-drop scene reordering
- Scene metadata: word count, creation date, edit date
- Scene search and filtering
- Quick navigation between scenes
- Scene notes and planning area

### Feature: Real-Time Statistics
- Live word count display
- Character count (with/without spaces)
- Reading time estimation
- Scene-level statistics
- Chapter-level statistics
- Project-level overview dashboard

### Feature: Auto-Save System
- Continuous background saving
- Never lose work due to crashes
- Save history with recovery options
- Indicator showing save status
- Customizable save frequency

### Feature: Theme Customization
- Multiple pre-designed themes optimized for writing
- Dark mode for reduced eye strain
- Light mode for daylight writing
- Custom color schemes
- Font size adjustment
- Line spacing options

### Feature: Notes System
- Separate notes for character development
- Plot planning and outline sections
- World-building reference notes
- Scene-specific notes
- Global project notes
- Quick reference panel during writing

### Feature: AI Writing Assistance
- Generate continuation suggestions based on story context
- Suggestion panel with accept/modify/reject options
- Customizable suggestion tone and length
- AI learns writer's style over time
- Maintains story continuity and plot awareness
- Optional feature (can be disabled)

### Feature: Export & Distribution
- RTF export for professional manuscript formatting
- TXT export for maximum compatibility
- Formatted output suitable for agent/publisher submission
- Preserves chapter and scene structure in exports
- Export with or without notes

### Feature: Recent Projects
- Quick access to recently worked-on projects
- Project thumbnails and metadata
- One-click project opening
- Recently accessed scenes within projects
- Project filtering and search

---

## Technical Foundation

### Technology Stack
- **Frontend**: SvelteKit with Svelte 5 runes (reactive state management)
- **Desktop Framework**: Tauri (Rust backend, web frontend)
- **AI Backend**: Bun runtime with Hono web framework
- **API Integration**: OpenRouter for language models
- **File Format**: Binary `.fictioneer` format containing project data
- **Build Tool**: Bun package manager and build system
- **Styling**: Tailwind CSS for responsive design

### Architecture Overview

#### Apps/fictioneer (Desktop Application)
- SvelteKit + Tauri desktop app
- Main user interface for writing and project management
- Handles file I/O, local storage, and project management
- Communicates with intelligence service for AI features

#### Apps/intelligence (AI Service)
- Bun + Hono API server
- Text generation and writing assistance
- OpenRouter API integration for LLM access
- Health check endpoint: `GET /health`
- Runs on local machine or remote server

#### Apps/landing-page (Marketing Site)
- SvelteKit marketing website
- Built with Vite and Tailwind CSS
- Product information, pricing (if applicable), and sign-ups
- Sales and marketing content for audience reach

### Key Technical Features
- **Reactive State Management**: Svelte 5 runes for responsive UI
- **Native Desktop Integration**: Tauri provides system integration without Electron bloat
- **Local-First Architecture**: Data stored locally with optional cloud integration
- **Efficient Performance**: Minimal dependencies, optimized for low resource usage
- **Type Safety**: Full TypeScript implementation, no `any` types

---

## Product Positioning

### Market Position
**Niche Focus**: Premium, focused tool for dedicated fiction writers rather than general document tool

### Value Propositions (Ranked by Importance)
1. **Distraction-Free Environment**: Eliminate UI clutter and focus on writing
2. **Fiction-Specific Organization**: Chapter/scene structure inherent to tool design
3. **Intelligent AI Assistance**: Context-aware suggestions that respect writer's voice
4. **Simplicity Without Sacrificing Power**: Professional capabilities in clean interface
5. **Privacy & Ownership**: Your stories remain yours, stored locally

### Ideal Use Cases
- **First-time Novelists**: Learning to organize complex narratives
- **NaNoWiMo Participants**: Need distraction-free environment during writing challenge
- **Experienced Authors**: Seeking cleaner alternative to traditional word processors
- **Minimalist Writers**: Prefer simplicity and focus over features
- **Indie Authors**: Managing self-publishing pipeline with professional tools
- **Writing Communities**: Alternative to mainstream, complex tools

### Success Metrics (For Marketing/Sales)
- **Engagement**: Average session duration, daily/weekly active users
- **Retention**: Project retention, repeat usage patterns
- **Satisfaction**: User testimonials, feature requests vs complaints
- **Growth**: New user acquisition, community growth
- **Adoption**: Writer community penetration, NaNoWiMo adoption

---

## Product Roadmap Themes (Future Considerations)

### Near-Term Focus Areas
- Stability and performance optimization
- AI assistant refinement and context improvement
- Export format expansion (EPUB, PDF, Markdown)
- Cloud sync capabilities (optional, privacy-preserving)

### Medium-Term Possibilities
- Collaboration features for writing groups
- Advanced research integration (linking sources to scenes)
- Writing analytics and insights
- Community sharing and feedback
- Mobile companion app for planning

### Long-Term Vision
- Integrated publishing pipeline
- Advanced AI features (character consistency checking, plot hole detection)
- Integration with literary agent/publisher platforms
- Translation services for international markets
- Professional writing workshop tools

---

## Marketing & Sales Talking Points

### For Writers Overwhelmed by Complexity
"Fictioneer removes the complexity so you can focus on storytelling. No formatting decisions, no feature overwhelm—just you and your words."

### For Writers Seeking AI Help Without Replacement
"Get intelligent suggestions that understand your story and respect your voice. AI assistance that enhances, never replaces, your creativity."

### For Minimalist Philosophy Advocates
"Built on the principle that powerful tools can be beautifully simple. Every feature serves writing, nothing serves distraction."

### For Indie Authors
"Professional manuscript management without the price tag of traditional tools. Your stories, your data, your complete control."

### For Writing Communities & Educators
"The tool that fits how writers actually think. Organize novels like novelists, not like accountants."

---

## Content Creation Guidelines for LLMs

### Use This Document To Generate:
1. **Landing Page Copy**: Hero sections, feature sections, benefit descriptions
2. **Product Descriptions**: App store descriptions, marketplace listings
3. **Marketing Materials**: Email campaigns, social media content, blog posts
4. **Feature Explanations**: In-app help text, onboarding tutorials, feature documentation
5. **Sales Pages**: Pricing pages, comparison pages, case studies
6. **Support Documentation**: User guides, FAQ, troubleshooting guides

### Tone & Voice Guidelines
- **Professional but Approachable**: Expert-level tool, friendly communication
- **Writer-Centric**: Use language that resonates with creative professionals
- **Clear Over Clever**: Prioritize clarity and directness over wordplay
- **Benefit-Focused**: Always connect features to writer benefits
- **Honest**: Don't oversell; acknowledge that Fictioneer is a focused tool for specific needs

### Key Messages to Reinforce
1. Fictioneer is purpose-built for fiction writers
2. It prioritizes focus and simplicity over feature complexity
3. AI assistance respects writer's voice and creative control
4. Privacy and data ownership are built-in, not added on
5. Professional manuscript management is accessible and intuitive

### Avoid/Don't Emphasize
- Comparing feature-for-feature with general word processors (different categories)
- Claiming AI can write for you (it can't and shouldn't)
- Oversimplifying the value of organized structure
- Marketing as replacement for writing skill or creativity
- Emphasizing technical details over writer benefits