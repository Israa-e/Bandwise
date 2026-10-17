import '../domain/reading.dart';

/// Original practice passages. Written for Bandwise; not taken from any
/// exam paper.
const readingPassages = [_heatIslands, _timekeeping];

// ---------------------------------------------------------------------------
// Passage 1: urban heat islands
// ---------------------------------------------------------------------------

const _heatHeadings = [
  'An old observation with growing importance',
  "How building materials store the sun's energy",
  "Losing nature's air conditioning",
  'Street layout and machines add to the problem',
  'Who pays the price of a hotter city',
  'Practical ways to cool urban areas',
  'Why rural areas are becoming warmer',
  'The cost of building new power stations',
];

const _heatIslands = ReadingPassage(
  id: 'uhi',
  title: 'Why cities run hot',
  topic: 'Urban heat islands: causes, effects and solutions',
  paragraphs: [
    // A
    ReadingParagraph([
      'On a still summer evening, the centre of a large city can be several '
          'degrees warmer than the farmland only a short drive away.',
      'Climate scientists call this contrast an urban heat island, and it has '
          'been measured in cities on every inhabited continent.',
      'The phenomenon is not new.',
      'In the early nineteenth century, the amateur meteorologist Luke Howard '
          'compared temperature records from central London with readings '
          'taken in the surrounding countryside and concluded that the city '
          'was consistently warmer, especially at night.',
      "What has changed since Howard's time is the scale of urban growth.",
      "More than half of the world's population now lives in towns and "
          'cities, so the way built environments store and release heat '
          'affects the daily lives of billions of people.',
    ]),
    // B
    ReadingParagraph([
      'The main cause of the effect lies in the materials from which cities '
          'are made.',
      'Asphalt, concrete, brick and dark roofing absorb a large share of the '
          'sunlight that falls on them, because they reflect relatively '
          'little of it; in technical terms, they have a low albedo.',
      'These materials also have a high capacity to store heat.',
      'During the day they gradually warm up, and after sunset they slowly '
          'release that stored energy into the air around them.',
      'This is why the difference between urban and rural temperatures is '
          'often greatest several hours after dark rather than in the middle '
          'of the afternoon.',
      'In the countryside, by contrast, soil and plants cool down quickly '
          'once the sun has set.',
    ]),
    // C
    ReadingParagraph([
      'A second cause is the loss of vegetation and open water.',
      'Plants draw water from the soil and release it as vapour through '
          'their leaves, a process known as transpiration, and the '
          'evaporation of this water uses energy that would otherwise heat '
          'the air.',
      'When fields and woodland are replaced by roads, car parks and '
          'buildings, this natural cooling largely disappears.',
      'Rain that falls on hard surfaces is also channelled quickly into '
          'drains, leaving little moisture near the ground to evaporate on '
          'the following day.',
      'As a result, a paved city centre can lose one of the most effective '
          'cooling mechanisms that a rural landscape provides.',
    ]),
    // D
    ReadingParagraph([
      'The shape of a city and the activities within it add further heat.',
      'Tall buildings lining narrow streets form what researchers describe '
          'as urban canyons.',
      'Within these canyons, heat radiated from one wall is partly absorbed '
          'by the wall opposite, so less of it escapes to the open sky at '
          'night.',
      'The same buildings can also block the breezes that might otherwise '
          'carry warm air away.',
      'Meanwhile, vehicles, factories and air-conditioning units release '
          'waste heat directly into the streets.',
      'Air conditioning creates a particularly awkward cycle: the hotter a '
          'city becomes, the more cooling people use, and the more heat the '
          'machines expel outdoors.',
    ]),
    // E
    ReadingParagraph([
      'These extra degrees have real consequences.',
      'During heatwaves, high night-time temperatures prevent the human body '
          'from recovering from the heat of the day, and public health '
          'researchers have linked such conditions to increases in hospital '
          'admissions and deaths, particularly among elderly people and '
          'those with heart or lung conditions.',
      'Warmer cities also consume more electricity for cooling, which can '
          'strain power networks at times of peak demand.',
      'In addition, heat speeds up the chemical reactions that produce '
          'ground-level ozone, a pollutant that irritates the lungs.',
      'The burden is not shared equally: neighbourhoods with few trees and '
          'dense housing are often noticeably hotter than greener, wealthier '
          'districts in the same city.',
    ]),
    // F
    ReadingParagraph([
      'Fortunately, the urban heat island is one of the few climate-related '
          'problems that city governments can tackle directly.',
      'Cool roofs, which are coated with pale, reflective materials, absorb '
          'less sunlight than conventional dark roofs and can lower the '
          'temperature of the building beneath them.',
      'Green roofs, planted with grasses or low shrubs, provide shade and '
          'cooling through transpiration, and they also slow the flow of '
          'rainwater into drains.',
      'At street level, planting trees is among the most widely recommended '
          'measures, since a mature tree both shades the pavement and '
          'releases water vapour.',
      'Some cities are also experimenting with lighter-coloured paving and '
          'with surfaces that allow water to soak through.',
      'None of these measures can remove the effect entirely, but combined '
          'they can make urban summers considerably more bearable.',
    ]),
  ],
  questions: [
    TfngQuestion(
      id: 'uhi-q1',
      statement:
          'Luke Howard found that London was warmer than the countryside '
          'around it.',
      answer: Tfng.trueAnswer,
      explanation:
          'Paragraph A says Howard compared readings from central London and '
          'the surrounding countryside and concluded that the city was '
          'consistently warmer.',
      evidence: EvidenceSpan(0, 3),
    ),
    TfngQuestion(
      id: 'uhi-q2',
      statement:
          'The temperature difference between a city and the countryside is '
          'usually largest in the early afternoon.',
      answer: Tfng.falseAnswer,
      explanation:
          'Paragraph B says the difference is often greatest several hours '
          'after dark, "rather than in the middle of the afternoon". The '
          'statement contradicts this.',
      evidence: EvidenceSpan(1, 4),
    ),
    TfngQuestion(
      id: 'uhi-q3',
      statement: 'Cool roofs are more expensive to install than dark roofs.',
      answer: Tfng.notGiven,
      explanation:
          'Paragraph F explains what cool roofs do, but the passage says '
          'nothing about what any roof costs to install.',
      evidence: EvidenceSpan(5, 1),
    ),
    ReadingMultipleChoiceQuestion(
      id: 'uhi-q4',
      prompt:
          'According to paragraph C, why does a paved city centre lose a '
          'natural way of cooling?',
      options: [
        'Hard surfaces reflect most of the sunlight that reaches them.',
        'Less water is left near the ground to evaporate.',
        'Drains release warm water into the air.',
        'Buildings stop rain from reaching the ground.',
      ],
      correctIndex: 1,
      explanation:
          'Rain on hard surfaces is channelled into drains, "leaving little '
          'moisture near the ground to evaporate". Paragraph B says these '
          'surfaces reflect little sunlight, so the first option is wrong.',
      evidence: EvidenceSpan(2, 3),
    ),
    ReadingMultipleChoiceQuestion(
      id: 'uhi-q5',
      prompt: 'What does the writer say about air conditioning?',
      options: [
        'It is the main cause of urban heat islands.',
        'It is used less in neighbourhoods with many trees.',
        'It adds to the heat that it is used to escape.',
        'It is not allowed in some city centres.',
      ],
      correctIndex: 2,
      explanation:
          'Paragraph D describes "a particularly awkward cycle": the hotter a '
          'city becomes, the more cooling people use, and the more heat the '
          'machines expel outdoors. The main cause is the materials '
          '(paragraph B).',
      evidence: EvidenceSpan(3, 5),
    ),
    HeadingQuestion(
      id: 'uhi-q6',
      paragraph: 1,
      options: _heatHeadings,
      correctIndex: 1,
      explanation:
          'Paragraph B explains how asphalt, concrete and brick absorb '
          'sunlight, store it and release it after dark.',
      evidence: EvidenceSpan(1, 0),
    ),
    HeadingQuestion(
      id: 'uhi-q7',
      paragraph: 2,
      options: _heatHeadings,
      correctIndex: 2,
      explanation:
          'Paragraph C is about the cooling that plants and water provide, '
          'and how it disappears when land is paved.',
      evidence: EvidenceSpan(2, 0),
    ),
    HeadingQuestion(
      id: 'uhi-q8',
      paragraph: 4,
      options: _heatHeadings,
      correctIndex: 4,
      explanation:
          'Paragraph E covers the effects on health, electricity and air '
          'quality, and notes that poorer, less green areas suffer most.',
      evidence: EvidenceSpan(4, 0),
    ),
    CompletionQuestion(
      id: 'uhi-q9',
      sentence:
          'Materials that reflect little of the sunlight reaching them are '
          'described as having a low ____.',
      answer: 'albedo',
      explanation:
          'Paragraph B: dark materials reflect relatively little sunlight; '
          '"in technical terms, they have a low albedo".',
      evidence: EvidenceSpan(1, 1),
    ),
    CompletionQuestion(
      id: 'uhi-q10',
      sentence:
          'Tall buildings along narrow streets create what researchers call '
          '____.',
      answer: 'urban canyons',
      variants: ['canyons'],
      explanation:
          'Paragraph D: tall buildings lining narrow streets "form what '
          'researchers describe as urban canyons".',
      evidence: EvidenceSpan(3, 1),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Passage 2: the history of timekeeping
// ---------------------------------------------------------------------------

const _timeHeadings = [
  'Reading time from the sky',
  'A device that worked by day and by night',
  'Machines in the tower',
  'From the pendulum to the open sea',
  'Agreeing on a common time',
  'Beyond moving parts',
  'The decline of the sundial in modern gardens',
  'Why ships needed faster engines',
];

const _timekeeping = ReadingPassage(
  id: 'time',
  title: 'Measuring the hours',
  topic: 'A short history of timekeeping',
  paragraphs: [
    // A
    ReadingParagraph([
      'For most of human history, people measured time by watching the sky.',
      'The daily movement of the sun, the changing shape of the moon and the '
          'yearly return of particular stars provided natural calendars that '
          'allowed early farming communities to plan when to sow and harvest.',
      'Dividing the day into smaller parts, however, required instruments.',
      'Among the oldest are shadow clocks and sundials, used in ancient Egypt '
          'more than three thousand years ago, which indicated the hour by '
          'the position of a shadow cast by the sun.',
      'Their limitation was obvious: they were useless at night and on '
          'cloudy days, and the length of their hours varied with the '
          'seasons.',
    ]),
    // B
    ReadingParagraph([
      'Water clocks offered a partial solution.',
      'In its simplest form, a water clock was a vessel from which water '
          'dripped through a small hole at a steady rate, so that the falling '
          'level inside marked the passing hours.',
      'Versions of the device were used in Egypt, Babylon, China and Greece, '
          'and it could be consulted at any time of day or night.',
      'In the third century BCE, the Greek inventor Ctesibius of Alexandria '
          'improved its accuracy by keeping the water in the supply tank at a '
          'constant level, which ensured an even flow.',
      'Even so, water clocks were affected by temperature, since water flows '
          'more slowly when it is cold, and they needed regular attention.',
    ]),
    // C
    ReadingParagraph([
      'The decisive step towards modern timekeeping came with mechanical '
          'clocks, which appeared in Europe towards the end of the thirteenth '
          'century.',
      'These were driven by a falling weight, and their key component was '
          'the escapement, a mechanism that released the stored energy in '
          'small, regular steps rather than all at once.',
      'Early mechanical clocks were large iron machines installed in church '
          'towers and town halls, and many of them struck a bell instead of '
          'displaying the time on a dial.',
      'They were impressive public symbols, but by modern standards they '
          'were not precise: an error of a quarter of an hour in a single day '
          'was not unusual.',
    ]),
    // D
    ReadingParagraph([
      'Precision improved dramatically in the seventeenth century.',
      'In 1656, the Dutch scientist Christiaan Huygens built the first '
          'pendulum clock, making use of the fact that a pendulum of a given '
          'length swings with a nearly regular period.',
      'The best pendulum clocks reduced daily errors from minutes to '
          'seconds.',
      'Yet a pendulum is of little use on a rolling ship, and sailors '
          'urgently needed accurate time to calculate their longitude at sea.',
      'The English clockmaker John Harrison spent decades on this problem, '
          'and his compact marine timekeeper, known today as H4, performed '
          'remarkably well on a voyage to Jamaica in 1761 and 1762.',
    ]),
    // E
    ReadingParagraph([
      'As clocks became more reliable, a new problem emerged: different '
          'towns kept different times.',
      'Each community traditionally set its clocks by the local position of '
          'the sun, so noon in one city could fall several minutes earlier or '
          'later than noon in another.',
      'This hardly mattered when travel was slow, but the arrival of the '
          'railways made it a serious source of confusion.',
      'In 1840, the Great Western Railway in Britain began using London time '
          'throughout its timetables, and other companies soon followed.',
      'Later, in 1884, delegates at the International Meridian Conference in '
          'Washington chose the meridian passing through Greenwich as the '
          'starting point for measuring longitude, which helped to establish '
          'the system of time zones used today.',
    ]),
    // F
    ReadingParagraph([
      'In the twentieth century, timekeeping left mechanical parts behind '
          'altogether.',
      'Quartz clocks, first developed in 1927, use the extremely regular '
          'vibrations of a quartz crystal when an electric current is applied '
          'to it, and today they are found in almost every wristwatch and '
          'household appliance.',
      'Atomic clocks went further still.',
      'In 1955, Louis Essen and Jack Parry built a caesium atomic clock at '
          'the National Physical Laboratory in Britain, and in 1967 the second '
          'itself was redefined in terms of the radiation emitted by caesium '
          'atoms.',
      'The most stable atomic clocks would neither gain nor lose a second in '
          'many millions of years, and they underpin technologies such as '
          'satellite navigation, which depends on extremely precise time '
          'signals.',
    ]),
  ],
  questions: [
    TfngQuestion(
      id: 'time-q1',
      statement: 'Sundials could not be used after dark.',
      answer: Tfng.trueAnswer,
      explanation:
          'Paragraph A says shadow clocks and sundials "were useless at '
          'night", which agrees with the statement.',
      evidence: EvidenceSpan(0, 4),
    ),
    TfngQuestion(
      id: 'time-q2',
      statement:
          'Early mechanical clocks were accurate to within a few seconds a '
          'day.',
      answer: Tfng.falseAnswer,
      explanation:
          'Paragraph C says an error of a quarter of an hour in a single day '
          'was not unusual, which contradicts the statement.',
      evidence: EvidenceSpan(2, 3),
    ),
    TfngQuestion(
      id: 'time-q3',
      statement:
          'The Great Western Railway was the largest railway company '
          'in Britain.',
      answer: Tfng.notGiven,
      explanation:
          'Paragraph E says the Great Western Railway adopted London time in '
          '1840, but the passage gives no information about the size of any '
          'railway company.',
      evidence: EvidenceSpan(4, 3),
    ),
    TfngQuestion(
      id: 'time-q4',
      statement:
          'Louis Essen received an award for his work on atomic '
          'clocks.',
      answer: Tfng.notGiven,
      explanation:
          'Paragraph F says Essen and Parry built a caesium clock in 1955, '
          'but there is no information about any award.',
      evidence: EvidenceSpan(5, 3),
    ),
    ReadingMultipleChoiceQuestion(
      id: 'time-q5',
      prompt: 'Why did temperature affect water clocks?',
      options: [
        'Water flows more slowly when it is cold.',
        'Warm water evaporated from the supply tank.',
        'Ice blocked the small hole in the vessel.',
        'Metal vessels expanded in the heat.',
      ],
      correctIndex: 0,
      explanation:
          'Paragraph B: water clocks were affected by temperature "since '
          'water flows more slowly when it is cold". The other options are '
          'not mentioned.',
      evidence: EvidenceSpan(1, 4),
    ),
    ReadingMultipleChoiceQuestion(
      id: 'time-q6',
      prompt: 'According to paragraph E, what problem did the railways cause?',
      options: [
        'Trains could not run safely at night.',
        'Towns keeping their own local time led to confusion.',
        'Station clocks were often broken.',
        'Passengers did not trust printed timetables.',
      ],
      correctIndex: 1,
      explanation:
          'Each town set its clocks by the local sun, and the railways made '
          'these differences "a serious source of confusion".',
      evidence: EvidenceSpan(4, 2),
    ),
    HeadingQuestion(
      id: 'time-q7',
      paragraph: 1,
      options: _timeHeadings,
      correctIndex: 1,
      explanation:
          'Paragraph B describes the water clock, which, unlike the sundial, '
          '"could be consulted at any time of day or night".',
      evidence: EvidenceSpan(1, 2),
    ),
    HeadingQuestion(
      id: 'time-q8',
      paragraph: 4,
      options: _timeHeadings,
      correctIndex: 4,
      explanation:
          'Paragraph E explains how railway time and the 1884 conference led '
          'to shared time instead of local time.',
      evidence: EvidenceSpan(4, 0),
    ),
    CompletionQuestion(
      id: 'time-q9',
      sentence:
          'The part of a mechanical clock that released energy in small, '
          'regular steps was the ____.',
      answer: 'escapement',
      explanation:
          'Paragraph C: "their key component was the escapement, a mechanism '
          'that released the stored energy in small, regular steps".',
      evidence: EvidenceSpan(2, 1),
    ),
    CompletionQuestion(
      id: 'time-q10',
      sentence:
          'In 1840, the Great Western Railway began to use ____ in all of its '
          'timetables.',
      answer: 'London time',
      explanation:
          'Paragraph E: the Great Western Railway "began using London time '
          'throughout its timetables".',
      evidence: EvidenceSpan(4, 3),
    ),
  ],
);
