# Buy From Lango - Master UI Implementation Guide

Use the supplied **Buy From Lango Marketplace App Screens** image as the visual reference when building the screens in this guide. Match its green-and-cream palette, rounded cards, compact marketplace layouts, icons, spacing, and bottom navigation where shown. The reference image guides visual design; the screen requirements and copy below define the expected content and behavior.

## Global Design System

- **Primary color:** Deep Forest Green (`#1E5631`)
- **Secondary color:** Earthy Gold (`#F2C94C`)
- **Background:** Off-White Cream (`#F9F9F4`)
- **Text:** Dark Charcoal (`#2C2C2C`); white text over dark images
- **Cards:** White background, 12 px rounded corners, subtle drop shadow
- **Typography:** Sans-serif, bold headers, clean and readable body text
- **Glassmorphism:** `BackdropFilter` with `sigmaX: 10`, semi-transparent white (`Colors.white.withOpacity(0.2)`), and a subtle white border

## App Startup Sequence

### 1. Preloading Screen (`preload_screen.dart`)

- Solid cream background (`#F9F9F4`)
- Centered forest-green `CircularProgressIndicator`
- Wait 2 seconds in `initState`, then navigate to `SplashScreen`

### 2. Splash Screen (`splash_screen.dart`)

- Use a cream background with the transparent circular logo and app name centered in the upper portion.
- Place **“Farmers to Buyers... Directly!”** below the app name in green italic/bold styling.
- Show an agricultural landscape image as a wide band near the bottom, with **“Connecting Lango Farmers to Markets...”** over its lower edge.
- Keep the logo free of a shadow or white box.
- Wait 3 seconds, then navigate to `OnboardingScreen`

### 3. Onboarding Screen (`onboarding_screen.dart`) - 8 slides

- Implement as an 8-page `PageView`.
- Follow the reference composition: show the farmer image in the upper portion and a deep-green content panel in the lower portion, with white title and subtitle, page dots, and a gold **Next** button. Keep **Skip** beneath the button on slides 1-7; replace it with **Get Started** on the final slide.
- Use a glassmorphic container only when it fits the specific image composition; the reference onboarding panel is a solid green panel rather than a glass overlay.
- Both **Skip** and **Get Started** navigate to `HomeScreen`.
- Use the existing onboarding illustrations in numeric order. The zero-based filenames map directly to one-based slide numbers:

| Slide | Asset | Image description | Title | Subtitle |
|---|---|---|---|---|
| 1 | `assets/illustrations/onboarding_0.png` | Man on phone looking happy | Welcome to Buy From Lango | Connect directly with local farmers. Buy and sell fresh produce, livestock, and equipment without middlemen. |
| 2 | `assets/illustrations/onboarding_1.png` | Woman and man exchanging vegetables | Sell Directly & Earn More | Skip the brokers. Trade farm-to-buyer and keep 100% of your hard-earned profits. |
| 3 | `assets/illustrations/onboarding_2.png` | Man giving a thumbs-up with a phone | Buy Fresh & Local | Browse verified listings from trusted farmers right in your district. Quality harvests, guaranteed. |
| 4 | `assets/illustrations/onboarding_3.png` | Happy family giving thumbs-up | Support Local Families | Every purchase you make empowers a farming family in Northern Uganda to grow and thrive. |
| 5 | `assets/illustrations/onboarding_4.png` | Farmer with cow, goat, and chickens | Livestock at Your Fingertips | From cattle and goats to poultry and fresh farm eggs, find exactly what you need for your farm or business. |
| 6 | `assets/illustrations/onboarding_5.png` | Group of youth/agri-preneurs | Hire & Get Hired | Find tractor operators, farm laborers, and agricultural experts instantly. Build your network and grow your agribusiness. |
| 7 | `assets/illustrations/onboarding_6.png` | Market vendors with produce | Know the Real Prices | Check daily market rates for wholesale and retail. Trade with confidence knowing you're getting a fair deal. |
| 8 | `assets/illustrations/onboarding_7.png` | Man looking over field with tractor | Modernize Your Farm | Access tractors, water pumps, and farming equipment for hire or purchase. Ready to take your harvest to the next level? |

## Core App Screens (Post-Onboarding)

### Shared Marketplace Screen Frame

- Follow the reference image's narrow mobile layout, Android status bar, compact spacing, white content surface, and forest-green app bars with white titles and icons.
- Use a back arrow on secondary screens. Keep search, cart, and notification actions in the app bar only where shown.
- Use the five-item bottom navigation on the main marketplace areas shown in the reference: Home, Saved, Sell, Messages, and Profile. Do not force it onto focused flows such as checkout, chat, or listing details.
- Treat the reference as the layout source for component order and visual hierarchy; retain the listed content and actions when adapting it to different device sizes.

