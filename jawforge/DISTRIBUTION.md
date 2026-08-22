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

---

## 5b · Full localized metadata (Connect requires these per added locale)

**Support URL — same for every locale:** `https://github.com/Meet2147/BuildMyItch`

> Note: **Marathi is not an App Store listing language.** The app UI ships in
> Marathi, but Connect only offers store pages for hi/fr/es/it among our set.

### Hindi (hi)

Keywords (72 chars):
```
जॉलाइन,mewing,जबड़ा,फेस,चेहरा,एक्सरसाइज़,jawline,looksmax,फिटनेस,glowup
```

Description:
```
आपकी जॉलाइन — अंदाज़ा नहीं, माप।

JawForge आपके चेहरे को Apple के ऑन-डिवाइस Vision इंजन से स्कैन करता है और 60+ फेशियल लैंडमार्क्स को चार ईमानदार मेट्रिक्स में बदलता है:

• जॉ एंगल — आपके जबड़े के कोने की तीक्ष्णता
• जॉ चौड़ाई — जबड़े और चेहरे की चौड़ाई का अनुपात
• निचले चेहरे का संतुलन — क्लासिकल फेशियल अनुपात
• सममिति — जबड़ा मध्य रेखा पर कितना संतुलित है

इनसे बनता है आपका जॉलाइन स्कोर (0–100), साथ में आपका पोटेंशियल स्कोर — नियमित ट्रेनिंग से हासिल होने वाली ऊँचाई — और आपके चेहरे का आकार (स्क्वायर, ओवल, राउंड, हार्ट, डायमंड, लंबा)।

आपके चेहरे के लिए बना प्लान
5 सवालों की शुरुआत (जीवनशैली, सोने की स्थिति, चबाने की आदतें, स्क्रीन टाइम, समय, लक्ष्य) और आपके स्कैन नतीजे मिलकर रोज़ का रूटीन बनाते हैं: म्यूइंग, चिन टक्स, रेज़िस्टेंस प्रेस, च्यूइंग ट्रेनिंग, नेक कर्ल और भी — हर एक में स्टेप-बाय-स्टेप निर्देश, टाइमर और TMJ-सुरक्षा नोट्स।

आदत बनाएँ
डेली हैबिट ट्रैकर (दिनभर टंग पोस्चर, पानी, पीठ के बल सोना, दोनों तरफ़ चबाना), स्ट्रीक्स, स्मार्ट रिमाइंडर और प्रगति चार्ट जो हर स्कैन के साथ आपका स्कोर बढ़ता दिखाता है।

ईमानदार डिज़ाइन
JawForge वह सच बताता है जो बाकी ऐप्स छोड़ देते हैं: बॉडी-फैट प्रतिशत और पोस्चर किसी भी एक्सरसाइज़ से ज़्यादा असर करते हैं। हड्डियों की बनावट आनुवंशिक है — ट्रेनिंग मांसपेशी, पोस्चर और आदतें बदलती है। यह चिकित्सकीय सलाह नहीं है।

प्राइवेट डिज़ाइन
विश्लेषण 100% आपके iPhone पर होता है। फ़ोटो कभी अपलोड या स्टोर नहीं होती। कोई अकाउंट नहीं। कोई ट्रैकिंग नहीं।

JAWFORGE PRO
अनलिमिटेड स्कैन, पूरी हिस्ट्री, अडैप्टिव रूटीन और स्मार्ट रिमाइंडर। साप्ताहिक, वार्षिक (7 दिन फ्री ट्रायल) या लाइफटाइम। फ्री में हफ़्ते में 1 स्कैन और आख़िरी 3 स्कैन।
```

### French (fr)

Keywords (84 chars):
```
machoire,mewing,jawline,visage,scanner,exercice,symetrie,menton,fitness,glowup
```

Description:
```
Votre mâchoire, mesurée — pas devinée.

JawForge scanne votre visage avec le moteur Vision d'Apple, directement sur l'appareil, et transforme plus de 60 points de repère faciaux en quatre mesures honnêtes :

• ANGLE DE LA MÂCHOIRE — la netteté de votre angle mandibulaire
• LARGEUR — le rapport mâchoire/visage
• ÉQUILIBRE DU BAS DU VISAGE — la proportion classique
• SYMÉTRIE — l'équilibre autour de l'axe du visage

Le tout devient votre score de mâchoire (0–100), accompagné de votre score POTENTIEL — le plafond qu'un entraînement régulier peut atteindre — et de la forme de votre visage.

UN PLAN FAIT POUR VOTRE VISAGE
Cinq questions (mode de vie, sommeil, mastication, temps d'écran, budget temps, objectif) plus vos résultats de scan personnalisent une routine quotidienne : mewing, rentrées de menton, presses de résistance, mastication, curls de nuque — avec instructions détaillées, minuteurs et précautions ATM.

CONSTRUISEZ L'HABITUDE
Suivi d'habitudes quotidiennes, séries, rappels intelligents et un graphique de progression qui montre votre score grimper scan après scan.

HONNÊTE PAR CONCEPTION
JawForge dit ce que les autres taisent : le taux de masse grasse et la posture comptent plus que n'importe quel exercice. L'ossature est génétique. Ceci n'est pas un avis médical.

PRIVÉ PAR CONCEPTION
L'analyse s'effectue à 100 % sur votre iPhone. Les photos ne sont jamais envoyées ni stockées. Pas de compte. Pas de suivi.

JAWFORGE PRO
Scans illimités, historique complet, routine adaptative et rappels intelligents. Hebdomadaire, annuel (essai gratuit de 7 jours) ou à vie. Gratuit : 1 scan/semaine et vos 3 derniers scans.
```

