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
- **Supabase JS Client** (`@supabase/supabase-js@2`) - Database and storage
- **Sortable.js** (`sortablejs@1.15.0`) - Drag-and-drop photo reordering

## Supabase Configuration

### Connection Details
- **URL**: `https://fupncptwrevxjlanbnsc.supabase.co`
- **Anon Key**: Embedded in HTML (lines 1337-1338 in index.html, lines 233-234 in admin.html)

### Storage Structure
- Bucket: `wedding-photos`
- Main photos: `main/{timestamp}_{index}_{filename}`
- Admin photos: `admin/{timestamp}_{index}_{filename}` (wedding photos)
- Guest photos: `guest/{timestamp}_{index}_{filename}`
- **Supports**: Images (JPEG, PNG, etc.) and Videos (MP4, MOV, etc.)
- **Compression**: Images are automatically compressed before upload (max 1920x1920px, 80% quality)

### Database Schema
```sql
-- photos table
- id: auto-increment
- image_url: text
- photo_type: text ('main', 'admin', or 'guest')
- uploader_name: text (게스트 사진 업로더 이름)
- password: text (게스트 사진 업로더 비밀번호)
- is_visible: boolean (메인 페이지 노출 여부, 기본값: false)
- display_order: integer (노출 순서, 1-5)
- del_yn: text ('Y' or 'N', 게스트가 삭제한 사진 표시, 기본값: 'N')
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
- meal: text ('no' = 식사 안함, 'yes' = 1명 (레거시), '1'-'11' = 식사 인원 수)
- name: text
- companions: text ('0'-'10' = 동행인 수, 본인 제외)
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
- **Guest Upload** (index.html):
  - Multiple file selection (images and videos)
  - Automatic image compression before upload
  - Preview with removal option
  - Parallel upload (3 files at a time)
  - Uploads to `guest/` path
  - Requires name and password (4+ chars)

- **Admin Upload** (admin.html):
  - Similar to guest upload with compression
  - Uploads to `main/`, `admin/`, or `guest/` paths
  - Progress bar with percentage
  - Visibility and display order management
  - Drag-and-drop reordering for visible photos

- **Gallery Loading**:
  - Tab-based filtering (all/admin/guest photos)
  - Grid layout with lightbox
  - Mobile-optimized grid sizes
  - Click to enlarge images

### Form Submissions
- **RSVP** (index.html):
  - Modal-based form with conditional fields
  - Shows companion/meal fields only when attending
  - Validates all required fields
  - Stores `'0'` for meal/companions when not attending or no meal
  - Inserts into `rsvp` table with timestamp

- **Guestbook** (index.html):
  - Requires name, password (for deletion), message
  - Displays messages in reverse chronological order
  - Delete functionality with password verification
  - Inserts into `guestbook` table

## Styling and UI

### Color Scheme
- Primary green: `#43573a` (buttons, headings)
- Groom color: `#5f8b9b` (blue tone)
- Bride color: `#BB7273` (rose tone)
- Background: `#f5f3ed`, `#fafaf8`

### Responsive Design
- **index.html**:
  - Max container width: `480px`
  - Mobile-first approach
  - Grid layouts for galleries: `repeat(3, 1fr)` for thumbnails
  - Modal scroll lock on mobile to prevent background scrolling

- **admin.html**:
  - Desktop gallery: 180px grid items
  - Tablet (≤768px): 100px grid items, 8px gap
  - Mobile (≤480px): 90px grid items, 6px gap
  - Scaled badges and buttons for touch targets
  - Touch-optimized drag-and-drop

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
- Call `lockBodyScroll()` when opening modal
- Call `unlockBodyScroll()` when closing modal
- Set up background click listener in `initPage()`
- Add `modal.classList.add/remove('active')` for show/hide
- Background scroll is prevented on mobile devices

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

Image compression logs:
- "[압축] filename.jpg: 3200.5KB → 850.2KB (73% 감소)"
- "[압축 스킵] filename.jpg: 압축 효과 없음"
- "[압축 시작] 총 5개 파일"
- "[압축 완료]"

Check browser console for these messages to verify proper initialization and compression performance.

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
- **Groom**: 서정원, Phone: 010-8358-7077
- **Bride**: 제시현, Phone: 010-4764-8574
- **Location**: 부산 라온 웨딩홀 23층 화이트홀
  - Address: 부산광역시 부산진구 중앙대로 640, ABL부산타워 23층
  - Tel: 1588-3820
  - Naver Map: https://map.naver.com/p/entry/place/34698403
  - Kakao Map: https://place.map.kakao.com/25639730
  - T Map: tmap://route?goalname=라온웨딩홀&goalx=129.0580&goaly=35.1455
- **Wedding Date & Time**: 2026년 10월 4일 토요일 오후 2시 (October 4, 2026 Saturday 2:00 PM)

### Known Issues
- Kakao Maps API may fail to load (fallback text displayed)
- Calendar assumes October 2026 structure (not dynamic)
- D-day counter shows negative after wedding date

## Recent Updates & Improvements

