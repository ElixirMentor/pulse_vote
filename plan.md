# PulseVote Action Plan

**Project Goal:** Build a real-time polling system where users can create polls, vote, and see live results with animated progress bars.

## Phase 1: Project Setup & Foundation
- [ ] Create new Phoenix app with LiveView
- [ ] Set up database (PostgreSQL)
- [ ] Configure basic routing
- [ ] Add Tailwind CSS for styling
- [ ] Create basic layout template

## Phase 2: Core Data Models
- [x] Create Poll schema (title, description, options as embedded schema, created_at)
- [x] Create User schema using phx.gen.auth
- [x] Create Vote schema (poll_id, option_index, user_id, created_at)
- [x] Run migrations
- [x] Add basic validations

## Phase 3: Poll Creation
- [ ] Create poll creation LiveView
- [ ] Build form for poll title/description
- [ ] Add dynamic option inputs (add/remove options)
- [ ] Implement poll creation logic
- [ ] Add basic validation and error handling

## Phase 4: Voting Interface
- [ ] Create poll voting LiveView
- [ ] Display poll title and options
- [ ] Implement voting buttons
- [ ] Store votes with session tracking
- [ ] Prevent duplicate voting per session

## Phase 5: Real-time Results
- [ ] Add PubSub for real-time updates
- [ ] Broadcast vote updates to all viewers
- [ ] Create animated progress bars
- [ ] Show live vote counts
- [ ] Display total votes and percentages

## Phase 6: Polish & Features
- [ ] Add poll listing page
- [ ] Implement poll sharing (URLs)
- [ ] Add basic styling and animations
- [ ] Show "Thanks for voting" states
- [ ] Add poll expiration (optional)

## Phase 7: Testing & Refinement
- [ ] Test real-time updates with multiple browsers
- [ ] Polish UI/UX
- [ ] Add loading states
- [ ] Handle edge cases
- [ ] Final styling touches

## Current Status
**Phase:** Not Started  
**Next Action:** Create new Phoenix app

## Notes
- Keep it simple but satisfying
- Focus on the real-time magic
- Make voting feel instant and responsive
