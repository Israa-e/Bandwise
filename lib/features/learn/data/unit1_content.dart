import '../domain/course.dart';

/// Unit 1: Everyday academic vocabulary.
const unit1 = Unit(
  number: 1,
  title: 'Everyday academic vocabulary',
  focus: 'Vocabulary',
  lessons: [
    Lesson(
      unit: 1,
      number: 1,
      title: 'Words for describing change',
      objective: 'Use precise words to describe how figures and trends change.',
      learnItems: [
        'Verbs for rising, falling and staying level',
        'Adverbs that show how fast something changed',
        'Formal choices that suit academic writing',
      ],
      estimatedMinutes: 8,
      exercises: [
        FlashcardExercise(
          id: 'u1-l1-e1',
          word: 'fluctuate',
          partOfSpeech: 'verb',
          meaning: 'to rise and fall repeatedly, often within a range',
          example:
              'Energy prices fluctuated throughout the decade, which made '
              'long-term planning difficult.',
          explanation:
              'Use "fluctuate" when a figure goes up and down several times '
              'instead of moving in one direction.',
        ),
        FlashcardExercise(
          id: 'u1-l1-e2',
          word: 'considerable',
          partOfSpeech: 'adjective',
          meaning: 'large in size, amount or importance',
          example:
              'The survey found a considerable increase in the number of '
              'students with part-time jobs.',
          explanation:
              '"Considerable" is more formal than "big" and often comes '
              'before nouns such as increase, amount and difference.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l1-e3',
          prompt:
              'Which verb describes a figure that falls suddenly and by a '
              'large amount?',
          options: ['plummet', 'edge down', 'level off', 'recover'],
          correctIndex: 0,
          explanation:
              '"Plummet" means to fall quickly and steeply. "Edge down" is a '
              'small fall, "level off" means to stop changing, and '
              '"recover" means to rise again after a fall.',
        ),
        FillBlankExercise(
          id: 'u1-l1-e4',
          sentence:
              'After rising for three years, the number of applications '
              '____ and stayed at about the same level.',
          options: ['levelled off', 'soared', 'doubled', 'declined sharply'],
          correctIndex: 0,
          explanation:
              '"Level off" describes a change that stops, so the figure '
              'stays roughly the same afterwards.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l1-e5',
          prompt: 'Which word completes the sentence in a formal style?',
          passage: 'Car ownership in the region rose ____ over the period.',
          options: ['steadily', 'a lot', 'loads', 'kind of'],
          correctIndex: 0,
          explanation:
              '"Steadily" shows gradual, continuous change and suits '
              'academic writing. The other options are informal.',
        ),
        FillBlankExercise(
          id: 'u1-l1-e6',
          sentence:
              'Public spending on research ____ by almost 40% between 2010 '
              'and 2020.',
          options: ['increased', 'increase', 'increasing', 'has increase'],
          correctIndex: 0,
          explanation:
              'The period is finished, so the past simple "increased" is '
              'correct.',
        ),
      ],
    ),
    Lesson(
      unit: 1,
      number: 2,
      title: 'Verbs for research and reporting',
      objective: 'Report what studies and writers say with accurate verbs.',
      learnItems: [
        'Neutral reporting verbs',
        'Verbs that show agreement or doubt',
        'Patterns after reporting verbs',
      ],
      estimatedMinutes: 8,
      exercises: [
        FlashcardExercise(
          id: 'u1-l2-e1',
          word: 'maintain',
          partOfSpeech: 'verb',
          meaning:
              'to keep saying that something is true, even if others disagree',
          example:
              'The author maintains that green spaces improve concentration, '
              'but she offers little data to support the claim.',
          explanation:
              '"Maintain" is stronger than "say": the writer holds a position '
              'firmly, whether or not the evidence is strong. The pattern is '
              '"maintain that" plus a clause.',
        ),
        FlashcardExercise(
          id: 'u1-l2-e2',
          word: 'concede',
          partOfSpeech: 'verb',
          meaning: 'to admit that something is true, often unwillingly',
          example:
              'The researchers concede that their sample was too small to '
              'represent all age groups.',
          explanation:
              'Use "concede" when a writer accepts a weakness or an opposing '
              'point. The pattern is "concede that" plus a clause.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l2-e3',
          prompt:
              'Which verb shows that evidence points towards a conclusion '
              'without fully proving it?',
          passage:
              'The results ____ that students who sleep for eight hours score '
              'higher, although the authors are cautious.',
          options: ['suggest', 'prove', 'insist', 'deny'],
          correctIndex: 0,
          explanation:
              '"Suggest" signals evidence that points towards a conclusion '
              'without proof. "Prove" is too strong for a cautious finding. '
              '"Insist" describes a person\'s firm demand, and "deny" means to '
              'say that something is not true.',
        ),
        FillBlankExercise(
          id: 'u1-l2-e4',
          sentence:
              'The report ____ that average rents in the city have risen faster '
              'than wages.',
          options: ['tells', 'informs', 'mentions to', 'states'],
          correctIndex: 3,
          explanation:
              '"State" can be followed directly by "that" and a clause. "Tell" '
              'and "inform" need a person first ("tells us that", "informs '
              'readers that"), so "tells that" is the tempting but incorrect '
              'choice.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l2-e5',
          prompt:
              'Which sentence makes the writer sound doubtful about the claim?',
          options: [
            'The minister explained that emissions had fallen.',
            'The minister claimed that emissions had fallen.',
            'The minister showed that emissions had fallen.',
            'The minister proved that emissions had fallen.',
          ],
          correctIndex: 1,
          explanation:
              '"Claim" often suggests that the writer is not sure the statement '
              'is true. "Show" and "prove" present it as fact, and "explain" '
              'simply reports it without any doubt.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l2-e6',
          prompt:
              'Which sentence uses the reporting verb with the correct pattern?',
          options: [
            'The authors suggest to reduce class sizes.',
            'The authors suggest for class sizes to reduce.',
            'The authors suggest us reducing class sizes.',
            'The authors suggest that class sizes should be reduced.',
          ],
          correctIndex: 3,
          explanation:
              '"Suggest" is followed by "that" and a clause (or an -ing form, as '
              'in "suggest reducing"). "Suggest to reduce" is the tempting '
              'mistake because verbs such as "want" and "advise" do take "to".',
        ),
      ],
    ),
    Lesson(
      unit: 1,
      number: 3,
      title: 'Nouns for ideas and evidence',
      objective: 'Name ideas, causes and evidence with academic nouns.',
      learnItems: [
        'Nouns for causes and effects',
        'Nouns for evidence and data',
        'Turning verbs into nouns',
      ],
      estimatedMinutes: 9,
      exercises: [
        FlashcardExercise(
          id: 'u1-l3-e1',
          word: 'implication',
          partOfSpeech: 'noun',
          meaning: 'a possible effect or result that is not stated directly',
          example:
              'One implication of the study is that cities need more shaded '
              'public spaces.',
          explanation:
              'Often plural and followed by "for": "implications for policy". '
              'It is the effect you can reasonably expect, not a proven fact.',
        ),
        FlashcardExercise(
          id: 'u1-l3-e2',
          word: 'correlation',
          partOfSpeech: 'noun',
          meaning:
              'a link in which two things change together, without proof that '
              'one causes the other',
          example:
              'The data show a strong correlation between hours of exercise and '
              'reported wellbeing.',
          explanation:
              'A correlation shows a link, not a cause. It is usually followed '
              'by "between ... and ...".',
        ),
        FlashcardExercise(
          id: 'u1-l3-e3',
          word: 'consequence',
          partOfSpeech: 'noun',
          meaning:
              'a result of an action or situation, especially an unwelcome one',
          example:
              'A major consequence of deforestation is the loss of habitat for '
              'many species.',
          explanation:
              'Use "consequence of" plus the cause, or "consequences for" plus '
              'what is affected. It is a stronger, more formal word than '
              '"result".',
        ),
        MultipleChoiceExercise(
          id: 'u1-l3-e4',
          prompt: 'Which sentence uses the noun correctly?',
          options: [
            'There are strong evidences that reading improves vocabulary.',
            'There is a strong evidence that reading improves vocabulary.',
            'There is strong evidence that reading improves vocabulary.',
            'There are strong evidence that reading improves vocabulary.',
          ],
          correctIndex: 2,
          explanation:
              '"Evidence" is uncountable, so it has no plural and no "a/an", and '
              'it takes a singular verb. "Evidences" is the tempting mistake, '
              'made by analogy with countable nouns such as "examples".',
        ),
        FillBlankExercise(
          id: 'u1-l3-e5',
          sentence:
              'Heavy traffic is a major ____ of air pollution in the city centre.',
          options: ['effect', 'cause', 'impact', 'outcome'],
          correctIndex: 1,
          explanation:
              '"Cause" names what produces a result: traffic produces '
              'pollution. "Effect", "impact" and "outcome" name the result, so '
              'they would reverse the relationship.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l3-e6',
          prompt: 'Which noun names the process of analysing data?',
          options: ['analyst', 'analytical', 'analysed', 'analysis'],
          correctIndex: 3,
          explanation:
              '"Analysis" is the noun for the process. "Analyst" is also a '
              'noun, but it names the person who does the work, which is the '
              'tempting mistake. "Analytical" is an adjective and "analysed" is '
              'a verb form.',
        ),
      ],
    ),
    Lesson(
      unit: 1,
      number: 4,
      title: 'Collocations in academic writing',
      objective: 'Combine words the way fluent writers do.',
      learnItems: [
        'Verb and noun pairs',
        'Adjective and noun pairs',
        'Common collocation mistakes',
      ],
      estimatedMinutes: 9,
      exercises: [
        FlashcardExercise(
          id: 'u1-l4-e1',
          word: 'conduct',
          partOfSpeech: 'verb',
          meaning:
              'to organise and carry out research, a survey or an experiment',
          example: 'The team conducted a survey of three hundred commuters.',
          explanation:
              'Formal collocations: conduct research, a survey, an experiment '
              'or an interview. In academic writing it sounds more precise than '
              '"do".',
        ),
        FlashcardExercise(
          id: 'u1-l4-e2',
          word: 'widespread',
          partOfSpeech: 'adjective',
          meaning: 'found or happening in many places or among many people',
          example:
              'There is widespread concern about the cost of university '
              'education.',
          explanation:
              'Common partners: widespread use, support, concern, belief and '
              'damage. It sits before the noun.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l4-e3',
          prompt: 'Which verb collocates with "a conclusion"?',
          options: ['draw', 'do', 'put', 'take'],
          correctIndex: 0,
          explanation:
              'We draw (or reach) a conclusion. "Do", "put" and "take" do not '
              'collocate with it. Learners often say "make a conclusion" by '
              'analogy with "make a decision", but "draw" is the standard '
              'choice.',
        ),
        FillBlankExercise(
          id: 'u1-l4-e4',
          sentence:
              'Researchers must take ethical issues into ____ when they design a '
              'study.',
          options: ['mind', 'thought', 'attention', 'account'],
          correctIndex: 3,
          explanation:
              'The fixed phrase is "take into account" (or "take into '
              'consideration"). "Bear in mind" uses the word "mind", which is '
              'why "take into mind" feels natural, but it is not a phrase in '
              'English.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l4-e5',
          prompt: 'Which adjective collocates with "rainfall"?',
          options: ['heavy', 'big', 'wide', 'strong'],
          correctIndex: 0,
          explanation:
              '"Heavy" is the usual adjective for rain and rainfall. "Strong" is '
              'tempting because it collocates with wind and evidence, but it is '
              'not used with rainfall.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l4-e6',
          prompt: 'Which sentence contains a collocation error?',
          options: [
            'The study made a significant contribution to the field.',
            'Researchers carried out an experiment last spring.',
            'The results raise important questions.',
            'The council did a decision to close the library.',
          ],
          correctIndex: 3,
          explanation:
              'The collocation is "make a decision"; "do" goes with tasks such '
              'as "do research". "Made a contribution" looks odd to some '
              'learners, but it is correct, as are "carry out an experiment" '
              'and "raise questions".',
        ),
      ],
    ),
    Lesson(
      unit: 1,
      number: 5,
      title: 'Linking words for contrast',
      objective: 'Show contrast clearly between ideas and sentences.',
      learnItems: [
        'However, whereas and while',
        'Although and despite',
        'Punctuation with linking words',
      ],
      estimatedMinutes: 8,
      exercises: [
        MultipleChoiceExercise(
          id: 'u1-l5-e1',
          prompt: 'Which word completes the sentence?',
          passage:
              '____ the survey was short, many students did not finish it.',
          options: ['Despite', 'However', 'Although', 'In spite'],
          correctIndex: 2,
          explanation:
              'Rule: "although", "while" and "whereas" join two clauses, each '
              'with its own subject and verb. "Despite" and "in spite of" are '
              'followed by a noun phrase or an -ing form, and "however" links '
              'two separate sentences. "Despite" is the tempting mistake here '
              'because it also shows contrast.',
        ),
        FillBlankExercise(
          id: 'u1-l5-e2',
          sentence:
              'Urban residents usually have good access to hospitals, ____ '
              'people in rural areas often travel long distances for care.',
          options: ['whereas', 'however', 'despite', 'because of'],
          correctIndex: 0,
          explanation:
              '"Whereas" joins two contrasting clauses. "However" needs a full '
              'stop or semicolon before it and a comma after it; after a comma '
              'it creates a comma splice.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l5-e3',
          prompt: 'Which sentence is punctuated correctly?',
          options: [
            'The trial was successful, however the sample was small.',
            'The trial was successful; however, the sample was small.',
            'The trial was successful however, the sample was small.',
            'The trial was successful, however, the sample was small.',
          ],
          correctIndex: 1,
          explanation:
              '"However" needs a semicolon or full stop before it and a comma '
              'after it. A comma before it is a comma splice, and leaving out '
              'the punctuation before "however" gives no break between the two '
              'clauses.',
        ),
        MultipleChoiceExercise(
          id: 'u1-l5-e4',
          prompt:
              'Which sentence expresses the same contrast as "Public transport '
              'is cheap, but it is often unreliable"?',
          options: [
            'Despite public transport is cheap, it is often unreliable.',
            'Public transport is cheap, so it is often unreliable.',
            'Although public transport is cheap, it is often unreliable.',
            'Because public transport is cheap, it is often unreliable.',
          ],
          correctIndex: 2,
          explanation:
              '"Although" keeps the contrast and joins two clauses correctly. '
              '"Despite" cannot be followed by a clause. "So" and "because" '
              'change the meaning from contrast to cause.',
        ),
        FillBlankExercise(
          id: 'u1-l5-e5',
          sentence: '____ the heavy rain, the match went ahead as planned.',
          options: ['Although', 'However', 'Despite', 'Whereas'],
          correctIndex: 2,
          explanation:
              '"Despite" is followed by a noun phrase ("the heavy rain"). '
              '"Although" is the tempting choice, but it needs a subject and '
              'verb ("although it rained heavily").',
        ),
        MultipleChoiceExercise(
          id: 'u1-l5-e6',
          prompt: 'Which sentence uses "while" to show contrast correctly?',
          options: [
            'While I was reading the report, the phone rang.',
            'While the north receives plenty of rain, the south is much drier.',
            'While the north receives plenty of rain. The south is much drier.',
            'The north receives plenty of rain, while however the south is drier.',
          ],
          correctIndex: 1,
          explanation:
              'It uses "while" to contrast two regions. The sentence about '
              'reading the report is also correct, but there "while" means "at '
              'the same time", not contrast. A full stop after the first clause '
              'leaves a fragment, and "while however" uses two linking words '
              'together.',
        ),
      ],
    ),
    Lesson(
      unit: 1,
      number: 6,
      isCheckpoint: true,
      title: 'Unit 1 checkpoint',
      objective: 'Check what you have learned across the unit.',
      learnItems: [
        'Words for change',
        'Reporting verbs and academic nouns',
        'Collocations and contrast',
      ],
      estimatedMinutes: 12,
      exercises: [
        MultipleChoiceExercise(
          id: 'u1-checkpoint-l1-e1',
          prompt: 'Which phrase describes a figure that rose only slightly?',
          options: ['shot up', 'collapsed', 'plunged', 'edged up'],
          correctIndex: 3,
          explanation:
              '"Edge up" means to rise by a small amount. "Shot up" describes a '
              'sudden, large rise, and "plunge" and "collapse" describe falls.',
        ),
        FillBlankExercise(
          id: 'u1-checkpoint-l1-e2',
          sentence:
              'Monthly visitor numbers ____ between 40,000 and 60,000 over the '
              'year, with no clear direction.',
          options: ['soared', 'peaked', 'fluctuated', 'declined'],
          correctIndex: 2,
          explanation:
              '"Fluctuate" describes repeated rises and falls within a range. '
              '"Peak" is a single high point, which is the tempting choice, but '
              'it does not describe movement in both directions.',
        ),
        MultipleChoiceExercise(
          id: 'u1-checkpoint-l2-e1',
          prompt:
              'Which verb is the most neutral way to report what a study found?',
          options: ['boasts', 'reports', 'admits', 'alleges'],
          correctIndex: 1,
          explanation:
              '"Report" simply passes on the finding. "Admit" suggests an '
              'unwelcome truth, "boast" suggests pride, and "allege" suggests a '
              'claim that has not been proved.',
        ),
        FillBlankExercise(
          id: 'u1-checkpoint-l2-e2',
          sentence:
              'The author ____ that the data may not apply to older adults.',
          options: ['persuades', 'acknowledges', 'proves', 'tells'],
          correctIndex: 1,
          explanation:
              '"Acknowledge that" fits both the pattern and the meaning: the '
              'writer accepts a limitation. "Persuade" and "tell" need a person '
              'before "that", and "proves" is far too strong for something the '
              'data "may" not do.',
        ),
        MultipleChoiceExercise(
          id: 'u1-checkpoint-l3-e1',
          prompt: 'Which of these nouns is uncountable?',
          options: ['study', 'survey', 'research', 'experiment'],
          correctIndex: 2,
          explanation:
              '"Research" is uncountable: we say "some research" or "a piece of '
              'research", never "a research" or "researches". "Study", '
              '"survey" and "experiment" are countable.',
        ),
        FillBlankExercise(
          id: 'u1-checkpoint-l3-e2',
          sentence:
              'The ____ of the new policy on small businesses is still unclear.',
          options: ['impacted', 'impactful', 'impacting', 'impact'],
          correctIndex: 3,
          explanation:
              'After "The" and before "of", the sentence needs a noun, so '
              '"impact" is correct. "Impactful" is an adjective, and the other '
              'two are verb forms.',
        ),
        MultipleChoiceExercise(
          id: 'u1-checkpoint-l4-e1',
          prompt: 'Which verb collocates with "a risk"?',
          options: ['make', 'do', 'give', 'take'],
          correctIndex: 3,
          explanation:
              'We take a risk (or run a risk). "Make a risk" is tempting because '
              'we make choices and decisions, but it is not used.',
        ),
        FillBlankExercise(
          id: 'u1-checkpoint-l4-e2',
          sentence: 'Many farmers face ____ competition from imported goods.',
          options: ['hard', 'thick', 'fierce', 'loud'],
          correctIndex: 2,
          explanation:
              '"Fierce competition" is the standard collocation. "Hard" is '
              'tempting because competition can be difficult, but it does not '
              'collocate with the noun.',
        ),
        FillBlankExercise(
          id: 'u1-checkpoint-l5-e1',
          sentence:
              'The first group improved quickly, ____ the second group made '
              'little progress.',
          options: ['despite', 'whereas', 'because of', 'therefore'],
          correctIndex: 1,
          explanation:
              '"Whereas" joins two contrasting clauses. "Despite" and "because '
              'of" need a noun phrase, and "therefore" shows a result, not a '
              'contrast.',
        ),
        MultipleChoiceExercise(
          id: 'u1-checkpoint-l5-e2',
          prompt: 'Which sentence is correct?',
          options: [
            'In spite of the experiment was costly, it continued.',
            'In spite of the high cost, the experiment continued.',
            'Despite of the high cost, the experiment continued.',
            'Despite the experiment was costly, it continued.',
          ],
          correctIndex: 1,
          explanation:
              '"In spite of" is followed by a noun phrase ("the high cost"). '
              '"Despite of" is a common mistake: "despite" is never followed by '
              '"of". A clause cannot follow either phrase.',
        ),
      ],
    ),
  ],
);
