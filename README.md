<p align="center">
  <a href="https://apps.apple.com/us/app/iron-workout-tracker/id1479893244?itsct=apps_box_link&itscg=30200" target="_blank" rel="noopener noreferrer">
    <img width="180" height="180" src="assets/app_icon_rounded.png" alt="Iron App Icon">
  </a>
</p>

<p align="center">
  <a href="https://apps.apple.com/us/app/iron-workout-tracker/id1479893244?itsct=apps_box_badge&amp;itscg=30200" target="_blank" rel="noopener noreferrer"><img src="assets/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg" alt="Download on the App Store" style="width: 160px"></a>
</p>

# Iron

A modern and completely free weightlifting workout tracker for iOS, written in SwiftUI.

| ![Screenshot 1](assets/screenshot1.png) | ![Screenshot 2](assets/screenshot2.png) | ![Screenshot 3](assets/screenshot3.png) |
|-|-|-|

## Building

**Xcode 13** or later is required.

- Select the "Iron" project in the Xcode sidebar
- Under "Targets", select "Iron"
- Change the "Bundle Identifier", "App Group" and "iCloud Container" to something unique like `com.yourname.Iron`
- Go to the "Signing & Capabilities" tab and select your development team under "Signing > Team"
- Repeat the same process for the other targets where applicable
- Build the `Iron` scheme. (Note that due to a bug in Xcode 14 the scheme for the Iron target might not be autocreated and you'll have to create it manually.)
