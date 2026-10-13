تمام، خلّينا نصمّم التطبيق كمنتج حقيقي قابل للنشر، مش مجرد مجموعة شاشات جميلة. سنبدأ في Google Stitch لتصميم الواجهات كاملة، وبعدها يمكن تحويل التصميم إلى Flutter.

أقترح اسمًا مبدئيًا للتطبيق: Bandwise — Your daily path to IELTS success.

الفكرة الأساسية: تجربة تعلّم ممتعة تشبه تطبيقات تعلّم اللغات، لكن مع تدريب جاد على IELTS Academic، واختبارات تجريبية، وذكاء اصطناعي يساعد المستخدم على تحسين الكتابة والمحادثة.

## 1. الهوية البصرية المقترحة

[Interactive Language Learning: A Gamified & Engaging Approach by Revy Adelinda Vierra on Dribbble](https://images.openai.com/static-rsc-4/pVu9u-gTSmeR37GlLQRwYXMhP_29uQFF5Py_Gc8U1UOABrUwbio449-53DtfYavdJ5tDvEUhl4fOWth1rCSVygr5P4IrjhkF7Wsuz5Xmrw66-LQZH8w3jfNP3fvNa0RVVSomesgGeXoTMp_hAYIlJP2wbB3SZlgI7wGbJmvcUas?purpose=inline)

[dribbble.com](https://dribbble.com/shots/25721361-Interactive-Language-Learning-A-Gamified-Engaging-Approach)

Primary

Purple · #6558D3

Accent

Lime · #DDF6A7

Background

Soft lavender

Text & contrast

Deep charcoal

هذا الاتجاه يعطي إحساسًا بالتعلّم والإنجاز، مع المحافظة على جدية اختبارات IELTS. نريد واجهة سهلة، بطاقات واضحة، رسومات بسيطة، تقدّم بصري، وشخصية مرئية لطيفة يمكن استخدامها كمرشد تعليمي أصلي.

## 2. البرومبت الأساسي لـ Stitch

انسخي البرومبت التالي كاملًا إلى Stitch. كتبته بالإنجليزية لأن ذلك يساعد على تحديد تفاصيل الواجهات ومكوّناتها بدقة.

# Design a Complete Mobile App: Bandwise — IELTS Academic Preparation

## Product vision

Design a complete, polished, production-oriented mobile app UI for **Bandwise**, an independent IELTS Academic preparation and English-learning app.

Bandwise combines:

- The engaging, gamified learning experience of modern language-learning apps.
- Realistic IELTS Academic practice across Listening, Reading, Writing, and Speaking.
- AI-powered educational feedback for writing and speaking.
- Structured learning paths, spaced repetition, daily goals, progress analytics, and full-length mock exams.

The product must feel like a real, cohesive mobile application, not a collection of unrelated concept screens.

**Important:** Bandwise is an independent educational product, not affiliated with or endorsed by IELTS, the British Council, IDP, or Cambridge. Do not use their official logos, proprietary artwork, or copied test questions. Create original sample exercises that reproduce the general structure and difficulty of IELTS-style practice without copying protected content.

## 1. Target audience

Design for:

- University applicants and scholarship seekers.
- Beginners and intermediate English learners progressing toward IELTS readiness.
- Learners who need a clear daily study plan.
- Users who feel anxious about speaking English.
- Students preparing for IELTS Academic for postgraduate study.
- Global users, with English as the primary interface language and a future-ready structure for Arabic localization.

The interface should be welcoming to beginners while remaining credible and useful for advanced learners.

## 2. Visual design system

Create a distinctive visual identity using:

- Primary purple: #6558D3.
- Dark text: #25243A.
- Soft lavender background: #F7F6FC.
- Lime accent: #DDF6A7.
- White cards with subtle borders and soft shadows.
- Success green, warning amber, and error red used consistently.
- Rounded cards, approximately 16–22 px corner radius.
- Clear spacing, strong typographic hierarchy, and accessible contrast.
- A modern sans-serif font such as Inter.
- Friendly, original illustrations used sparingly.
- Simple line icons and consistent icon sizing.
- Smooth, encouraging visual feedback for completed lessons and milestones.

Avoid childish graphics, excessive gradients, cluttered dashboards, generic AI-generated text-heavy illustrations, and overly decorative interfaces.

Support responsive layouts, mobile-first composition, safe areas, keyboard visibility, and scrollable content.

Design both light and dark mode if feasible, prioritizing the complete light-mode experience first.

## 3. Navigation and app structure

Use a five-item bottom navigation bar:

1. Home
2. Learn
3. Practice
4. Progress
5. Profile

Use contextual navigation inside lessons and mock exams. During a timed mock exam, hide the normal bottom navigation and provide a focused, distraction-free testing interface.

Create reusable components for:

- Primary and secondary buttons.
- Skill cards.
- Lesson cards.
- Progress bars and circular progress indicators.
- XP, streak, and daily-goal indicators.
- Question options and answer fields.
- Audio players and recording controls.
- Timer and section progress indicators.
- AI feedback cards.
- Empty, loading, error, success, and offline states.
- Confirmation dialogs and bottom sheets.

## 4. Design EVERY screen in the following sections

Do not stop after the home screen. Create the full screen set with consistent components, realistic content, meaningful navigation, and complete user journeys.

### A. Onboarding and authentication

Screen 1 — Splash screen:

- Bandwise wordmark.
- Original, minimal learning-path symbol.
- Short tagline: "Small steps. Stronger English."

Screen 2 — Welcome:

- Friendly hero illustration.
- Sign up and log in buttons.
- Continue as guest option.
- Clear statement that this is an independent preparation app.

Screen 3 — Learning goals:

- Choose target IELTS band, such as 6.0, 6.5, 7.0, 7.5, or 8.0+.
- Explain that the goal is a target, not a guaranteed result.

Screen 4 — Exam date:

- Optional date picker.
- "I haven't booked my exam yet" option.

Screen 5 — Current English level:

- Beginner, elementary, intermediate, upper-intermediate, advanced.
- Explain that this is an initial self-assessment, not an official CEFR result.

Screen 6 — Daily study commitment:

- 10, 15, 20, 30, or 45 minutes.
- Optional reminder time.

Screen 7 — Skill priorities:

- Listening, Reading, Writing, Speaking.
- Allow users to select multiple priorities.

Screen 8 — Short placement assessment:

- A few original grammar, vocabulary, and reading questions.
- Progress indicator and option to skip.
- Result should be described as an initial learning recommendation, not an official level.

Screen 9 — Personalized plan:

- Recommended learning path.
- Target and daily goal summary.
- Start learning button.

Screen 10 — Create account:

- Email, password, Google sign-in placeholder, password visibility toggle.
- Validation and loading states.

Screen 11 — Log in and password recovery:

- Email and password.
- Forgot-password flow.
- Helpful error states.

### B. Home and learning journey

Screen 12 — Home dashboard:

- Greeting and profile avatar.
- Current learning streak.
- Daily goal progress.
- XP balance.
- Continue-learning card.
- Recommended next lesson.
- Four IELTS skill shortcuts.
- Upcoming review cards.
- Weekly mini-progress chart.

Screen 13 — Learn tab:

- A vertically arranged learning path with connected lesson nodes.
- Units organized by themes and skills.
- Locked, available, completed, and review-required lesson states.
- Visible unit completion percentages.

Screen 14 — Unit overview:

- Unit objective.
- Estimated duration.
- Lessons, checkpoints, and review tasks.
- Start or continue button.

Screen 15 — Lesson introduction:

- Learning objective.
- Estimated time.
- Short explanation.
- Start exercise button.

Screen 16 — Vocabulary exercise:

- Word, pronunciation placeholder, meaning, contextual example.
- Flashcard interaction.
- Reveal-answer state.
- Save-to-vocabulary option.

Screen 17 — Grammar exercise:

- Short, clear explanation.
- Original fill-in-the-blank and multiple-choice questions.
- Submit, correction, and explanation states.

Screen 18 — Listening micro-lesson:

- Audio player with replay controls.
- Original short recording transcript hidden until review.
- One question at a time.
- Playback and answer states.

Screen 19 — Reading micro-lesson:

- Short original passage.
- Highlightable text.
- Comprehension question.
- Explanation and evidence from the passage after answering.

Screen 20 — Lesson feedback:

- Score and correct answers.
- XP earned.
- Mistakes to review.
- Continue, retry, and return-home actions.

Screen 21 — Daily review:

- Spaced-repetition vocabulary cards.
- Previously missed grammar and reading questions.
- Review queue and completion state.

Screen 22 — Streak and achievement celebration:

- Original illustration.
- Streak milestone.
- XP earned.
- Friendly, restrained celebration animation concept.

### C. IELTS practice center

Screen 23 — Practice dashboard:

- Four large skill cards: Listening, Reading, Writing, Speaking.
- Practice by skill, question type, difficulty, or time available.
- Dedicated mock-exam entry.
- Recent attempts and weak areas.

Screen 24 — Practice configuration:

- Select skill.
- Select difficulty.
- Select question type.
- Choose untimed learning mode or timed practice mode.
- Show estimated duration.

Screen 25 — Practice session introduction:

- Instructions.
- Number of questions.
- Timer policy.
- Explain whether hints and corrections are available in this mode.

### D. Listening practice

Screen 26 — Listening section:

- Audio player and playback status.
- Question navigation.
- Multiple-choice, form completion, note completion, and matching question interfaces.
- Answer input states.
- Clear instruction to listen before submitting.

Screen 27 — Listening results:

- Correct and incorrect responses.
- Original transcript revealed after submission.
- Explanation for each answer.
- Replay incorrect questions.

### E. Reading practice

Screen 28 — Reading test:

- Passage and question panels.
- Responsive split-pane layout on larger screens and accessible stacked layout on phones.
- Countdown timer in timed mode.
- Question navigator.
- Multiple-choice, True/False/Not Given, matching headings, and sentence completion interfaces.
- Answer review markers.
- Highlighting and scrolling support.

Screen 29 — Reading results:

- Score and correct answers.
- Evidence in the passage.
- Explanations for wrong answers.
- Review mistakes and retry actions.

### F. Writing practice and AI feedback

Screen 30 — Writing task selection:

- Task 1: Academic visual-data description.
- Task 2: Essay writing.
- Untimed learning mode and timed test mode.
- Show task-specific recommended time.

Screen 31 — Writing Task 1:

- Original chart, graph, table, map, or process diagram.
- Task prompt.
- Word counter.
- Writing editor.
- Save draft, submit, and timer states.

Screen 32 — Writing Task 2:

- Original essay question.
- Writing editor with paragraph spacing.
- Word counter and timer.
- Draft saving.
- Submit confirmation.
- No AI hints during strict exam mode.

Screen 33 — AI writing feedback loading state:

- Clear progress state.
- Friendly text explaining that the submission is being evaluated.
- Avoid fake precise percentages or fabricated evaluation steps.

Screen 34 — AI writing feedback:

- Separate feedback categories:
  - Task Achievement or Task Response.
  - Coherence and Cohesion.
  - Lexical Resource.
  - Grammatical Range and Accuracy.
- Estimated band range for practice only, with a prominent explanation that this is an AI-generated estimate, not an official IELTS score.
- Strengths and priority improvements.
- Examples of grammar corrections.
- Vocabulary suggestions that preserve the student's intended meaning.
- Paragraph-level feedback.
- Suggested revision plan.
- Original and revised text comparison.
- Rewrite and resubmit action.
- Clear explanation of uncertainty and limitations.

For Task 1, use Task Achievement; for Task 2, use Task Response. Do not present one generic rubric for both tasks.

### G. Speaking practice and AI feedback

Screen 35 — Speaking practice dashboard:

- Part 1, Part 2, and Part 3.
- Confidence-building mode.
- Realistic timed mode.
- Recent speaking attempts and improvement suggestions.

Screen 36 — Part 1 interview:

- One question displayed at a time.
- Audio recording button.
- Recording timer and clear microphone permission state.
- Start, pause where appropriate, stop, and retry controls.
- A calm, non-judgmental visual design.

Screen 37 — Part 2 cue card:

- Original cue card with topic and bullet points.
- Preparation countdown of up to one minute in realistic mode.
- Recording timer of up to two minutes.
- Notes area during preparation.
- Optional untimed learning mode.

Screen 38 — Part 3 discussion:

- Follow-up questions.
- Recording and answer navigation.
- Progress through the session.

Screen 39 — Speech transcription review:

- Transcribed response.
- Audio replay.
- Edit transcription only for transcript corrections, clearly distinguishing edits from the original recording.
- Submit for feedback.

Screen 40 — AI speaking feedback:

- Fluency and Coherence.
- Lexical Resource.
- Grammatical Range and Accuracy.
- Pronunciation feedback only when supported by the audio and available speech-analysis capability.
- Transcript with examples and timestamps when available.
- Useful vocabulary and natural phrasing suggestions.
- Personalized exercises for the next attempt.
- Practice-only estimated band range, never presented as an official score.
- Explain uncertainty, especially when audio quality or accent recognition is limited.

Screen 41 — Speaking confidence mode:

- No visible countdown by default.
- Gentle prompts to help organize ideas.
- Option to record privately.
- Encouraging feedback focused on progress.
- Gradual transition to timed conditions.

### H. Full mock exams

Screen 42 — Mock exam dashboard:

- IELTS Academic practice exam.
- Listening, Reading, Writing, and Speaking sections.
- Estimated total duration.
- Previous mock attempts.
- Start a new mock exam button.

Screen 43 — Mock exam instructions:

- Clear exam rules.
- Timed conditions.
- Explain navigation and answer submission.
- Confirmation before starting.

Screen 44 — Listening mock test:

- Exam-focused interface with countdown and answer navigator.
- No correctness feedback until the section is submitted.

Screen 45 — Reading mock test:

- Long passage layout, question navigator, countdown, and review markers.
- No hints or answer reveals during the test.

Screen 46 — Writing mock test:

- Task 1 and Task 2 navigation.
- Section timer and word counters.
- Draft protection and clear submission controls.
- No AI-generated writing suggestions while the exam is in progress.

Screen 47 — Speaking mock test:

- Part 1, Part 2, and Part 3 in sequence.
- Recording instructions and realistic timing.
- Clear handling of recording interruptions.

Screen 48 — Mock exam submission:

- Review unanswered questions.
- Confirmation dialog.
- Save and submit behavior.

Screen 49 — Mock exam results:

- Listening and Reading raw scores where applicable.
- Writing and Speaking AI practice estimates, clearly labeled.
- Overall practice summary with uncertainty.
- Skill-by-skill analysis.
- Avoid falsely claiming an official overall IELTS band or an exact official conversion where none is justified.
- Review answers and receive a recommended study plan.

### I. Progress and personalization

Screen 50 — Progress dashboard:

- Weekly study time.
- Completed lessons.
- Streak history.
- Skill progress.
- Accuracy trends.
- Mock exam history.
- Target versus current practice performance.

Screen 51 — Skill analytics:

- Listening, Reading, Writing, and Speaking breakdowns.
- Recent attempts.
- Repeated error patterns.
- Recommended next actions.

Screen 52 — Mistake notebook:

- Saved errors.
- Incorrect answers grouped by category.
- Original response and correction.
- Review later action.
- Search and filters.

Screen 53 — Vocabulary notebook:

- Saved words.
- Definitions and examples.
- Pronunciation controls where available.
- Flashcard review.
- Spaced-repetition scheduling.

Screen 54 — Study planner:

- Weekly calendar.
- Daily tasks.
- Estimated study time.
- Reschedule and skip actions.
- Exam countdown if an exam date is configured.

### J. Profile, settings, and supporting screens

Screen 55 — Profile:

- Avatar, learning level, goal band, XP, and achievements.
- Account details and edit profile action.

Screen 56 — Achievements:

- Original badges for streaks, lesson completion, skill milestones, and mock exams.
- Locked and unlocked states.

Screen 57 — Notifications:

- Study reminders.
- Streak reminders.
- Progress summaries.
- Notification preferences.

Screen 58 — Settings:

- Language.
- Light and dark appearance.
- Study reminders.
- Audio and recording preferences.
- Accessibility settings.
- Account security.
- Data and privacy controls.

Screen 59 — Subscription and upgrade:

- Free plan and optional premium plan.
- Clear feature comparison.
- AI usage limits, if applicable.
- Transparent renewal terms and pricing placeholders.
- Restore purchases.
- Do not invent actual prices.

Screen 60 — Privacy and AI transparency:

- How writing and audio are processed.
- Consent before recording or uploading audio.
- Data retention and deletion controls.
- Explain AI feedback limitations.
- Link placeholders for privacy policy and terms.

Screen 61 — Empty, loading, error, and offline states:

- No practice history yet.
- No saved vocabulary.
- Loading lesson content.
- AI evaluation unavailable.
- Network failure with retry.
- Microphone permission denied.
- Audio upload failed.
- Session interrupted and recovery.
- Authentication expired.

Screen 62 — Global dialogs and bottom sheets:

- Exit lesson confirmation.
- Leave timed test confirmation.
- Discard draft confirmation.
- Submit test confirmation.
- Microphone permission explanation.
- Network retry.
- Daily goal completed.
- Achievement unlocked.

## 5. Learning experience and gamification

Build a coherent reward system with:

- XP for completed learning activities.
- Daily goals.
- Study streaks.
- Original achievements.
- Progressive lesson paths.
- Review queues.
- Personalized recommendations.
- Encouraging but respectful copy.

Gamification should reward consistent learning, not pressure users into studying excessively. Do not copy another language-learning app's proprietary character designs, interface, wording, or exact reward system.

## 6. IELTS exam accuracy

Use IELTS Academic conventions for practice design:

- Listening: approximately 30 minutes, with additional transfer time where appropriate for paper-based practice.
- Reading: 60 minutes.
- Writing: 60 minutes total, normally allocating around 20 minutes to Task 1 and 40 minutes to Task 2.
- Speaking: approximately 11–14 minutes, across three parts.

Allow configurable modes where necessary and distinguish computer-based practice from paper-based conventions. Keep instructions accurate, and do not suggest that this app replaces official IELTS materials or guarantees a band score.

Create original, internally consistent questions and visual data. Do not copy official test passages, prompts, charts, or audio recordings.

## 7. Accessibility and usability

- Readable text sizes.
- Accessible contrast.
- Large touch targets.
- Keyboard-aware writing editor.
- Screen-reader-friendly labels.
- Visible focus and selected states.
- Clear validation and error messages.
- Audio controls that do not rely on color alone.
- Recording status that is unmistakable.
- Responsive layouts for smaller phones and tablets.
- Avoid unnecessary animation during timed exams.
- Support future right-to-left Arabic localization.

## 8. Navigation and interaction requirements

Create meaningful connections between screens:

- Onboarding leads to the personalized home dashboard.
- Home leads to a lesson or skill practice.
- Lessons lead to feedback and review.
- Writing submissions lead to AI feedback and revision.
- Speaking recordings lead to transcription and feedback.
- Mock exam sections lead to submission and results.
- Results link to mistake review and recommended lessons.
- Progress links to specific weak skills.
- Profile links to settings, privacy, and subscription screens.

Show realistic selected, disabled, loading, success, and error states wherever relevant.

## 9. Design delivery requirements

Create a complete mobile design system and the entire screen collection.

Prioritize:

1. A consistent design system.
2. All 62 screens listed above, grouped by feature.
3. Reusable components.
4. Consistent typography, spacing, icons, and colors.
5. Realistic original sample content.
6. Connected navigation and representative interaction states.
7. High-fidelity UI rather than rough wireframes.

If all screens cannot fit into one generation, create them in clearly named feature groups without changing the design system between groups. Do not silently omit entire sections.

Start with the design system, onboarding, home dashboard, and learning path. Then continue through all remaining groups until the complete application is designed.

The final product should feel like a polished, approachable, premium-quality learning application that a Flutter developer can realistically implement.

## 3. كيف تستخدمي Stitch للحصول على نتيجة أفضل؟

لا تعتمدي على توليد 62 شاشة في محاولة واحدة فقط؛ أحيانًا الأداة تختصر بعض الشاشات أو تغيّر التصميم بين المجموعات. استخدمي البرومبت الأساسي، ثم أنشئي الشاشات على دفعات.

## 1

ابدئي بالهوية والشاشات الرئيسية

ولّدي نظام الألوان والخطوط والمكوّنات، ثم Splash وOnboarding وHome وLearning Path. اعتمدي هذا التصميم قبل الانتقال لبقية الأقسام.

## 2

صمّمي أقسام المهارات الأربعة

اطلبي Listening وReading وWriting وSpeaking مع جميع الحالات: قبل الحل، أثناء الحل، بعد الإجابة، وبعد انتهاء التدريب.

## 3

أكملي الاختبارات والنتائج

صمّمي الاختبار الكامل والمؤقت والتنقل بين الأسئلة وتسليم الإجابات وصفحة النتائج. حافظي على واجهة هادئة ومختلفة عن واجهة التعلّم اليومية.

## 4

أضيفي التحليلات والإعدادات

أكْملي لوحة التقدم، ودفتر الأخطاء والمفردات، والإعدادات، والخصوصية، والاشتراك، وحالات الخطأ والتحميل.

## 4. برومبت متابعة إذا أنشأ Stitch الشاشات الرئيسية فقط

Continue designing the existing Bandwise project. Preserve the exact established design system, colors, typography, spacing, reusable components, and navigation.

Do not redesign the home dashboard or create another concept. Continue with the next missing screen group from the original requirements.

Create complete high-fidelity mobile screens with realistic original sample content, meaningful navigation, and all relevant states. Include normal, selected, disabled, loading, error, empty, and completed states where appropriate.

After completing each feature group, continue to the next missing group until all requested screens are covered. Do not omit Writing AI feedback, Speaking AI feedback, full mock exams, analytics, privacy, subscription, accessibility, or error-recovery screens.

Keep the application implementation-ready for Flutter, and clearly distinguish practice estimates from official IELTS scores.

## 5. ملاحظات مهمة قبل التنفيذ

- الذكاء الاصطناعي: التصميم وحده لا ينفّذ التصحيح؛ لاحقًا سنحتاج إلى خدمة خلفية تتصل بنموذج AI، وتحفظ المحاولات بأمان، وتعيد تقييمًا منظمًا وفق معايير التدريب.
- الاختبارات: نحتاج إلى محتوى أصلي عالي الجودة، وإجابات صحيحة قابلة للتحقق، ومؤقت يعمل بطريقة موثوقة.
- الصوت: يجب تصميم طلب إذن الميكروفون، والتسجيل، وإعادة المحاولة، والتفريغ النصي، والتعامل مع فشل رفع التسجيل.
- التكلفة: يمكن أن يكون التطبيق مجانيًا في البداية، مع تقييم AI محدود أو خيار تفعيل الخدمة لاحقًا. لا تضعي مفتاح API داخل تطبيق Flutter نفسه.
- الهوية: اسم Bandwise مؤقت إلى أن نتحقق من توفر الاسم والنطاق والعلامة التجارية.

نصيحتي: ابدئي بالتصميم الكامل، لكن عند البرمجة نفّذي أولًا التسجيل، ومسار التعلّم، وReading وVocabulary، ثم أضيفي Writing AI وSpeaking AI. بهذه الطريقة سيكون لديكِ تطبيق قابل للتجربة مبكرًا، ويمكن تطويره تدريجيًا دون التضحية بجودة التصميم.