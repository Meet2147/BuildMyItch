# JawForge — App Store distribution kit

Copy-paste source for every field App Store Connect asks for. Fields marked
⚠️ need an action only you can take.

---

## 1 · App identity

| Field | Value |
|---|---|
| App name (30 max) | `JawForge` |
| Subtitle (30 max) | `Jawline Scanner & Coach` |
| Bundle ID | `com.buildmyitch.jawforge` |
| SKU | `jawforge-ios-001` |
| Primary language | English (U.S.) |
| Primary category | Health & Fitness |
| Secondary category | Lifestyle |
| Price | Free (with in-app purchases) |
| Availability | All countries (or start with India + US/EU) |
| Copyright | © 2026 Meet Jethwa |
| Version / Build | 1.0 / 1 |

## 2 · Promotional text (170 max, editable without review)

> Scan your face, get your Jawline Score, and train it up with a plan built
> for you. On-device analysis — your photos never leave your phone.

## 3 · Description (4000 max)

```
Your jawline, measured — not guessed.

JawForge scans your face with Apple's on-device Vision engine and turns 60+
facial landmarks into four honest metrics:

• JAW ANGLE — the sharpness of your jaw corner
• JAW WIDTH — jaw-to-face width ratio
• LOWER-FACE BALANCE — classical facial proportion
• SYMMETRY — how evenly your jaw sits on your midline

They blend into one Jawline Score (0–100), plus your POTENTIAL score — the
ceiling consistent training can realistically reach — and your face shape
(square, oval, round, heart, diamond, oblong).

A PLAN BUILT FOR YOUR FACE
A 5-question onboarding (lifestyle, sleep position, chewing habits, screen
time, time budget, goal) plus your scan results personalize a daily routine:
mewing, chin tucks, resistance presses, chewing training, neck curls and
more — each with step-by-step form cues, timers and TMJ-safety notes.

BUILD THE HABIT
Daily habit tracker (all-day tongue posture, hydration, back sleeping, even
chewing), streaks, smart reminders at the time you actually train, and a
progress chart that shows your score climbing scan after scan.

HONEST BY DESIGN
JawForge tells you the truth other apps skip: body-fat percentage and
posture move your jawline more than any exercise. Bone structure is genetic —
training shapes muscle, posture and habits. Not medical advice.

PRIVATE BY DESIGN
Analysis runs 100% on your iPhone. Photos are processed in memory and
discarded — never uploaded, never stored. No account. No tracking.

IN SIX LANGUAGES
English, हिन्दी, मराठी, Français, Español, Italiano.

JAWFORGE PRO
Unlimited scans, full progress history, adaptive routine, complete metric
breakdowns and smart reminders. Weekly, annual (7-day free trial) or
lifetime. Free tier includes 1 scan/week and your last 3 scans.

Terms: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

## 4 · Keywords (100 chars, comma-separated, no spaces)

```
jawline,mewing,face,scanner,jaw,exercise,looksmax,chisel,symmetry,facial,fitness,glowup
```
(98 chars. Don't repeat "JawForge" — the name already indexes.)

## 5 · Localized store listings

| Locale | Subtitle | Promotional text |
|---|---|---|
| hi | जॉलाइन स्कैनर और कोच | चेहरा स्कैन करें, जॉलाइन स्कोर पाएँ और अपने लिए बने प्लान से ट्रेनिंग करें। विश्लेषण डिवाइस पर ही — फ़ोटो कभी बाहर नहीं जाती। |
| mr | जॉलाइन स्कॅनर आणि कोच | चेहरा स्कॅन करा, जॉलाइन स्कोअर मिळवा आणि तुमच्यासाठी बनलेल्या योजनेने सराव करा. विश्लेषण डिव्हाइसवरच — फोटो कधीही बाहेर जात नाहीत. |
| fr | Scanner de mâchoire + coach | Scannez votre visage, obtenez votre score de mâchoire et entraînez-la avec un plan fait pour vous. Analyse sur l'appareil — vos photos ne quittent jamais votre téléphone. |
| es | Escáner de mandíbula y coach | Escanea tu rostro, obtén tu puntuación de mandíbula y entrénala con un plan hecho para ti. Análisis en el dispositivo — tus fotos nunca salen del teléfono. |
| it | Scanner jawline e coach | Scansiona il viso, ottieni il tuo punteggio jawline e allenala con un piano fatto per te. Analisi sul dispositivo — le foto non lasciano mai il telefono. |

(App UI ships fully localized in all six — App Store Connect auto-detects
this from the build.)

## 6 · Screenshots (in `jawforge/marketing/appstore/`)

| Slot | Size | Files |
|---|---|---|
| iPhone 6.9" | 1320×2868 | `iphone-6.9/1…6.png` |
| iPhone 6.5" | 1242×2688 | `iphone-6.5/1…6.png` |
| iPad 13" | 2064×2752 | `ipad-13/1…6.png` |

Upload order: scan → results → plan → onboarding → progress → pro.

## 7 · Age rating questionnaire

Answer **None/No** to every content question (violence, sexual content,
profanity, drugs, gambling, horror, contests, unrestricted web). Medical/
treatment information: **None** (fitness guidance, no diagnosis/treatment).
Result: **4+**.

## 8 · App Privacy (nutrition label)

- **Data collection: “Data Not Collected.”** The app has no servers, no
  accounts, no analytics; scans and answers stay in on-device storage;
  photos are processed in memory and discarded. Purchases run entirely
  through Apple.
- Camera use is explained by the purpose string already in the build.
- ⚠️ Privacy policy URL (required): host `jawforge/PRIVACY.md` (GitHub
  Pages is fine) and paste the URL here **and** into
  `Entitlements.privacyURL` in code.

## 9 · In-app purchases (create these exactly)

Subscription group: **JawForge Pro**

| Reference name | Product ID | Type | Price tier | Notes |
|---|---|---|---|---|
| Pro Weekly | `com.buildmyitch.jawforge.pro.weekly` | Auto-renewable, 1 week | $3.99 | |
| Pro Annual | `com.buildmyitch.jawforge.pro.annual` | Auto-renewable, 1 year | $29.99 | Add intro offer: 7-day free trial |
| Pro Lifetime | `com.buildmyitch.jawforge.pro.lifetime` | Non-consumable | $79.99 | |

Display name / description (all three): “JawForge Pro <Weekly/Annual/Lifetime>” /
“Unlimited scans, full history, adaptive routine and smart reminders.”
Each IAP needs a review screenshot — use `iphone-6.9/6-pro.png`.

⚠️ Requires the **Paid Applications agreement** signed under Agreements,
Tax, and Banking first.

## 10 · App Review information

- Contact: your name, phone, email (⚠️ fill in).
- Sign-in required: **No** (no accounts).
- Notes for review:

```
JawForge analyzes a selfie entirely on-device with Apple's Vision framework
(VNDetectFaceLandmarksRequest). No photo is uploaded or stored — only
numeric measurements are saved locally. No account or server exists.

