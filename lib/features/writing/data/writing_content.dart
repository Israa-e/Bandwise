import '../domain/writing.dart';
import '../domain/writing_feedback.dart';

/// Percentage of commuters cycling to work, at five-year points.
const cyclingChart = LineChartData(
  title: 'Percentage of commuters cycling to work in three cities, 2000–2020',
  xLabels: ['2000', '2005', '2010', '2015', '2020'],
  series: [
    ChartSeries('Arden', [4, 6, 9, 14, 18]),
    ChartSeries('Belmont', [12, 11, 10, 8, 7]),
    ChartSeries('Corvale', [3, 4, 4, 5, 9]),
  ],
  yMax: 20,
  yStep: 5,
  unit: '%',
);

const cyclingTask = WritingTask(
  id: 'w1-cycling',
  type: WritingTaskType.task1,
  topic: 'Cycling to work',
  prompt:
      'The line graph below shows the percentage of commuters who cycled to '
      'work in three cities, Arden, Belmont and Corvale, between 2000 and '
      '2020.',
  instructions:
      'Summarise the information by selecting and reporting the main '
      'features, and make comparisons where relevant. Write at least 150 '
      'words.',
  chart: cyclingChart,
  sampleEssay:
      'The line graph shows the percentage of commuters who cycling to work '
      'in three cities, Arden, Belmont and Corvale, from 2000 to 2020.\n'
      '\n'
      'Overall, cycling become more popular in Arden and Corvale, while it '
      'was decreased in Belmont over the twenty years. By the end of the '
      'period, Arden had the highest figure of the three cities.\n'
      '\n'
      'In 2000, Belmont had the biggest proportion of cyclists, at 12%, '
      'compared with only 4% in Arden and 3% in Corvale. After that, the '
      'figure for Belmont fell steadily, dropping to 10% in 2010, and it '
      'reached 7% in 2020. In contrast, Arden saw a dramatic increase. Its '
      'percentage rose to 9% in 2010 and overtook Belmont before 2015, '
      'finally reaching 18% in 2020.\n'
      '\n'
      'Corvale was quite stable for the first fifteen years, staying between '
      '3% and 5%. However, it jumped to 9% in the last five years, so it was '
      'higher than Belmont in 2020 for the first time. Also, the number of '
      'commuters in Corvale was always lower than Arden.',
);

const universitiesTask = WritingTask(
  id: 'w2-universities',
  type: WritingTaskType.task2,
  topic: 'Universities: jobs or knowledge?',
  prompt:
      'Some people believe that universities should focus on preparing '
      'students for jobs, while others think their main purpose is to '
      'develop knowledge for its own sake. Discuss both views and give your '
      'own opinion.',
  instructions:
      'Give reasons for your answer and include any relevant examples from '
      'your own knowledge or experience. Write at least 250 words.',
  sampleEssay:
      'Nowadays, the role of universities is a topic of debate. Some people '
      'think universities should mainly prepare students for jobs, while '
      'others believe their main purpose is to develop knowledge for it\'s '
      'own sake. In my opinion, universities should do both, but job '
      'preparation are more important for most students.\n'
      '\n'
      'On the one hand, there are good reasons to focus on employment. Most '
      'students go to university because they want a better job in the '
      'future, and the tuition fees are very expensive. If graduates can not '
      'find work, they may feel that their degree was waste of time and '
      'money. For example, courses that include internships help students to '
      'gain practical experience and make them more attractive to employers. '
      'Moreover, the economy needs skilled workers such as engineers and '
      'nurses, and universities are the main place where they are trained.\n'
      '\n'
      'On the other hand, some people argue that knowledge is valuable even '
      'if it has no direct use. Many important discoveries, like X-rays, was '
      'made by researchers who were simply curious about the world, not '
      'trying to make a product. In addition, subjects such as history and '
      'philosophy teach students to think critically, which is useful in '
      'every part of life. If universities only teach job skills, society '
      'will lose this kind of thinking and fewer new ideas will appear.\n'
      '\n'
      'In conclusion, both views has merit. I believe that universities '
      'should mainly prepare students for careers, because this is what most '
      'students and their families expect when they pay for a degree. '
      'However, they should also keep space for pure research and for '
      'subjects that develop the mind, so that knowledge continue to grow '
      'for future generations.',
);

const writingTasks = [cyclingTask, universitiesTask];

