# ⚽ Match Details, Timeline Events & Tactical Lineups Standards

This document establishes the UI and domain standards for match details, chronological event timelines, vector event iconography, and tactical pitch lineup board.

---

## 1. Match Details Tab Visibility Rules

Tab display depends strictly on match status:

| Match Status | Allowed Tabs | Hidden Tabs |
| :--- | :--- | :--- |
| **Active Live (`مباشر`)** | All Tabs `[التفاصيل, الأحداث, التشكيلة, الإحصائيات, الترتيب, الهدافون, الصناع, الأخبار]` | None |
| **Finished (`انتهت`)** | All Tabs `[التفاصيل, الأحداث, التشكيلة, الإحصائيات, الترتيب, الهدافون, الصناع, الأخبار]` | None |
| **Upcoming (`لم تبدأ`)** | `[التفاصيل, التشكيلة, الترتيب, الهدافون, الصناع, الأخبار]` | **Events (`الأحداث`)**, **Statistics (`الإحصائيات`)** |
| **Cancelled (`ألغيت`)** | `[التفاصيل, التشكيلة, الترتيب, الهدافون, الصناع, الأخبار]` | **Events (`الأحداث`)**, **Statistics (`الإحصائيات`)** |
| **Postponed (`تأجلت`)** | `[التفاصيل, التشكيلة, الترتيب, الهدافون, الصناع, الأخبار]` | **Events (`الأحداث`)**, **Statistics (`الإحصائيات`)** |

- **Header Score Safeguard**: For upcoming, cancelled, or postponed matches, NEVER display dummy `"0 - 0"` scores. Display kickoff time or status pill.

---

## 2. Match Event Icons & Typography Catalog

All match events are rendered using vector-styled components (`match_event_visual_icon.dart`):

1. **Penalty Scored (`type == 5` / `"penalty_goal"`)**:
   - MUST be rendered visually as a **Goal** with green circular badge (`AppColors.primary`), white soccer ball icon, minute badge, and Arabic label `"ركلة جزاء مسجلة"`.
2. **Penalty Missed (`type == 6` / `"penalty_miss"`)**:
   - Red circular badge (`AppColors.relegationRed`) with a cross/miss icon and label `"ركلة جزاء ضائعة"`.
3. **Missed Chance & Woodwork**:
   - Distinct icons for missed open chances and ball hitting crossbar/post.
4. **Cards**:
   - Yellow card (`AppColors.yellowCard`), Red card (`AppColors.redCard`), Second yellow into red.
5. **Substitutions**:
   - Twin directional arrows in cyan (`AppColors.substitution`).
6. **VAR Events**:
   - Screen icon in vibrant orange (`AppColors.varEvent`).
7. **Stoppage Time**:
   - Badge indicating additional minutes (e.g., `+4`, `+6`).

### 2.1 Symmetrical Layout Alignment
- Timeline event rows must be symmetrically aligned for both home and away teams:
  - Home events anchored to the home side with reverse child order.
  - Center minute badge anchored between home and away.
  - Away events anchored to the away side.
  - Both RTL and LTR viewports preserve symmetric spacing.

---

## 3. Tactical Pitch Lineup & Player Stats

### 3.1 Tactical Pitch (`match_pitch_widget.dart`)
1. **Pitch Graphics**:
   - Pitch board painted via `PitchPainter` with grass lines, penalty boxes, center spot, and goals.
   - Formations dynamically rendered (4-3-3, 4-2-3-1, 3-5-2, 5-3-2, etc.).
2. **Player Node (`pitch_player_node.dart`)**:
   - Player avatar / circular photo with fallback jersey.
   - Player number and localized display name.
   - Rating pill colored by performance (green for 7.5+, yellow for 6.5–7.4, orange/red for <6.5).
   - Event badges: goals scored, yellow/red cards, captain `(C)` badge.
3. **RTL / LTR Symmetry**:
   - Team halves mirror correctly based on active directionality and home/away assignment.

### 3.2 Player Match Statistics Sheet (`player_match_stats_sheet.dart`)
- Triggered by tapping any starting or substitute player node.
- Displays comprehensive player stats:
  - Match rating badge.
  - Minutes played & substitution status.
  - Goals, assists, shots on target.
  - Total passes & pass accuracy percentage.
  - Tackles, duels won, fouls committed, fouls suffered.