### 4. Sign In / Login (`login_screen.dart`)

- Use a white background and a vertically centered, single-column form.
- Stack the logo, **Welcome Back!**, and **Sign in to continue** at the top.
- Add a full-width green **Sign in with Google** button with the Google mark, then a small **OR** divider.
- Place outlined Phone Number or Email and Password fields below; include leading icons and a password visibility toggle.
- Right-align **Forgot Password?** under the password field.
- Use a full-width green **Sign In** button, then the **“Don't have an account? Sign Up”** footer with **Sign Up** in green.

### 5. Home (`home_screen.dart`)

- **Top bar:** green menu button, centered/adjacent **Buy From Lango** brand, and notification action with unread badge.
- **Search:** full-width white rounded field immediately below the bar, with search icon and **“Search products, services...”** placeholder.
- **Hero:** wide farmer-and-produce banner with **“Good Harvest, Better Prices!”** and a gold **Buy Local** pill button.
- **Categories:** compact 3-by-2 icon grid for Crops, Livestock, Equipment, Services, Jobs, and More.
- **Featured Listings:** section heading followed by horizontally scrolling product cards with photo, name, and price.
- Keep the five-item bottom navigation fixed to the bottom; highlight the selected item in gold.

### 6. All Categories (`categories_screen.dart`)

- Green app bar with back arrow, **Categories**, and Search action.
- Place categories in a two-column grid of white rounded cards. Each card has a large rectangular thumbnail above a centered label.
- Arrange the cards as Crops, Livestock, Equipment, Services, Jobs, Vaccines & Drugs, Cooperatives, and Suppliers, following the reference image.

### 7. Crop Sub-Category / List (`crop_list_screen.dart`)

- Green app bar with back arrow, **Crops**, and Search action.
- Add horizontal rounded filter chips below the bar: All (selected green), Maize, Beans, and Rice.
- Show vertically stacked white listing cards. Each row has a crop thumbnail on the left, title and green price/unit in the middle, location below, and an outline Heart action on the right.
- Continue the list for Fresh Maize, Beans, Rice, and Sorghum as shown.

### 8. Listing Detail (`listing_detail_screen.dart`)

- **Image header:** large crop photo across the top with a back control at top-left and Heart action at top-right.
- **Details:** title **Fresh Maize**, prominent green **UGX 1,500 / Kg**, then location and availability.
- **Seller row:** avatar, seller name, verified/trusted label, and rating.
- **Actions:** side-by-side green **Chat Seller** and gold **Make Offer** buttons.
- **Description:** section heading and short product description beneath seller details.
- Pin a full-width green **Buy Now** button to the bottom edge.

### 9. Chat (`chat_screen.dart`)

- Green app bar with back arrow, seller avatar, name, online status, and a call/action icon.
- Use a vertically scrolling conversation: received messages in pale gray/white bubbles aligned left and sent messages in pale green bubbles aligned right; show small timestamps.
- Anchor a rounded message composer at the bottom with attachment, text input, and green send button. Include **Smart Responses** in the composer actions; show the microphone when appropriate.

### 10. Create Listing (`create_listing_screen.dart`)

- Green app bar with back arrow, **Create Listing**, and account/action icon.
- Start the form with a selected listing thumbnail beside a dashed **Add Photos (Max 5)** tile.
- Stack required **Title**, **Category**, and **Description** fields vertically; mark required labels with an asterisk. Use a dropdown affordance for Category.
- Keep a full-width green **Publish Listing** button fixed at the bottom.

### 11. My Listings (`my_listings_screen.dart`)

- Green app bar titled **My Listings**, with relevant account/action icons.
- Add three compact tabs with counts: **Active**, **Sold**, and **Drafts**.
- Show vertical listing rows with thumbnail, title, green price/unit, and a right-aligned status badge such as **Active**.
- Use the full-width green **+ New Listing** action at the bottom, as in the reference.

### 12. Checkout (`checkout_screen.dart`)

- Green app bar titled **Checkout**, with back and cart actions.
- Show a three-step Delivery -> Payment -> Review progress indicator, highlighting the current step.
- Stack white rounded sections for **Order Summary** (thumbnail, item, quantity, total), **Delivery Details**, and **Payment Method**.
- Provide a selectable **Mobile Money (MTN/Airtel)** option with radio control.
- Place a full-width gold **Pay Now** button at the bottom, including a lock icon.