To test: complete the 5-screen onboarding, then on the Scan tab either use
the front camera or tap the photo-library button and pick any clear frontal
face photo. Results show the metric breakdown; "Save scan" adds it to
Progress. The paywall (crown icon or after onboarding) sells the Pro
subscription via StoreKit 2; the free tier is fully functional at 1 scan
per week.

The app provides fitness/cosmetic guidance only, states prominently that
bone structure is genetic and that measurements are estimates, and includes
TMJ-safety cautions on jaw exercises. It does not rate attractiveness and
is not a medical app.
```

## 11 · Export compliance

`ITSAppUsesNonExemptEncryption = NO` is set in the build — the app uses
only standard HTTPS. No upload-time questions, no French declaration.

## 12 · Launch checklist (in order)

1. ⚠️ Sign Paid Applications agreement (banking + tax).
2. ⚠️ Host privacy policy; update URL in code + Connect.
3. Create the app record (name, bundle ID, SKU).
4. Create the 3 IAPs + subscription group; attach intro offer to Annual.
5. Fill listing: subtitle, promo, description, keywords, categories,
   screenshots (6.9", 6.5", iPad 13"), age rating, privacy.
6. Xcode: Product → Archive → Distribute App → App Store Connect.
7. Attach the build + the 3 IAPs to version 1.0, add review notes, submit.
```