### Spanish (es)

Keywords (85 chars):
```
mandibula,mewing,jawline,rostro,escaner,cara,ejercicio,simetria,menton,fitness,glowup
```

Description:
```
Tu mandíbula, medida — no adivinada.

JawForge escanea tu rostro con el motor Vision de Apple, directamente en el dispositivo, y convierte más de 60 puntos faciales en cuatro métricas honestas:

• ÁNGULO MANDIBULAR — la definición de la esquina de tu mandíbula
• ANCHURA — la proporción mandíbula/rostro
• EQUILIBRIO DEL TERCIO INFERIOR — la proporción clásica
• SIMETRÍA — el equilibrio respecto al eje facial

Todo se convierte en tu Puntuación de Mandíbula (0–100), junto con tu puntuación POTENCIAL — el techo que puede alcanzar el entrenamiento constante — y la forma de tu rostro.

UN PLAN HECHO PARA TU CARA
Cinco preguntas (estilo de vida, sueño, masticación, tiempo de pantalla, tiempo disponible, objetivo) más tus resultados personalizan una rutina diaria: mewing, chin tucks, presiones de resistencia, masticación, curls de cuello — con instrucciones paso a paso, temporizadores y precauciones de ATM.

CREA EL HÁBITO
Registro de hábitos diarios, rachas, recordatorios inteligentes y una gráfica de progreso que muestra tu puntuación subir escaneo a escaneo.

HONESTO POR DISEÑO
JawForge dice la verdad que otras apps omiten: el porcentaje de grasa corporal y la postura influyen más que cualquier ejercicio. La estructura ósea es genética. No es consejo médico.

PRIVADO POR DISEÑO
El análisis se realiza al 100 % en tu iPhone. Las fotos nunca se suben ni se guardan. Sin cuenta. Sin rastreo.

JAWFORGE PRO
Escaneos ilimitados, historial completo, rutina adaptativa y recordatorios inteligentes. Semanal, anual (prueba gratis de 7 días) o de por vida. Gratis: 1 escaneo/semana y tus últimos 3.
```

### Italian (it)

Keywords (76 chars):
```
mascella,mewing,jawline,viso,scanner,esercizi,simmetria,mento,fitness,glowup
```

Description:
```
La tua mascella, misurata — non indovinata.

JawForge scansiona il tuo viso con il motore Vision di Apple, direttamente sul dispositivo, e trasforma oltre 60 punti di riferimento facciali in quattro metriche oneste:

• ANGOLO MANDIBOLARE — la nitidezza dell'angolo della mascella
• LARGHEZZA — il rapporto mascella/viso
• EQUILIBRIO DEL VOLTO INFERIORE — la proporzione classica
• SIMMETRIA — l'equilibrio rispetto all'asse del viso

Tutto diventa il tuo punteggio jawline (0–100), insieme al punteggio POTENZIALE — il tetto raggiungibile con un allenamento costante — e alla forma del tuo viso.

UN PIANO FATTO PER IL TUO VISO
Cinque domande (stile di vita, sonno, masticazione, tempo davanti allo schermo, tempo disponibile, obiettivo) più i risultati della scansione personalizzano una routine quotidiana: mewing, chin tuck, pressioni di resistenza, masticazione, curl del collo — con istruzioni passo passo, timer e precauzioni ATM.

COSTRUISCI L'ABITUDINE
Tracker di abitudini quotidiane, serie, promemoria intelligenti e un grafico dei progressi che mostra il punteggio salire scansione dopo scansione.

ONESTO PER PROGETTAZIONE
JawForge dice la verità che altre app tacciono: grasso corporeo e postura contano più di qualsiasi esercizio. La struttura ossea è genetica. Non è un consiglio medico.

PRIVATO PER PROGETTAZIONE
L'analisi avviene al 100 % sul tuo iPhone. Le foto non vengono mai caricate né salvate. Nessun account. Nessun tracciamento.

JAWFORGE PRO
Scansioni illimitate, cronologia completa, routine adattiva e promemoria intelligenti. Settimanale, annuale (prova gratuita di 7 giorni) o a vita. Gratis: 1 scansione a settimana e le ultime 3.
```