### 13. Notifications (`notifications_screen.dart`)

- Green app bar titled **Notifications**, with back and account/action icons.
- Use vertically stacked notification rows with a colored circular icon, bold title, short message, relative time, and optional trailing chevron.
- Place the red **Clear All** action centered at the bottom.

### 14. My Orders (`my_orders_screen.dart`)

- Green app bar titled **My Orders**, with back and account/action icons.
- Stack compact white order cards. Each row includes a product thumbnail, order ID, date, total, and a right-aligned pale-green **View** button.
- Show the order status (for example, Delivered) within each card and use green for completed status.

### 15. Offers (`offers_screen.dart`)

- Green app bar titled **Offers**, with back and account/action icons.
- Each offer row contains a product thumbnail, product name and price, then the offer amount and buyer/seller attribution.
- Place a compact green **Accept** button on each offer; provide a full-width green **Make Counter Offer** action at the bottom.

### 16. Saved Items (`saved_items_screen.dart`)

- Green app bar titled **Saved Items**, with back and account/action icons.
- Use a vertical list of compact rows with product thumbnail, title, green price, and a red filled Heart action at the right.
- Add a full-width green **View All Saved** action at the bottom when the full collection is not already displayed.

### 17. Profile (`profile_screen.dart`)

- Use a green app bar and a profile header with a large circular avatar, **Joseph Ssebalamu**, and **Member since 2025**.
- Place outlined **Edit Profile** and **My Seller Card** buttons side-by-side.
- Show a compact white menu list with icons and chevrons for My Listings, My Offers, Saved Items, and Transaction History.
- Keep the five-item bottom navigation visible, with Profile selected.
- Use a red **Log Out** action below the profile menu.

### 18. Settings (`settings_screen.dart`)

- Green app bar titled **Settings**, with back and account/action icons.
- Show a single vertical settings menu with a small green icon and trailing chevron for each row: Account Settings, Notifications, Privacy & Security, Language (English), Help & Support, and About App.
- Add a red **Log Out** button at the bottom.

### 19. FAQ (`faq_screen.dart`)

- Green app bar titled **FAQ**, with back and account/action icons.
- Present a vertical accordion of rounded white rows. Questions have trailing expand/collapse chevrons; expand an answer inline.
- Example questions: **How do I buy on Buy From Lango?**, **How do I sell my produce?**, **What are the charges?**, **How do I report a scammer?**, and **Can I use feature phones?**
- Anchor a green **Contact Support** button at the bottom.

### 20. Help & Support (`help_support_screen.dart`)

- Green app bar titled **Help & Support**, with back and account/action icons.
- Use a vertical menu of compact rows with leading icons and trailing chevrons for Contact Us, Report a Problem, App Guide, Terms of Service, and Privacy Policy.
- Put a full-width green **Send Message** action at the bottom.

### 21. Report User (`report_user_screen.dart`)

- Green app bar titled **Report User**, with back and account/action icons.
- Begin with **Select Reason:**, followed by radio rows for Scam/Fraud, Harassment, Fake Listings, Other, and an **Additional Details...** text field.
- Use a full-width gold **Submit Report** button at the bottom.

### 22. Block User (`block_user_screen.dart`)

- Green app bar titled **Block User**, with back and account/action icons.
- Center the confirmation content on a white surface: red warning triangle, **Block This User?**, and a short explanation that blocking hides their listings and messages.
- Add a full-width red **Block User** button, followed by **Cancel**.

### 23. Access via SMS (`access_sms_screen.dart`)

- Green app bar titled **Access via SMS**, with back and account/action icons.
- Center an SMS icon and short explanation that the service works on basic phones.
- Highlight **“Send: BUY LANGO to 8500”** in a wide gold rounded panel.
- Show a brief search/post/buy explanation below the panel.

### 24. Informational Screens

Use a consistent green app bar with back and account/action icons, centered relevant illustration or icon, short explanatory copy, and a full-width bottom action where shown.

- **Privacy Policy:** shield illustration, concise privacy copy, green **Read More** button.
- **Terms of Service:** document icon, brief terms copy, green **Read More** button.
- **Contact Us:** phone/contact icon, phone, email, and location rows; green **Send Message** button.
- **Share App:** share icon, invitation copy, green **Share Now** button.
- **App Guide:** book icon, short guide prompt, green **View Guide** button.
- **About Buy From Lango:** logo, app purpose, and partner logos.
- **About App:** app logo, **Buy From Lango**, version number, and **Built for Lango Farmers & Buyers**.