/// An annotation before its offsets are worked out from the essay.
typedef SampleNote = ({
  String id,
  AnnotationType type,
  WritingCriterion criterion,
  String original,
  String suggestion,
  String why,
});

/// Prepared feedback on a task's sample essay. Quotes from the essay are in
/// ‘curly quotes’ and must match it exactly.
typedef SampleFeedback = ({
  EstimateRange overall,
  List<CriterionFeedback> criteria,
  List<TopImprovement> topImprovements,
  List<SampleNote> notes,
  List<ParagraphNote> paragraphNotes,
});

const _ta = WritingCriterion.taskAchievement;
const _tr = WritingCriterion.taskResponse;
const _cc = WritingCriterion.coherenceCohesion;
const _lr = WritingCriterion.lexicalResource;
const _gr = WritingCriterion.grammaticalRange;

final sampleFeedback = <String, SampleFeedback>{
  cyclingTask.id: (
    overall: const EstimateRange(6.0, 6.5),
    criteria: [
      CriterionFeedback(
        id: _ta.id,
        range: const EstimateRange(6.0, 6.5),
        strength:
            'Your overview picks out the main trends, and you note that '
            '‘Arden had the highest figure of the three cities’ by the end. '
            'All the figures you give match the graph.',
        improvement:
            'Describe what the graph measures. It shows percentages, so '
            '‘the number of commuters’ should refer to the proportion of '
            'commuters.',
        explanation:
            'Task Achievement looks at how well you summarise the main '
            'features, report the data accurately and compare the key '
            'figures.',
      ),
      CriterionFeedback(
        id: _cc.id,
        range: const EstimateRange(6.0, 6.5),
        strength:
            'Each body paragraph has a clear focus: Belmont and Arden in the '
            'third paragraph, Corvale in the fourth. ‘In contrast’ marks the '
            'change of city well.',
        improvement:
            'Some links are loose. ‘Also,’ adds a final point that really '
            'sums up the whole period, and ‘and it reached 7% in 2020’ '
            'repeats the subject instead of continuing the sentence.',
        explanation:
            'Coherence and Cohesion looks at how logically the information '
            'is organised and how clearly sentences and paragraphs are '
            'linked.',
      ),
      CriterionFeedback(
        id: _lr.id,
        range: const EstimateRange(6.0, 6.5),
        strength:
            'You use accurate trend language such as ‘fell steadily’, '
            '‘overtook Belmont’ and ‘jumped to 9%’.',
        improvement:
            'Check collocations and the strength of words: ‘the biggest '
            'proportion’ is usually the largest proportion, and ‘a dramatic '
            'increase’ overstates a gradual rise.',
        explanation:
            'Lexical Resource looks at the range and accuracy of your '
            'vocabulary, including collocations and word choice.',
      ),
      CriterionFeedback(
        id: _gr.id,
        range: const EstimateRange(5.5, 6.0),
        strength:
            'You use participle clauses well, as in ‘finally reaching 18% in '
            '2020’ and ‘staying between 3% and 5%’.',
        improvement:
            'Several verb forms are wrong: ‘who cycling’, ‘cycling become’ '
            'and ‘it was decreased’. Comparisons also need to compare like '
            'with like.',
        explanation:
            'Grammatical Range and Accuracy looks at the variety of your '
            'sentence structures and how accurately you use them.',
      ),
    ],
    topImprovements: const [
      TopImprovement(
        title: 'Fix verb forms',
        detail:
            'Three sentences have a wrong verb form. Find the main verb of '
            'each sentence and check its tense and form.',
      ),
      TopImprovement(
        title: 'Name what the graph measures',
        detail:
            'The data is in percentages, so write about the proportion or '
            'percentage of commuters, not their number.',
      ),
      TopImprovement(
        title: 'Match words to the size of a change',
        detail:
            'Arden rose by a few points every five years. Choose a word that '
            'describes a steady rise.',
      ),
    ],
    notes: const [
      (
        id: 't1-g1',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'who cycling',
        suggestion: 'who cycled',
        why:
            'A relative clause needs a full verb. The graph is about the '
            'past, so use the past simple.',
      ),
      (
        id: 't1-g2',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'cycling become',
        suggestion: 'cycling became',
        why: 'The period is finished, so the overview needs the past simple.',
      ),
      (
        id: 't1-g3',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'it was decreased',
        suggestion: 'it decreased',
        why:
            'Here "decrease" has no object, so it can\'t be passive. Use the '
            'active form.',
      ),
      (
        id: 't1-v1',
        type: AnnotationType.vocabulary,
        criterion: _lr,
        original: 'the biggest proportion',
        suggestion: 'the largest proportion',
        why: '"Proportion" usually goes with "large" and "small".',
      ),
      (
        id: 't1-c1',
        type: AnnotationType.cohesion,
        criterion: _cc,
        original: 'and it reached 7% in 2020',
        suggestion: 'before reaching 7% in 2020',
        why:
            'Continuing the sentence avoids repeating "it" and shows the '
            'order of events.',
      ),
      (
        id: 't1-v2',
        type: AnnotationType.vocabulary,
        criterion: _lr,
        original: 'a dramatic increase',
        suggestion: 'a steady increase',
        why:
            'Arden rose by a few points in every five-year period. '
            '"Dramatic" suggests a sudden change.',
      ),
      (
        id: 't1-c2',
        type: AnnotationType.cohesion,
        criterion: _cc,
        original: 'Also,',
        suggestion: 'Throughout the period,',
        why:
            '"Also" just adds a point. This sentence compares the cities '
            'over all twenty years, so say that.',
      ),
      (
        id: 't1-t1',
        type: AnnotationType.task,
        criterion: _ta,
        original: 'the number of commuters',
        suggestion: 'the proportion of commuters',
        why:
            'The graph gives percentages, not numbers of people. Reporting '
            'what the data measures is part of describing it accurately.',
      ),
      (
        id: 't1-g4',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'lower than Arden',
        suggestion: 'lower than that of Arden',
        why:
            'Compare like with like: the proportion in Corvale with the '
            'proportion in Arden, not with the city itself.',
      ),
    ],
    paragraphNotes: const [
      ParagraphNote(
        paragraph: 0,
        note:
            'A clear paraphrase of the task. Fix the verb form in the '
            'relative clause.',
      ),
      ParagraphNote(
        paragraph: 1,
        note: 'A good overview: it gives the main trends without figures.',
      ),
      ParagraphNote(
        paragraph: 2,
        note:
            'Accurate figures, and a useful comparison of Arden and Belmont '
            'over time.',
      ),
      ParagraphNote(
        paragraph: 3,
        note:
            'An accurate description of Corvale. Finish with a clear '
            'comparison rather than an extra point.',
      ),
    ],
  ),
  universitiesTask.id: (
    overall: const EstimateRange(6.0, 6.5),
    criteria: [
      CriterionFeedback(
        id: _tr.id,
        range: const EstimateRange(6.5, 7.0),
        strength:
            'You discuss both views in separate paragraphs and give a clear '
            'position: ‘universities should do both’, with more weight on '
            'jobs.',
        improvement:
            'Develop your examples. ‘like X-rays’ names a discovery but '
            'doesn\'t explain how curiosity-driven research led to it or '
            'why that matters.',
        explanation:
            'Task Response looks at how fully you answer every part of the '
            'question, how clear your position is, and how well you support '
            'your ideas.',
      ),
      CriterionFeedback(
        id: _cc.id,
        range: const EstimateRange(6.5, 7.0),
        strength:
            'Clear paragraphing, with ‘On the one hand’ and ‘On the other '
            'hand’ guiding the reader through the two views.',
        improvement:
            '‘Moreover, the economy needs’ moves from students to the whole '
            'economy. Signal that change of view instead of simply adding a '
            'point.',
        explanation:
            'Coherence and Cohesion looks at how logically your ideas are '
            'organised and how clearly sentences and paragraphs are linked.',
      ),
      CriterionFeedback(
        id: _lr.id,
        range: const EstimateRange(6.0, 6.5),
        strength:
            'Good topic vocabulary: ‘tuition fees’, ‘internships’, '
            '‘practical experience’ and ‘think critically’.',
        improvement:
            'Watch collocations and overstatement: fees are high rather than '
            'expensive, and ‘in every part of life’ claims more than you '
            'need.',
        explanation:
            'Lexical Resource looks at the range and accuracy of your '
            'vocabulary, including collocations and word choice.',
      ),
      CriterionFeedback(
        id: _gr.id,
        range: const EstimateRange(5.5, 6.0),
        strength:
            'You use a range of structures, including conditionals such as '
            '‘If universities only teach job skills, society will lose this '
            'kind of thinking’.',
        improvement:
            'Several verbs don\'t agree with their subjects, for example '
            '‘job preparation are’ and ‘both views has merit’.',
        explanation:
            'Grammatical Range and Accuracy looks at the variety of your '
            'sentence structures and how accurately you use them.',
      ),
    ],
    topImprovements: const [
      TopImprovement(
        title: 'Check subject–verb agreement',
        detail:
            'Find the subject of each verb, especially after a long phrase '
            'between the subject and the verb.',
      ),
      TopImprovement(
        title: 'Develop your examples',
        detail:
            'Add a sentence after each example that explains how it supports '
            'your point.',
      ),
      TopImprovement(
        title: 'Open with the question, not a general statement',
        detail:
            'Start the introduction by putting the two views in your own '
            'words, then give your position.',
      ),
    ],
    notes: const [
      (
        id: 't2-t1',
        type: AnnotationType.task,
        criterion: _tr,
        original: 'Nowadays, the role of universities is a topic of debate.',
        suggestion:
            'Begin with the two views in your own words, then your position.',
        why:
            'A general opening adds little. The introduction is stronger '
            'when every sentence answers the question.',
      ),
      (
        id: 't2-g1',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'for it\'s own sake',
        suggestion: 'for its own sake',
        why: '"Its" is possessive. "It\'s" means "it is".',
      ),
      (
        id: 't2-g2',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'job preparation are',
        suggestion: 'job preparation is',
        why: '"Preparation" is uncountable here, so it takes a singular verb.',
      ),
      (
        id: 't2-v1',
        type: AnnotationType.vocabulary,
        criterion: _lr,
        original: 'the tuition fees are very expensive',
        suggestion: 'tuition fees are high',
        why:
            'Fees and prices are "high"; the things you buy are '
            '"expensive".',
      ),
      (
        id: 't2-g3',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'can not',
        suggestion: 'cannot',
        why: '"Cannot" is normally written as one word.',
      ),
      (
        id: 't2-g4',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'was waste of time',
        suggestion: 'was a waste of time',
        why: '"A waste of time" is a fixed phrase and needs the article.',
      ),
      (
        id: 't2-c1',
        type: AnnotationType.cohesion,
        criterion: _cc,
        original: 'Moreover, the economy needs',
        suggestion: 'From a wider point of view, the economy needs',
        why:
            'The paragraph moves from students to society. Show the change '
            'of view rather than just adding a point.',
      ),
      (
        id: 't2-g5',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'like X-rays, was made',
        suggestion: 'like X-rays, were made',
        why:
            'The subject is "discoveries" (plural). The phrase between the '
            'commas doesn\'t change that.',
      ),
      (
        id: 't2-v2',
        type: AnnotationType.vocabulary,
        criterion: _lr,
        original: 'in every part of life',
        suggestion: 'in many areas of life',
        why:
            '"Areas of life" is the usual phrase, and "many" avoids claiming '
            'more than you can support.',
      ),
      (
        id: 't2-g6',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'both views has merit',
        suggestion: 'both views have merit',
        why: '"Both views" is plural, so use "have".',
      ),
      (
        id: 't2-g7',
        type: AnnotationType.grammar,
        criterion: _gr,
        original: 'knowledge continue to grow',
        suggestion: 'knowledge continues to grow',
        why: '"Knowledge" is singular, so the verb needs -s.',
      ),
    ],
    paragraphNotes: const [
      ParagraphNote(
        paragraph: 0,
        note:
            'Your position is clear. The first sentence is general; start '
            'with the two views.',
      ),
      ParagraphNote(
        paragraph: 1,
        note:
            'Relevant reasons with an example. The point about the economy '
            'needs a clearer link.',
      ),
      ParagraphNote(
        paragraph: 2,
        note:
            'A good balance with the first body paragraph. Develop the '
            'X-rays example.',
      ),
      ParagraphNote(
        paragraph: 3,
        note: 'The conclusion restates your opinion and adds a reason.',
      ),
    ],
  ),
};

/// Learning mode's structure hints. Structure only: no model sentences.
const structureTips = {
  WritingTaskType.task1: [
    'Introduction: say what the graph shows, in your own words.',
    'Overview: the two or three main trends, without figures.',
    'Body paragraphs: group the data logically and compare key figures.',
    'No conclusion or opinion is needed.',
  ],
  WritingTaskType.task2: [
    'Introduction: put the question in your own words and give your '
        'opinion.',
    'Body paragraph 1: the first view, with a reason and an example.',
    'Body paragraph 2: the second view, with a reason and an example.',
    'Conclusion: sum up both views and restate your opinion.',
  ],
};