### 1. Page Section Reordering (2026-06-02)
**File**: `index.html`

Sections are now displayed in the following order:
1. 메인사진 (Main photos slider)
2. 문구 (Invitation message)
3. 웨딩사진 (Wedding gallery)
4. 달력 (Calendar)
5. 지도 (Location map)
6. 참석여부 (RSVP)
7. 디데이 (D-day countdown)
8. 계좌번호 (Account information)
9. 방명록 (Guestbook)
10. 참석자 사진 업로드 (Guest photo upload)

### 2. Admin Page Visibility Limit Bug Fix (2026-06-02)
**File**: `admin.html`

Fixed the issue where setting max visibility count (e.g., 5 photos) didn't work correctly when adding photos via batch selection.

**Changes:**
- Updated `checkVisibilityLimit()` function to use dynamic `maxLimits` instead of hardcoded constants
- Added pending visibility changes reflection to accurately calculate current visible count
- Now respects user-configured max limits in real-time

**Location**: Lines ~2021-2060

### 3. Image Compression & Upload Optimization (2026-06-02)
**Files**: `index.html`, `admin.html`

Implemented automatic image compression for faster loading and reduced bandwidth usage.

**Features:**
- **Auto Image Compression**:
  - Max size: 1920x1920px (maintains aspect ratio)
  - JPEG quality: 80%
  - Uses original if compressed size is larger
  - Console logs compression ratio (e.g., "3.2MB → 850KB, 73% reduction")

- **Parallel Upload**:
  - Uploads 3 files concurrently instead of sequential
  - ~3x faster for bulk uploads

- **Video Support**:
  - Accepts both images and videos: `accept="image/*,video/*"`
  - Videos uploaded without compression
  - UI updated to "사진/동영상 선택하기"

**Functions:**
- `compressImage(file, maxWidth, maxHeight, quality)` - Compresses images using Canvas API
- Modified `uploadPhotos()` (index.html) and `uploadImages(type)` (admin.html) to use compression

**Performance:**
- Typical compression: 70-85% size reduction
- Main page load: ~15MB → ~3MB (5 photos)
- Mobile 4G: 3s → 0.6s loading time

### 4. Admin Page Mobile Optimization (2026-06-02)
**File**: `admin.html`

Improved mobile experience for photo management on small screens.

**Grid Size Changes:**
- Desktop: 180px (unchanged)
- Tablet (≤768px): 100px → ~4-5 images per row
- Mobile (≤480px): 90px → ~4 images per row

**Badge & Button Scaling:**
- Display order badge: 40px → 30px (tablet) → 26px (mobile)
- Remove button: 30px → 24px (tablet) → 20px (mobile)
- Visibility badge: Reduced font size and padding
- Gap spacing: 15px → 8px (tablet) → 6px (mobile)

**Touch Optimization:**
- Enhanced drag-and-drop for mobile:
  - `touchStartThreshold: 3` - 3px movement to start drag
  - `delayOnTouchOnly: true` - Slight delay only for touch
  - `forceFallback: false` - Uses HTML5 DnD for smoother experience

**Result**: 12-16 images visible per screen on mobile devices

**Location**: Lines ~83-142 (CSS media queries), ~1820-1837 (Sortable config)

### 5. Modal Background Scroll Prevention (2026-06-02)
**File**: `index.html`

Fixed issue where background page scrolled when modal/popup was open on mobile devices.

**Implementation:**
- `lockBodyScroll()`: Sets body to `overflow: hidden` and `position: fixed`
- `unlockBodyScroll()`: Restores scroll position after closing
- Applied to all modals and popups:
  - RSVP modal
  - Contact modal
  - My photos modal
  - Lightbox
  - RSVP popup

**Location**: Lines ~2629-2645

### 6. RSVP Conditional Fields (2026-06-02)
**File**: `index.html`

Improved RSVP form UX by showing/hiding fields based on attendance status.

**Behavior:**
- **참석 (Attending)**:
  - Shows: 동행인 수 (companions), 식사 여부 (meal option), 식사 인원 (meal count)

- **불참석 (Not Attending)**:
  - Hides all companion and meal-related fields
  - Saves `companions: '0'` and `meal: '0'` to database

**Data Storage:**
- Attending + meal: `{ companions: '2', meal: '3' }`
- Attending + no meal: `{ companions: '2', meal: '0' }`
- Not attending: `{ companions: '0', meal: '0' }`

**Functions:**
- `toggleAttendanceFields()` - Shows/hides fields based on attendance selection
- Modified `submitRsvp()` - Handles conditional data submission

**Location**: Lines ~1494-1560 (HTML), ~2658-2718 (JavaScript)

### 7. Database Schema Updates

**rsvp table - meal field:**
- `'0'` = 식사 안함 or 불참석 (changed from `null` or `'no'`)
- `'1'`-`'11'` = 식사 인원 수 (본인 포함)

**rsvp table - companions field:**
- `'0'` = 없음 or 불참석 (changed from `null`)
- `'1'`-`'10'` = 동행인 수 (본인 제외)
