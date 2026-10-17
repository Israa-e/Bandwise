import '../domain/course.dart';

/// Original course content. Only Lesson 1 of each unit has exercises so far.
const course = Course([
  Unit(
    number: 1,
    title: 'Everyday academic vocabulary',
    focus: 'Vocabulary',
    lessons: [
      Lesson(
        unit: 1,
        number: 1,
        title: 'Words for describing change',
        objective:
            'Use precise words to describe how figures and trends change.',
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
      ),
    ],
  ),
  Unit(
    number: 2,
    title: 'Sentence structure for academic English',
    focus: 'Grammar',
    lessons: [
      Lesson(
        unit: 2,
        number: 1,
        title: 'Clauses and complete sentences',
        objective:
            'Recognise complete sentences and avoid fragments in your '
            'writing.',
        learnItems: [
          'What makes a clause independent',
          'How to spot a sentence fragment',
          'Joining clauses correctly',
        ],
        estimatedMinutes: 8,
        exercises: [
          FlashcardExercise(
            id: 'u2-l1-e1',
            word: 'clause',
            partOfSpeech: 'noun',
            meaning: 'a group of words that contains a subject and a verb',
            example:
                'In "Although the data is limited, the trend is clear", each '
                'part has its own subject and verb.',
            explanation:
                'An independent clause can stand alone as a sentence. A '
                'dependent clause, such as one starting with "although", '
                'cannot.',
          ),
          MultipleChoiceExercise(
            id: 'u2-l1-e2',
            prompt: 'Which of these is a complete sentence?',
            options: [
              'Because the population grew rapidly.',
              'The population grew rapidly.',
              'The rapidly growing population.',
              'Growing rapidly in the cities.',
            ],
            correctIndex: 1,
            explanation:
                'It has a subject ("the population") and a main verb '
                '("grew"), and it does not depend on another clause.',
          ),
          MultipleChoiceExercise(
            id: 'u2-l1-e3',
            prompt: 'What is wrong with this sentence?',
            passage: 'Although many cities have expanded public transport.',
            options: [
              'It is a fragment: it needs a main clause',
              'The verb is in the wrong tense',
              '"Transport" should be plural',
              'Nothing, it is correct',
            ],
            correctIndex: 0,
            explanation:
                'A clause that starts with "although" depends on a main '
                'clause, for example: "…, traffic is still a problem."',
          ),
          FillBlankExercise(
            id: 'u2-l1-e4',
            sentence:
                'The experiment was repeated three times, ____ the results '
                'were consistent.',
            options: ['and', 'despite', 'because of', 'due to'],
            correctIndex: 0,
            explanation:
                '"And" joins two independent clauses. "Despite", "because of" '
                'and "due to" must be followed by a noun phrase, not a '
                'clause.',
          ),
          FillBlankExercise(
            id: 'u2-l1-e5',
            sentence:
                '____ the cost was high, the government approved the '
                'project.',
            options: ['Although', 'Despite', 'However', 'Because of'],
            correctIndex: 0,
            explanation:
                '"Although" introduces a clause with a subject and verb. '
                '"Despite" and "because of" need a noun phrase, and '
                '"however" cannot join two clauses like this.',
          ),
          MultipleChoiceExercise(
            id: 'u2-l1-e6',
            prompt: 'Which sentence is punctuated correctly?',
            options: [
              'Prices rose, demand fell.',
              'Prices rose; demand fell.',
              'Prices rose demand fell.',
              'Prices rose, however demand fell.',
            ],
            correctIndex: 1,
            explanation:
                'A semicolon can join two closely related independent '
                'clauses. A comma alone cannot: that is called a comma '
                'splice.',
          ),
        ],
      ),
      Lesson(
        unit: 2,
        number: 2,
        title: 'Relative clauses',
        objective: 'Add information to nouns with who, which and that.',
        learnItems: [
          'Defining relative clauses',
          'Non-defining relative clauses',
          'Commas with relative clauses',
        ],
        estimatedMinutes: 9,
      ),
      Lesson(
        unit: 2,
        number: 3,
        title: 'The passive in academic writing',
        objective: 'Use the passive to focus on actions and results.',
        learnItems: [
          'Forming the passive',
          'When the passive sounds natural',
          'Avoiding overuse',
        ],
        estimatedMinutes: 9,
      ),
      Lesson(
        unit: 2,
        number: 4,
        title: 'Conditionals for possibilities',
        objective: 'Discuss possible causes and results with conditionals.',
        learnItems: [
          'Real and unreal conditionals',
          'Alternatives to "if"',
          'Hedging with conditionals',
        ],
        estimatedMinutes: 8,
      ),
      Lesson(
        unit: 2,
        number: 5,
        title: 'Building longer noun phrases',
        objective: 'Pack information into precise noun phrases.',
        learnItems: [
          'Pre- and post-modifiers',
          'Prepositional phrases after nouns',
          'Keeping noun phrases clear',
        ],
        estimatedMinutes: 9,
      ),
      Lesson(
        unit: 2,
        number: 6,
        isCheckpoint: true,
        title: 'Unit 2 checkpoint',
        objective: 'Check what you have learned across the unit.',
        learnItems: [
          'Complete sentences and clauses',
          'Relative clauses and the passive',
          'Conditionals and noun phrases',
        ],
        estimatedMinutes: 12,
      ),
    ],
  ),
  Unit(
    number: 3,
    title: 'Paraphrasing and argument structure',
    focus: 'Writing skills',
    lessons: [
      Lesson(
        unit: 3,
        number: 1,
        title: 'Paraphrasing with synonyms',
        objective:
            'Restate ideas in your own words by choosing accurate synonyms.',
        learnItems: [
          'Synonyms that keep the meaning',
          'Changes that alter the meaning',
          'Keeping a formal tone',
        ],
        estimatedMinutes: 8,
        exercises: [
          FlashcardExercise(
            id: 'u3-l1-e1',
            word: 'paraphrase',
            partOfSpeech: 'verb',
            meaning: 'to express the same meaning using different words',
            example:
                'In the introduction, paraphrase the question instead of '
                'copying it.',
            explanation:
                'A good paraphrase keeps the original meaning. Changing words '
                'is not enough if the meaning changes too.',
          ),
          FlashcardExercise(
            id: 'u3-l1-e2',
            word: 'approximately',
            partOfSpeech: 'adverb',
            meaning: 'close to a number or amount, but not exactly',
            example:
                'Approximately half of the participants completed the second '
                'survey.',
            explanation:
                'A formal alternative to "about" or "around" when you give '
                'figures.',
          ),
          MultipleChoiceExercise(
            id: 'u3-l1-e3',
            prompt: 'Which is the best paraphrase?',
            passage: 'The number of people living alone has increased.',
            options: [
              'More people now live on their own.',
              'People prefer to live alone.',
              'Everyone lives alone now.',
              'People living alone has gone.',
            ],
            correctIndex: 0,
            explanation:
                'It keeps the meaning (a rise in people living alone) without '
                'adding new ideas such as a preference.',
          ),
          MultipleChoiceExercise(
            id: 'u3-l1-e4',
            prompt: 'Which word is closest in meaning to "essential" here?',
            passage: 'Clean water is essential for public health.',
            options: ['vital', 'useful', 'common', 'expensive'],
            correctIndex: 0,
            explanation:
                '"Vital" means absolutely necessary, like "essential". '
                '"Useful" is weaker, so it would change the meaning.',
          ),
          FillBlankExercise(
            id: 'u3-l1-e5',
            prompt: 'Choose a formal synonym for "buy".',
            sentence: 'Many consumers now ____ their groceries online.',
            options: ['purchase', 'grab', 'pick up', 'get hold of'],
            correctIndex: 0,
            explanation:
                '"Purchase" is a formal synonym for "buy". The other options '
                'are informal.',
          ),
          MultipleChoiceExercise(
            id: 'u3-l1-e6',
            prompt: 'Which change would alter the meaning of this sentence?',
            passage: 'Some experts believe the policy failed.',
            options: [
              'Changing "some" to "all"',
              'Changing "believe" to "think"',
              'Changing "experts" to "specialists"',
              'Changing "failed" to "was unsuccessful"',
            ],
            correctIndex: 0,
            explanation:
                '"Some" and "all" describe different amounts, so the '
                'paraphrase would no longer be accurate. The other changes '
                'keep the meaning.',
          ),
        ],
      ),
      Lesson(
        unit: 3,
        number: 2,
        title: 'Changing word forms',
        objective:
            'Paraphrase by switching between nouns, verbs and '
            'adjectives.',
        learnItems: [
          'Common word families',
          'Verb to noun changes',
          'Keeping grammar correct after a change',
        ],
        estimatedMinutes: 9,
      ),
      Lesson(
        unit: 3,
        number: 3,
        title: 'Changing sentence structure',
        objective: 'Restate ideas by reorganising the sentence.',
        learnItems: [
          'Active and passive versions',
          'Moving the focus of a sentence',
          'Combining short sentences',
        ],
        estimatedMinutes: 9,
      ),
      Lesson(
        unit: 3,
        number: 4,
        title: 'Building a clear main argument',
        objective: 'State a clear position and keep it throughout an essay.',
        learnItems: [
          'Writing a clear thesis statement',
          'Topic sentences that support it',
          'Staying consistent',
        ],
        estimatedMinutes: 10,
      ),
      Lesson(
        unit: 3,
        number: 5,
        title: 'Supporting ideas with examples',
        objective: 'Develop each point with explanation and examples.',
        learnItems: [
          'Explaining before giving examples',
          'Choosing relevant examples',
          'Linking examples back to the point',
        ],
        estimatedMinutes: 10,
      ),
      Lesson(
        unit: 3,
        number: 6,
        isCheckpoint: true,
        title: 'Unit 3 checkpoint',
        objective: 'Check what you have learned across the unit.',
        learnItems: [
          'Paraphrasing techniques',
          'Argument structure',
          'Supporting ideas',
        ],
        estimatedMinutes: 12,
      ),
    ],
  ),
]);
