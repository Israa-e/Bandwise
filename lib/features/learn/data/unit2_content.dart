import '../domain/course.dart';

/// Unit 2: Sentence structure for academic English.
const unit2 = Unit(
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
      exercises: [
        MultipleChoiceExercise(
          id: 'u2-l2-e1',
          prompt: 'Which relative pronoun completes the sentence?',
          passage:
              'The researcher ____ designed the study has moved to another '
              'university.',
          options: ['which', 'whom', 'whose', 'who'],
          correctIndex: 3,
          explanation:
              'Rule: a defining relative clause says which noun we mean and '
              'takes no commas. Use "who" for people, "which" for things, and '
              '"that" for either. Here the researcher is the subject of '
              '"designed", so "who" is needed; "whom" is the tempting formal '
              'choice, but it is only for objects.',
        ),
        FillBlankExercise(
          id: 'u2-l2-e2',
          sentence:
              'The report, ____ was published last month, calls for more '
              'funding.',
          options: ['that', 'which', 'what', 'who'],
          correctIndex: 1,
          explanation:
              'A non-defining clause adds extra information between commas, and '
              'it cannot begin with "that". "Which" is used for things. "Who" '
              'is for people.',
        ),
        MultipleChoiceExercise(
          id: 'u2-l2-e3',
          prompt: 'Which sentence is punctuated correctly?',
          options: [
            'Cities that have good public transport attract more residents.',
            'Cities, that have good public transport, attract more residents.',
            'Cities which have good public transport, attract more residents.',
            'Cities, which have good public transport attract more residents.',
          ],
          correctIndex: 0,
          explanation:
              '"That have good public transport" says which cities we mean, so '
              'it is a defining clause and needs no commas. Commas with "that" '
              'are wrong, and a single comma before or after the clause leaves '
              'the punctuation unbalanced.',
        ),
        FillBlankExercise(
          id: 'u2-l2-e4',
          sentence:
              'Students ____ first language is not English may need extra '
              'support.',
          options: ['who', 'which', 'whose', 'whom'],
          correctIndex: 2,
          explanation:
              '"Whose" shows possession: the first language belongs to the '
              'students. "Who" is the tempting choice, but it cannot be '
              'followed directly by a noun like "first language".',
        ),
        MultipleChoiceExercise(
          id: 'u2-l2-e5',
          prompt:
              'Which sentence suggests that only SOME of the students passed?',
          options: [
            'The students, who studied hard, passed the exam.',
            'The students, who passed the exam, studied hard.',
            'The students who studied hard passed the exam.',
            'The students, who all studied hard, passed the exam.',
          ],
          correctIndex: 2,
          explanation:
              'With no commas, "who studied hard" tells us which students we '
              'mean, so the others are not included. With commas, the clause '
              'only adds extra information about all of the students.',
        ),
        FillBlankExercise(
          id: 'u2-l2-e6',
          sentence: 'The data ____ we collected in 2023 were incomplete.',
          options: ['what', 'whose', 'who', 'that'],
          correctIndex: 3,
          explanation:
              'The pronoun is the object of "collected", and "that" is correct '
              'in a defining clause for things. "What" cannot follow a noun, '
              '"who" is for people, and "whose" shows possession.',
        ),
      ],
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
      exercises: [
        MultipleChoiceExercise(
          id: 'u2-l3-e1',
          prompt: 'Which sentence is in the passive voice?',
          options: [
            'Scientists measured the temperature every hour.',
            'The temperature was measured every hour.',
            'The temperature rose every hour.',
            'Scientists were measuring the temperature every hour.',
          ],
          correctIndex: 1,
          explanation:
              'Rule: the passive is a form of "be" plus a past participle ("was '
              'measured"). The object of the active sentence becomes the '
              'subject, and "by" plus the doer is optional. Use it when the '
              'action or result matters more than who did it. "Rose" is '
              'active: it has no "be" plus participle.',
        ),
        FillBlankExercise(
          id: 'u2-l3-e2',
          sentence: 'The samples ____ at -20°C until they were analysed.',
          options: ['stored', 'were stored', 'were storing', 'had store'],
          correctIndex: 1,
          explanation:
              'The samples did not store anything; they received the action, so '
              'the passive "were stored" is correct. "Stored" alone would be '
              'active and needs an object.',
        ),
        MultipleChoiceExercise(
          id: 'u2-l3-e3',
          prompt:
              'The builders are unknown and unimportant. Which sentence is the '
              'most natural in academic writing?',
          options: [
            'Someone built the bridge in 1998.',
            'The bridge was built by someone in 1998.',
            'The bridge was built in 1998.',
            'It was the bridge that was built in 1998 by them.',
          ],
          correctIndex: 2,
          explanation:
              'The passive lets you leave out an unknown or unimportant doer. '
              'The versions with "someone" draw attention to a person who adds '
              'nothing to the point, and "It was the bridge that ..." is clumsy.',
        ),
        FillBlankExercise(
          id: 'u2-l3-e4',
          sentence: 'The results have been ____ in three languages.',
          options: ['published', 'publish', 'publishing', 'publishes'],
          correctIndex: 0,
          explanation:
              'After "have been" the passive needs a past participle: '
              '"published". "Publishing" is tempting because it follows "been" '
              'in continuous forms, but that would not be a passive.',
        ),
        MultipleChoiceExercise(
          id: 'u2-l3-e5',
          prompt: 'Which version is the most direct way to say this?',
          passage:
              'It was decided by the committee that the proposal should be '
              'rejected.',
          options: [
            'The proposal was decided to be rejected by the committee.',
            'It was the committee that decided that the proposal be rejected.',
            'The committee decided to reject the proposal.',
            'The proposal\'s rejection was decided by the committee.',
          ],
          correctIndex: 2,
          explanation:
              'The committee is the important doer, so an active sentence is '
              'shorter and clearer. The passive versions are grammatical, but '
              'overusing the passive makes writing heavy and hides who acted.',
        ),
        MultipleChoiceExercise(
          id: 'u2-l3-e6',
          prompt: 'Which sentence is incorrect?',
          options: [
            'The treatment was developed in Japan.',
            'The accident was happened last year.',
            'Two hundred patients were interviewed.',
            'The gap has been widened by rising costs.',
          ],
          correctIndex: 1,
          explanation:
              '"Happen" has no object, so it cannot be made passive: say '
              '"The accident happened last year". The other sentences use verbs '
              'that take an object (develop, interview, widen).',
        ),
      ],
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
      exercises: [
        MultipleChoiceExercise(
          id: 'u2-l4-e1',
          prompt: 'Which verb form completes the sentence?',
          passage: 'If the government ____ fuel taxes, people will drive less.',
          options: ['raised', 'would raise', 'raises', 'will raise'],
          correctIndex: 2,
          explanation:
              'Rule: a real (first) conditional uses "if" plus the present '
              'simple, then "will" plus a base verb. An unreal (second) '
              'conditional uses "if" plus the past simple, then "would". Never '
              'put "will" directly after "if"; "raised" would need "would" in '
              'the main clause.',
        ),
        FillBlankExercise(
          id: 'u2-l4-e2',
          sentence:
              'If more cities ____ car-free zones, air quality would improve '
              'significantly.',
          options: [
            'introduced',
            'would introduce',
            'introduce',
            'will introduce',
          ],
          correctIndex: 0,
          explanation:
              'The main clause has "would improve", so the "if" clause takes '
              'the past simple: "introduced". Using "would" or "will" after '
              '"if" is the tempting error.',
        ),
        MultipleChoiceExercise(
          id: 'u2-l4-e3',
          prompt:
              'Which sentence has the same meaning as "Unless the funding is '
              'renewed, the project will close"?',
          options: [
            'If the funding is not renewed, the project will close.',
            'Because the funding is not renewed, the project will close.',
            'Although the funding is renewed, the project will close.',
            'If the funding is renewed, the project will close.',
          ],
          correctIndex: 0,
          explanation:
              '"Unless" means "if ... not". The version with "Because" states '
              'that the funding is already not renewed, so it is no longer a '
              'possibility. The versions that say the funding "is renewed" '
              'change the condition itself.',
        ),
        FillBlankExercise(
          id: 'u2-l4-e4',
          sentence: 'The method is reliable ____ it is applied consistently.',
          options: ['although', 'despite', 'provided that', 'whereas'],
          correctIndex: 2,
          explanation:
              '"Provided that" means "only if" and introduces a condition. '
              '"Although" and "whereas" show contrast, and "despite" cannot '
              'be followed by a clause.',
        ),
        MultipleChoiceExercise(
          id: 'u2-l4-e5',
          prompt: 'Which sentence expresses the idea most cautiously?',
          options: [
            'If tickets were cheaper, passenger numbers might increase.',
            'Cheaper tickets always increase passenger numbers.',
            'Cheaper tickets will increase passenger numbers.',
            'Cheaper tickets would definitely increase passenger numbers.',
          ],
          correctIndex: 0,
          explanation:
              'An unreal "if" clause with "might" shows only a possibility. '
              '"Will", "always" and "definitely" present the result as certain, '
              'which is not cautious.',
        ),
        FillBlankExercise(
          id: 'u2-l4-e6',
          sentence:
              'If the experiment ____ repeated, the results might differ.',
          options: ['are', 'will be', 'were', 'would be'],
          correctIndex: 2,
          explanation:
              '"Were" is the formal past form after "if" for an unlikely or '
              'imagined situation. "Are" does not agree with the singular '
              'subject, and "will be" and "would be" cannot follow "if" in this '
              'sentence.',
        ),
      ],
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
      exercises: [
        MultipleChoiceExercise(
          id: 'u2-l5-e1',
          prompt: 'Which noun phrase is correctly formed?',
          options: [
            'the growth rapid of population',
            'the population rapid growth',
            'the growth of rapid population',
            'the rapid growth in population',
          ],
          correctIndex: 3,
          explanation:
              'Rule: a noun phrase can add information before the noun '
              '(premodifiers such as "rapid") and after it (a prepositional '
              'phrase such as "in population"). Adjectives come before the noun '
              'they describe, and "growth in" is the usual pattern.',
        ),
        FillBlankExercise(
          id: 'u2-l5-e2',
          sentence:
              'There has been a steady increase ____ the number of online '
              'courses.',
          options: ['of', 'on', 'in', 'at'],
          correctIndex: 2,
          explanation:
              'We say "an increase in" something. "Of" is the tempting choice '
              'because "an increase of 10%" is correct, but "of" introduces the '
              'size of the change, not what changed.',
        ),
        MultipleChoiceExercise(
          id: 'u2-l5-e3',
          prompt:
              'Which noun phrase expresses "The city\'s population has grown '
              'rapidly"?',
          options: [
            'the rapidly growth of the population city',
            'the rapid growth of the city\'s population',
            'the city\'s population grown rapid',
            'the quick grow of city population',
          ],
          correctIndex: 1,
          explanation:
              'The verb becomes the noun "growth", and the adverb becomes the '
              'adjective "rapid" before it. The other versions keep the wrong '
              'word forms or the wrong word order.',
        ),
        FillBlankExercise(
          id: 'u2-l5-e4',
          sentence:
              'The ____ report highlighted several weaknesses in the system.',
          options: [
            'published recently',
            'recently published',
            'recent publishing',
            'publish recently',
          ],
          correctIndex: 1,
          explanation:
              'An adverb plus a participle can sit before the noun: "recently '
              'published report". "Published recently" is correct only after '
              'the noun ("a report published recently").',
        ),
        MultipleChoiceExercise(
          id: 'u2-l5-e5',
          prompt:
              'Which noun phrase is the easiest for a reader to understand?',
          options: [
            'the government education spending increase decision',
            'the education government spending decision increase',
            'the decision to increase government spending on education',
            'the increase decision of spending government education',
          ],
          correctIndex: 2,
          explanation:
              'Prepositions and "to" show how the ideas connect. A string of '
              'nouns, such as "the government education spending increase '
              'decision", is hard to read even when the words are in a '
              'plausible order.',
        ),
        FillBlankExercise(
          id: 'u2-l5-e6',
          sentence:
              'Many students ____ part-time jobs struggle to find time to study.',
          options: ['of', 'with', 'for', 'by'],
          correctIndex: 1,
          explanation:
              '"With" after a noun adds a characteristic: students with '
              'part-time jobs. "Of" and "for" do not give this meaning here.',
        ),
      ],
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
      exercises: [
        MultipleChoiceExercise(
          id: 'u2-checkpoint-l1-e1',
          prompt: 'Which of these is a sentence fragment?',
          options: [
            'Temperatures rose.',
            'Whenever the temperature rises.',
            'The temperature rose because the sun was strong.',
            'It rains often here.',
          ],
          correctIndex: 1,
          explanation:
              '"Whenever the temperature rises" has a subject and a verb, but '
              'the word "whenever" makes it depend on a main clause, so it '
              'cannot stand alone. The other three are complete sentences.',
        ),
        FillBlankExercise(
          id: 'u2-checkpoint-l1-e2',
          sentence:
              'The sample was small, ____ the results should be treated with '
              'caution.',
          options: ['so', 'despite', 'because of', 'although'],
          correctIndex: 0,
          explanation:
              '"So" joins two independent clauses and shows a result. '
              '"Although" is grammatical here but gives an illogical contrast, '
              'and "despite" and "because of" cannot be followed by a clause.',
        ),
        FillBlankExercise(
          id: 'u2-checkpoint-l2-e1',
          sentence:
              'Dr Patel, ____ research focuses on coastal erosion, will give '
              'the keynote talk.',
          options: ['who', 'which', 'that', 'whose'],
          correctIndex: 3,
          explanation:
              '"Whose" shows that the research belongs to Dr Patel. "Who" is '
              'tempting because Dr Patel is a person, but "who" cannot be '
              'followed by a noun it owns.',
        ),
        MultipleChoiceExercise(
          id: 'u2-checkpoint-l2-e2',
          prompt: 'Which sentence is correct?',
          options: [
            'The book that I read it was long.',
            'The book, that I read, was long.',
            'The book what I read was long.',
            'The book that I read was long.',
          ],
          correctIndex: 3,
          explanation:
              '"That" already stands for the book, so adding "it" repeats the '
              'object. "What" cannot follow a noun, and "that" cannot be used '
              'between commas.',
        ),
        FillBlankExercise(
          id: 'u2-checkpoint-l3-e1',
          sentence:
              'The vaccine ____ in 1955 and has been used worldwide since.',
          options: [
            'was introduced',
            'is introducing',
            'introduced',
            'has introduce',
          ],
          correctIndex: 0,
          explanation:
              'The vaccine received the action, so the passive "was '
              'introduced" is needed. "Introduced" alone would mean the vaccine '
              'introduced something else.',
        ),
        MultipleChoiceExercise(
          id: 'u2-checkpoint-l3-e2',
          prompt:
              'Which sentence is the passive version of "Researchers have '
              'analysed the data"?',
          options: [
            'The data are analysing by researchers.',
            'The data analysed researchers.',
            'The data have been analysed by researchers.',
            'The data was analysing by researchers.',
          ],
          correctIndex: 2,
          explanation:
              'The passive of the present perfect is "have been" plus a past '
              'participle. The other options use the wrong participle or the '
              'wrong word order.',
        ),
        MultipleChoiceExercise(
          id: 'u2-checkpoint-l4-e1',
          prompt: 'Which sentence is correct?',
          options: [
            'If it will rain, the match will be cancelled.',
            'If it rains, the match will be cancelled.',
            'If it would rain, the match will be cancelled.',
            'If it rained, the match will be cancelled.',
          ],
          correctIndex: 1,
          explanation:
              'A real possibility uses the present simple after "if" and "will" '
              'in the main clause. "Will" or "would" directly after "if" is '
              'incorrect, and "rained" does not match "will be cancelled".',
        ),
        FillBlankExercise(
          id: 'u2-checkpoint-l4-e2',
          sentence:
              'The treatment is safe ____ patients follow the dosage '
              'instructions.',
          options: ['even though', 'as long as', 'whereas', 'in case of'],
          correctIndex: 1,
          explanation:
              '"As long as" introduces a condition, like "provided that". '
              '"Even though" and "whereas" show contrast, and "in case of" is '
              'followed by a noun phrase.',
        ),
        MultipleChoiceExercise(
          id: 'u2-checkpoint-l5-e1',
          prompt: 'Which noun phrase is correct?',
          options: [
            'a large number of students',
            'a number large of students',
            'large number of student',
            'a large numbers of students',
          ],
          correctIndex: 0,
          explanation:
              '"A large number of" is followed by a plural noun, and "number" '
              'stays singular after "a large". "A large numbers" mixes singular '
              'and plural forms.',
        ),
        FillBlankExercise(
          id: 'u2-checkpoint-l5-e2',
          sentence:
              'The government\'s response ____ the crisis was criticised.',
          options: ['of', 'to', 'at', 'on'],
          correctIndex: 1,
          explanation:
              'The noun "response" is followed by "to". "Of" is tempting '
              'because many nouns take "of", but "response of the crisis" would '
              'mean the crisis was responding.',
        ),
      ],
    ),
  ],
);
