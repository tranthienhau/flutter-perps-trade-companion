# Dispatch - Trade Companion: Design System

Brand: postal / "send a letter". Clean, white, minimal. Big primary numbers, small quiet labels.
Motifs: circular postmark stamp mark, perforated postage-stamp edges on ticket cards, envelope and paper plane icons, "Post trade" CTA, "Delivered" stamps on completed items.

## Color (use ONLY these colors; no default violet or indigo, no flat neutral grey)
- Background: #F7FCF4 (faint lime-tinted near-white)
- Surface (cards, sheets): #FFFFFF
- Surface alt (grouped rows, segmented track): #F2F6EE
- Accent (bright lime): #9FE870 - large fills, primary button fill with INK label, active tab pill, current-price dot
- Accent fill (white-label safe): #557D3C ; pressed #4C7036
- Accent tint: #F2FCEB
- Support (peach): #FFB08A decoration only; data series #FF5F03
- Text primary (ink): #141F0C ; secondary #4A5541 ; tertiary #6B7562
- Border hairline #E3E9DE ; input and control border #749F6F
- Long / profit / success text #0E7C3A on tint #E3F4E9
- Short / loss / danger text #CE2020 on tint #FBE5E5
- Warning text #A75906 on tint #FAEFE1
- Gradient (only if white text sits on it): #557D3C -> #4C7036. Prefer no gradients; this brand is clean white.

## Typography
- UI + body: Inter. Display + big numbers: Familjen Grotesk with tabular numerals.
- Display 40/700 (-0.02em) big primary numbers; Title 20/600; Body 16/400; Label 14/500; Caption 13/500.
- Only these 5 sizes. Minimum text 12px (13px chips and tags, 14px safety or legal text).

## Frame
- 393x852 mobile (iPhone 16/17). Keep top ~59px and bottom ~34px safe areas clear.

## Layout
- 8pt spacing scale, 20px screen edge padding, generous whitespace.
- Radius: card 20, control 14, input 12, pill 999.
- Elevation: soft only, 0 1px 2px rgba(20,31,12,.04) + 0 8px 24px rgba(20,31,12,.06).
- One bold focal element per screen (usually a giant number).

## Icons
- One set only: rounded outline (Lucide style), 24px, 1.75 stroke.

## Controls (one spec each, reused on every screen)
- Primary button: full-width pill 56px, fill #9FE870, ink #141F0C label, pressed #8FD660, disabled #E3E9DE fill with #6B7562 label.
- Secondary button: white pill with 1.5px ink border, ink label.
- Input: 12px radius, border #749F6F, focus 2px #9FE870 ring, error #CE2020.
- Card: white, 20px radius, soft shadow. Ticket card: perforated postage-stamp scalloped edge on top.
- Chip: pill, 13px label. Selected chip: ink fill with white label.
- Segmented control: pill track #F2F6EE, selected segment white with soft shadow.
- Bottom sheet: white, 28px top radius, grabber bar, dimmed backdrop rgba(20,31,12,.4).
- Long uses success green with up-arrow; Short uses danger red with down-arrow.

## Shared components
- Bottom tab bar: flat white, hairline top border #E3E9DE, EXACTLY 3 tabs in this order: Trade (paper plane icon), Orders (envelope icon), Positions (stacked layers icon). Active tab: ink label + #9FE870 pill behind the icon. Inactive: #6B7562 icon and label. Never rename, reorder, add or remove tabs. Settings is NOT a tab.
- Header: left = small circular postmark stamp mark + screen title (20/600). Trade screen only: gear icon top-right. When wallet connected: small chip "0x7a3f...91c2" with green dot.

## Imagery
- Real photography only; empty states and onboarding also use real photos or flat 2D vector art. NO 3D renders, claymorphism, isometric, CGI or glossy plastic objects. Photo subjects: envelopes, wax seals, mailboxes, stamps, on white desks in soft daylight.

## Meaning of color
- Red only for Short side, losses, errors and destructive actions. Warnings use the warning color with an icon.

## Copy scope
- Do not mention: Deposit funds, Add funds, Buy crypto, Chart, Candlestick, Portfolio, Analytics, Staking, Airdrop, Token launch, Phone number, Followers, Copy trading. No invented integrations. Person name only: Maya Chen.
