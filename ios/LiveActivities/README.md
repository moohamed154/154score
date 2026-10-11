# Live Activities & Widget Extension Guide

This directory contains the SwiftUI and WidgetKit implementation for 154Score Live Match Activities.

## Files
- `LiveMatchActivityWidget.swift`: SwiftUI views for Dynamic Island (compact, minimal, expanded) and Lock Screen Live Activity banner.

## How to Enable Live Activities in Xcode (macOS)
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select **File > New > Target...**.
3. Select **Widget Extension** and click **Next**.
4. Set:
   - Product Name: `LiveMatchActivityWidget`
   - Include Live Activity: Checked
5. Add `LiveMatchActivityWidget.swift` and `LiveMatchActivityAttributes.swift` to the extension's target membership.
