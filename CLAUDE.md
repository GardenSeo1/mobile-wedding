# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mobile wedding invitation website (모바일 청첩장) for 서정원 & 제시현's wedding on October 4, 2026. This is a single-page application built with vanilla HTML/CSS/JavaScript that integrates with Supabase for backend functionality.

## Architecture

### Single-File Application Structure
- **index.html** - Main wedding invitation page with all features embedded
- **admin.html** - Admin interface for uploading and managing wedding photos
- **test.html** / **test-simple.html** / **index-minimal.html** - Debug/test pages

### Key Components (all in index.html)
The application is organized into distinct sections, each self-contained:
- Header with wedding date and venue
- Swiper-based image slider for main photos
- Invitation message section
- Couple information with contact modals
- Photo gallery with tabs (all/admin/guest photos)
- Guest photo upload section
- RSVP modal form
- Calendar display for wedding date
- Real-time D-day countdown
- Location map with Kakao Maps integration
- Account information for monetary gifts
- Guestbook with message submission

### Data Flow Architecture
1. **Supabase Client**: Initialized at line 1336-1339 in index.html with public credentials
2. **Storage Bucket**: `wedding-photos` bucket stores all images
3. **Database Tables**:
   - `photos` - Stores image URLs and type (admin/guest)
   - `guestbook` - Stores guest messages with name, password, message
   - `rsvp` - Stores attendance responses with side, attendance, meal, name, companions, message

### State Management
- `selectedFiles[]` - Tracks files selected for upload
- `currentTab` - Active gallery tab ('all', 'admin', or 'guest')
- No complex state management library; uses vanilla JavaScript with DOM manipulation

## Development Commands

### Testing Locally
```bash
# Simple HTTP server (Python 3)
python3 -m http.server 8000

# Then open http://localhost:8000/index.html

# For testing admin page
# Open http://localhost:8000/admin.html
```

### Deployment
This project is deployed via GitHub Pages. Changes pushed to the `main` branch are automatically deployed.

```bash
# Standard git workflow
git add .
git commit -m "Your message"
git push origin main
```

## External Dependencies

All dependencies are loaded via CDN in the HTML files:

### index.html Dependencies
- **Supabase JS Client** (`@supabase/supabase-js@2`) - Database and storage
- **Swiper** (`swiper@11`) - Image carousel
- **AOS** (`aos@2.3.1`) - Scroll animations
- **Kakao Maps** (commented out in production) - Map display

### admin.html Dependencies
- **Supabase JS Client** - Same as index.html

## Supabase Configuration

### Connection Details
- **URL**: `https://fupncptwrevxjlanbnsc.supabase.co`
- **Anon Key**: Embedded in HTML (lines 1337-1338 in index.html, lines 233-234 in admin.html)

### Storage Structure
- Bucket: `wedding-photos`
- Admin photos: `wedding/{timestamp}_{index}_{filename}`
- Guest photos: `guest/{timestamp}_{index}_{filename}`

### Database Schema
```sql
-- photos table
- id: auto-increment
- image_url: text
- photo_type: text ('admin' or 'guest')
- created_at: timestamp

-- guestbook table
- id: auto-increment
- name: text
- password: text
- message: text
- created_at: timestamp

-- rsvp table
- id: auto-increment
- side: text ('groom' or 'bride')
- attendance: text ('yes' or 'no')
- meal: text ('yes' or 'no')
- name: text
- companions: text
- message: text
- created_at: timestamp
```

## Key Functions and Logic

### Critical Initialization (index.html:1830-1880)
- `initPage()` - Main initialization function called on DOMContentLoaded
- Sets up modal event listeners
- Starts D-day countdown (updates every second)
- Loads gallery and guestbook from Supabase
- Initializes map, Swiper, and AOS animations

### Real-time D-day Counter (index.html:1388-1424)
- Wedding date: `2026-10-04T14:00:00`
- Updates every 1000ms
- Calculates days, hours, minutes, seconds
- Displays negative values after wedding date passes

### Calendar Generation (index.html:1346-1385)
- October 2026 calendar
- First day: Thursday (Oct 1st)
- Wedding day highlighted: Oct 4th
- Holiday marked: Oct 5th (대체공휴일)

### Photo Management
- **Guest Upload** (index.html:1526-1570): Multiple file selection, preview, batch upload to `guest/` path
- **Admin Upload** (admin.html:285-340): Similar to guest but uploads to `wedding/` path with progress bar
- **Gallery Loading** (index.html:1459-1491): Tab-based filtering, displays images in grid with lightbox

### Form Submissions
- **RSVP** (index.html:1765-1794): Collects attendance data, inserts into `rsvp` table
- **Guestbook** (index.html:1573-1601): Requires name, password, message; inserts into `guestbook` table

## Styling and UI

### Color Scheme
- Primary green: `#43573a` (buttons, headings)
- Groom color: `#5f8b9b` (blue tone)
- Bride color: `#BB7273` (rose tone)
- Background: `#f5f3ed`, `#fafaf8`

### Responsive Design
- Max container width: `480px`
- Mobile-first approach
- Grid layouts for galleries: `repeat(3, 1fr)` for thumbnails

### Animations
- AOS library for scroll animations with `data-aos="fade-up"` attributes
- Swiper autoplay with 3-second delay
- CSS transitions on buttons and modals

## Common Development Patterns

### Adding a New Section
1. Create section HTML with `<section class="section" data-aos="fade-up">`
2. Add section title with `<div class="section-title">`
3. Style in the `<style>` block before closing `</head>`
4. Add any JavaScript logic in the `<script>` section (after line 1334)

### Adding a New Supabase Table Interaction
1. Define async function with try/catch
2. Use `supabaseClient.from("table_name").method()`
3. Handle errors with console.error and user-friendly alerts
4. Update UI after successful operation

### Modal Pattern
- Create modal HTML with `<div class="modal" id="modalName">`
- Add `openModalName()` and `closeModalName()` functions
- Set up background click listener in `initPage()`
- Add `modal.classList.add/remove('active')` for show/hide

## Testing and Debugging

### Test Pages
- **test.html** - Basic functionality test with timestamp
- **test-simple.html** - Minimal test page
- **index-minimal.html** - Stripped-down version for debugging

### Console Logging
The app logs initialization steps:
- "✅ Supabase 초기화 성공!"
- "✅ Swiper 초기화 성공!"
- "✅ AOS 초기화 성공!"
- "페이지 로드 완료"

Check browser console for these messages to verify proper initialization.

## Important Notes

### Security Considerations
- Supabase anon key is public (acceptable for this use case)
- No authentication required for guest features
- Guestbook uses password for deletion (stored in plain text - not secure but simple)
- No rate limiting on uploads or form submissions

### Browser Compatibility
- Uses modern JavaScript (const, arrow functions, async/await)
- Requires ES6+ support
- Web Share API with fallback to clipboard
- File API for image previews

### Contact Information (Hardcoded)
- Groom: 서정원, phone: 010-8358-7077
- Bride: 제시현, phone: 010-4764-8574
- Location: 네이버 그린팩토리 (placeholder venue)
- Wedding time: 오후 2시 (2:00 PM)

### Known Issues
- Kakao Maps API may fail to load (fallback text displayed)
- Calendar assumes October 2026 structure (not dynamic)
- D-day counter shows negative after wedding date
- No image optimization or compression on upload
- No loading states for Supabase operations beyond button disable
