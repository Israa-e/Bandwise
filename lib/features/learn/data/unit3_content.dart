import '../domain/course.dart';

/// Unit 3: Paraphrasing and argument structure.
const unit3 = Unit(
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
      exercises: [
        MultipleChoiceExercise(
          id: 'u3-l2-e1',
          prompt:
              'Which sentence paraphrases this one by changing the verb into a noun?',
          passage: 'The economy grew rapidly last year.',
          options: [
            'The economy was grown rapid last year.',
            'There was rapid growth in the economy last year.',
            'There was rapidly growth in the economy last year.',
            'The growth rapidly economy was last year.',
          ],
          correctIndex: 1,
          explanation:
              'Rule: changing a word form usually forces other changes. The '
              'verb "grew" becomes the noun "growth", the adverb "rapidly" '
              'becomes the adjective "rapid" before it, and a new verb ("there '
              'was") is needed. "Rapidly growth" keeps the adverb, which cannot '
              'describe a noun.',
        ),
        FillBlankExercise(
          id: 'u3-l2-e2',
          sentence:
              'The ____ of wildlife habitats is a priority for the charity.',
          options: ['protection', 'protectively', 'protect', 'protective'],
          correctIndex: 0,
          explanation:
              'After "The" and before "of" the sentence needs a noun, so '
              '"protection" is correct. "Protect" is the verb, "protective" is '
              'an adjective, and "protectively" is an adverb.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l2-e3',
          prompt: 'Which sentence is a correct paraphrase?',
          passage:
              'Teachers are increasingly concerned about the use of smartphones.',
          options: [
            'There is increasing concern among teachers about smartphone use.',
            'Teachers have increased smartphone use.',
            'Teachers are increasingly concerning about smartphone use.',
            'Smartphone use is concerned by teachers more and more.',
          ],
          correctIndex: 0,
          explanation:
              'The adjective "concerned" becomes the noun "concern", and the '
              'adverb "increasingly" becomes the adjective "increasing". '
              '"Concerning" and "concerned by" use the wrong forms, and saying '
              'that teachers have increased smartphone use changes the '
              'meaning completely.',
        ),
        FillBlankExercise(
          id: 'u3-l2-e4',
          sentence:
              'The committee considered the proposal ____ before reaching a '
              'decision.',
          options: ['careful', 'care', 'carefulness', 'carefully'],
          correctIndex: 3,
          explanation:
              'An adverb is needed to describe the verb "considered", so '
              '"carefully" is correct. "Careful" is an adjective and is the '
              'tempting choice, but adjectives describe nouns.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l2-e5',
          prompt: 'Which sentence uses the correct word form?',
          options: [
            'The economic of the region is growing.',
            'The region has an economical growth.',
            'The region has strong economic growth.',
            'The region is growing economy.',
          ],
          correctIndex: 2,
          explanation:
              '"Economic" is the adjective that relates to the economy. '
              '"Economical" is the tempting alternative, but it means "not '
              'wasting money". "Economic" is not a noun, so it cannot follow '
              '"The".',
        ),
        FillBlankExercise(
          id: 'u3-l2-e6',
          sentence:
              'There has been a significant ____ in the number of road accidents.',
          options: ['reduction', 'reducing', 'reduced', 'reduce'],
          correctIndex: 0,
          explanation:
              'After "a significant" a noun is needed, and "reduction in" is '
              'the usual pattern. "Reduce" is a verb, "reduced" is a participle '
              'and "reducing" cannot follow "a significant".',
        ),
      ],
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
      exercises: [
        MultipleChoiceExercise(
          id: 'u3-l3-e1',
          prompt:
              'Which sentence is the passive version of "Local councils fund '
              'most community libraries"?',
          options: [
            'Most community libraries are funded by local councils.',
            'Local councils are funded by most community libraries.',
            'Most community libraries funded local councils.',
            'Most community libraries are funding by local councils.',
          ],
          correctIndex: 0,
          explanation:
              'Rule: to change active to passive, move the object to the front, '
              'use "be" plus a past participle, and put the old subject after '
              '"by" (or leave it out). The meaning must stay the same. The '
              'version beginning "Local councils are funded" reverses who '
              'funds whom.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l3-e2',
          prompt:
              'Which sentence keeps the meaning of "Although the course was '
              'expensive, it was popular"?',
          options: [
            'The course was expensive because it was popular.',
            'The course was popular, so it was cheap.',
            'The course was popular because it was expensive.',
            'The course was popular despite being expensive.',
          ],
          correctIndex: 3,
          explanation:
              '"Despite being" keeps the contrast between price and '
              'popularity. The versions with "because" and "so" turn the '
              'contrast into a cause or result, which changes the meaning.',
        ),
        FillBlankExercise(
          id: 'u3-l3-e3',
          sentence:
              'Urban populations are growing, ____ puts pressure on housing.',
          options: ['which', 'what', 'whose', 'who'],
          correctIndex: 0,
          explanation:
              '"Which" can refer to a whole idea (the growth of the '
              'population) and joins two short sentences into one. "What" '
              'cannot introduce a clause after a comma, and "who" and "whose" '
              'are for people.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l3-e4',
          prompt:
              'Which sentence starts with the result instead of the cause and '
              'keeps the meaning of "Poor air quality causes many respiratory '
              'illnesses"?',
          options: [
            'Many respiratory illnesses cause poor air quality.',
            'Many respiratory illnesses are poor air quality.',
            'Poor air quality is caused by many respiratory illnesses.',
            'Many respiratory illnesses are caused by poor air quality.',
          ],
          correctIndex: 3,
          explanation:
              'The passive moves "many respiratory illnesses" to the front and '
              'keeps poor air quality as the cause. The sentences that make '
              'illnesses the cause of poor air quality, or equate the two, '
              'reverse or blur cause and effect.',
        ),
        FillBlankExercise(
          id: 'u3-l3-e5',
          sentence: '____ the ageing population, healthcare costs are rising.',
          options: ['Because', 'Because of', 'Despite', 'Although'],
          correctIndex: 1,
          explanation:
              '"Because of" is followed by a noun phrase ("the ageing '
              'population"). "Because" is the tempting choice, but it needs a '
              'subject and verb. "Despite" and "although" show contrast, which '
              'does not fit the meaning.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l3-e6',
          prompt:
              'Which sentence combines "Cycling is cheap" and "Cycling is '
              'healthy" without changing the meaning?',
          options: [
            'Cycling is both cheap and healthy.',
            'Cycling is cheap although healthy.',
            'Cycling is cheap, however healthy.',
            'Cycling is cheap because healthy.',
          ],
          correctIndex: 0,
          explanation:
              '"Both ... and" joins the two qualities neatly. "Although" and '
              '"however" add a contrast that is not in the original, and '
              '"because" adds a cause.',
        ),
      ],
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
      exercises: [
        MultipleChoiceExercise(
          id: 'u3-l4-e1',
          prompt:
              'Which sentence is the clearest thesis statement for an essay on '
              'whether cities should ban cars from their centres?',
          options: [
            'City centres should be closed to private cars because this would '
                'reduce pollution and make streets safer.',
            'Cars are everywhere in cities.',
            'This essay will talk about cars in city centres.',
            'Some people like cars and some people do not.',
          ],
          correctIndex: 0,
          explanation:
              'Rule: a thesis statement gives your position and your main '
              'reasons. An announcement of the topic is the tempting choice, '
              'but it takes no side. A simple fact and a list of opposing '
              'opinions do not state a position either.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l4-e2',
          prompt:
              'Which topic sentence supports the thesis "Universities should '
              'make lecture attendance optional"?',
          options: [
            'Attendance is recorded at the start of each lecture.',
            'Many universities are in large cities.',
            'Optional attendance gives students more responsibility for their '
                'own learning.',
            'Students who miss lectures sometimes fail their exams.',
          ],
          correctIndex: 2,
          explanation:
              'A topic sentence introduces a reason for the thesis. The '
              'sentence about missing lectures and failing is tempting '
              'because it is related, but it supports the opposite position. '
              'The other two are facts that give no reason.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l4-e3',
          prompt:
              'A writer argues that schools should reduce homework. Which '
              'sentence contradicts that position?',
          options: [
            'Excessive homework leaves children little time for sleep.',
            'Therefore, homework should be increased in secondary schools.',
            'Studies link heavy workloads with stress.',
            'Reducing homework would give families more time together.',
          ],
          correctIndex: 1,
          explanation:
              'Calling for more homework contradicts the thesis, so it breaks '
              'the consistency of the essay. The other sentences give reasons '
              'for reducing homework.',
        ),
        FillBlankExercise(
          id: 'u3-l4-e4',
          sentence:
              'Because the evidence shows clear benefits, I ____ that cycling '
              'lanes should be expanded.',
          options: ['argue', 'regret', 'doubt', 'deny'],
          correctIndex: 0,
          explanation:
              '"Argue" restates the writer\'s position, which follows from the '
              'evidence. "Doubt" and "deny" would contradict the reason given, '
              'and "regret" suggests the writer is unhappy about expanding the '
              'lanes.',
          prompt: 'Choose the word that keeps the argument consistent.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l4-e5',
          prompt:
              'Where should the thesis statement appear in a short exam '
              'essay?',
          options: [
            'In the middle of the second body paragraph',
            'Nowhere: the reader should work it out',
            'Only in the conclusion',
            'At the end of the introduction',
          ],
          correctIndex: 3,
          explanation:
              'Stating your position in the introduction lets every paragraph '
              'that follows support it. Keeping it for the conclusion is '
              'tempting, but the reader then cannot tell what the paragraphs '
              'are proving.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l4-e6',
          prompt:
              'Which body-paragraph plan supports the thesis "Governments '
              'should invest more in public transport"?',
          options: [
            'Cars are fast; people enjoy driving.',
            'Roads are better value than trains; public transport reduces '
                'congestion.',
            'Public transport reduces congestion; it is cheaper for families.',
            'Public transport exists in many cities; some people use buses.',
          ],
          correctIndex: 2,
          explanation:
              'Both reasons argue for the thesis. The plan that says roads are '
              'better value than trains contradicts it, the plan about '
              'driving argues for cars, and the plan that only says public '
              'transport exists gives no reason to invest.',
        ),
      ],
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
      exercises: [
        MultipleChoiceExercise(
          id: 'u3-l5-e1',
          prompt:
              'The paragraph follows the pattern point, explanation, example. '
              'Which sentence should come next?',
          passage: 'Online lessons make education more accessible.',
          options: [
            'For example, a farmer in a remote village studied engineering '
                'online.',
            'In conclusion, online lessons are popular.',
            'This is because students can learn from home without paying for '
                'travel or accommodation.',
            'Many people have computers.',
          ],
          correctIndex: 2,
          explanation:
              'Rule: a strong paragraph moves from point to explanation to '
              'example, then links back to the point. The explanation says why '
              'the point is true. The example is the tempting choice, but it '
              'works better after the explanation.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l5-e2',
          prompt:
              'Which example best supports the point "Public libraries support '
              'lifelong learning"?',
          options: [
            'Many libraries have tall windows.',
            'A local café sells good coffee.',
            'Books were once copied by hand.',
            'A retired teacher uses her local library\'s free courses to learn '
                'Spanish.',
          ],
          correctIndex: 3,
          explanation:
              'The example shows an adult learning something new through the '
              'library, which is exactly the point. The other sentences are '
              'true or interesting but not relevant to learning.',
        ),
        FillBlankExercise(
          id: 'u3-l5-e3',
          sentence:
              'Many cities have introduced congestion charges. ____, London '
              'reduced traffic in its centre soon after charges began.',
          options: ['For instance', 'However', 'Therefore', 'In contrast'],
          correctIndex: 0,
          explanation:
              '"For instance" introduces a specific example of the general '
              'statement. "Therefore" is tempting because charges and less '
              'traffic seem connected, but London is one case, not a result of '
              'other cities introducing charges.',
          prompt: 'Choose the phrase that introduces an example.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l5-e4',
          prompt: 'Which sentence links the example back to the point?',
          passage:
              'Point: Regular exercise improves mental health. Example: '
              'Employees who join a lunchtime walking group often report '
              'feeling less stressed.',
          options: [
            'Another point is that sleep matters.',
            'Office workers are busy people.',
            'Walking is a popular activity in many countries.',
            'This shows that even moderate activity can ease stress.',
          ],
          correctIndex: 3,
          explanation:
              '"This shows that..." connects the example to the point about '
              'mental health. "Another point is..." is tempting because it '
              'sounds like a link, but it starts a new point instead.',
        ),
        MultipleChoiceExercise(
          id: 'u3-l5-e5',
          prompt:
              'Which example best supports the point "Tourism can damage '
              'fragile environments"?',
          options: [
            'Many tourists enjoy taking photographs.',
            'Hotels employ local people.',
            'Thousands of visitors walk the same path each year, wearing away '
                'the plants around an ancient site.',
            'Flights have become cheaper.',
          ],
          correctIndex: 2,
          explanation:
              'It shows a specific way in which visitors cause damage. The '
              'other statements are about tourism, but none of them shows '
              'harm to the environment.',
        ),
        FillBlankExercise(
          id: 'u3-l5-e6',
          sentence:
              'Cities can encourage walking by improving facilities, ____ wider '
              'pavements and safer crossings.',
          options: ['such as', 'for', 'such', 'as for'],
          correctIndex: 0,
          explanation:
              '"Such as" introduces examples inside a sentence. "Such" needs a '
              'noun after it, and "for" and "as for" do not introduce a list '
              'of examples.',
          prompt: 'Choose the words that complete the sentence.',
        ),
      ],
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
      exercises: [
        MultipleChoiceExercise(
          id: 'u3-checkpoint-l1-e1',
          prompt: 'Which word is closest in meaning to "significant" here?',
          passage:
              'The study found a significant difference between the groups.',
          options: ['notable', 'accidental', 'tiny', 'imaginary'],
          correctIndex: 0,
          explanation:
              '"Notable" means worth noticing, which matches "significant". '
              '"Tiny" is the opposite, and "accidental" and "imaginary" add '
              'ideas that are not in the sentence.',
        ),
        MultipleChoiceExercise(
          id: 'u3-checkpoint-l1-e2',
          prompt: 'Which sentence is the best paraphrase?',
          passage: 'Most students prefer studying in the evening.',
          options: [
            'All students study in the evening.',
            'A few students favour evening study.',
            'The majority of students favour evening study.',
            'Students must study in the evening.',
          ],
          correctIndex: 2,
          explanation:
              '"The majority" matches "most", and "favour" matches "prefer". '
              '"All" and "a few" change the amount, and "must" changes a '
              'preference into a rule.',
        ),
        FillBlankExercise(
          id: 'u3-checkpoint-l2-e1',
          sentence: 'The ____ of renewable energy has risen sharply.',
          options: ['usable', 'used', 'user', 'use'],
          correctIndex: 3,
          explanation:
              'A noun is needed after "The", and "use" names the activity. '
              '"User" is also a noun, but it names a person, so the sentence '
              'would say that a person has risen.',
        ),
        MultipleChoiceExercise(
          id: 'u3-checkpoint-l2-e2',
          prompt:
              'Which sentence uses a different word form to paraphrase this?',
          passage: 'The two groups differ greatly.',
          options: [
            'There is a great difference between the two groups.',
            'The two groups are greatly difference.',
            'The two groups have a different greatly.',
            'There is a greatly differ between the two groups.',
          ],
          correctIndex: 0,
          explanation:
              'The verb "differ" becomes the noun "difference", and the adverb '
              '"greatly" becomes the adjective "great". The other versions keep '
              'the wrong forms.',
        ),
        MultipleChoiceExercise(
          id: 'u3-checkpoint-l3-e1',
          prompt:
              'Which sentence is the passive version of "The council banned '
              'cars from the square"?',
          options: [
            'Cars banned the council from the square.',
            'The square was banned from cars by the council.',
            'The council was banned from the square by cars.',
            'Cars were banned from the square by the council.',
          ],
          correctIndex: 3,
          explanation:
              'The cars were the thing banned, so they become the subject. '
              '"The square was banned" is tempting but changes who or what was '
              'banned.',
        ),
        FillBlankExercise(
          id: 'u3-checkpoint-l3-e2',
          sentence: 'The rise in unemployment ____ many families to move.',
          options: ['resulted', 'caused', 'was caused', 'made to'],
          correctIndex: 1,
          explanation:
              'This turns "Because unemployment rose, many families moved" '
              'into a noun phrase plus "caused ... to move". "Resulted" needs '
              '"in", and "was caused" would make the families the cause.',
        ),
        MultipleChoiceExercise(
          id: 'u3-checkpoint-l4-e1',
          prompt:
              'Which statement is a clear position on the question "Should '
              'students wear school uniforms?"',
          options: [
            'Uniforms are a topic that people discuss.',
            'There are many kinds of uniforms.',
            'Students should wear uniforms because they reduce pressure to '
                'follow fashion.',
            'This essay will look at uniforms.',
          ],
          correctIndex: 2,
          explanation:
              'It takes a side and gives a reason. The other statements only '
              'announce or describe the topic.',
        ),
        MultipleChoiceExercise(
          id: 'u3-checkpoint-l4-e2',
          prompt:
              'A writer argues that cities need more parks. Which sentence '
              'belongs in the conclusion?',
          options: [
            'Parks should be removed to build offices.',
            'Cities need fewer trees.',
            'It is unclear whether parks matter.',
            'Therefore, more green space should be created.',
          ],
          correctIndex: 3,
          explanation:
              'A conclusion restates the position, so it must agree with the '
              'thesis. The other sentences contradict it or avoid taking a '
              'side.',
        ),
        FillBlankExercise(
          id: 'u3-checkpoint-l5-e1',
          sentence:
              'Public parks improve community life. ____, neighbours who meet '
              'at a weekend market often start to help one another.',
          options: ['Because', 'Despite', 'Whereas', 'For example'],
          correctIndex: 3,
          explanation:
              '"For example" introduces a specific illustration of the point. '
              'The other options cannot start a sentence in this way and give '
              'the wrong relationship.',
          prompt: 'Choose the words that complete the sentence.',
        ),
        MultipleChoiceExercise(
          id: 'u3-checkpoint-l5-e2',
          prompt: 'Which order is the most effective for a body paragraph?',
          options: [
            'Example, link back, point, explanation',
            'Point, explanation, example, link back',
            'Link back, point, example, explanation',
            'Explanation, conclusion, example, point',
          ],
          correctIndex: 1,
          explanation:
              'A paragraph works best when it states the point, explains it, '
              'gives an example and then links the example back to the point. '
              'Starting with the example leaves the reader without a purpose.',
        ),
      ],
    ),
  ],
);
