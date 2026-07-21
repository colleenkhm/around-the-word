import '../models/vocab_category.dart';

const List<Category> vocabCategories = [
  Category(
    name: 'Food',
    subjects: [
      Subject(
        name: 'Cooking',
        phrases: [
          Phrase('recipe'),
          Phrase('ingredient'),
          Phrase('to chop'),
          Phrase('to boil'),
          Phrase('to bake'),
          Phrase('stove'),
          Phrase('oven'),
          Phrase('Can you pass the salt?'),
        ],
      ),
      Subject(
        name: 'Grocery Shopping',
        phrases: [
          Phrase('cart'),
          Phrase('checkout'),
          Phrase('receipt'),
          Phrase('aisle'),
          Phrase('Where can I find the milk?'),
          Phrase('Do you have any bags?'),
          Phrase('fresh produce'),
          Phrase('on sale'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Shopping',
    subjects: [
      Subject(
        name: 'Malls',
        phrases: [
          Phrase('storefront'),
          Phrase('fitting room'),
          Phrase('Do you have this in a different size?'),
          Phrase('How much does this cost?'),
          Phrase('discount'),
          Phrase('Can I return this?'),
          Phrase('escalator'),
        ],
      ),
      Subject(
        name: 'Souvenirs',
        phrases: [
          Phrase('souvenir'),
          Phrase('handmade'),
          Phrase('Is this locally made?'),
          Phrase('gift shop'),
          Phrase('Can you gift wrap this?'),
          Phrase('postcard'),
          Phrase('keychain'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Hiking / The Outdoors',
    subjects: [
      Subject(
        name: 'Hiking / The Outdoors',
        phrases: [
          Phrase('trail'),
          Phrase('trailhead'),
          Phrase('backpack'),
          Phrase('How long is this trail?'),
          Phrase('summit'),
          Phrase('Is this trail difficult?'),
          Phrase('water bottle'),
          Phrase('scenic view'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Talking About Family',
    subjects: [
      Subject(
        name: 'Talking About Family',
        phrases: [
          Phrase('sibling'),
          Phrase('parent'),
          Phrase('How many siblings do you have?'),
          Phrase('Do you have kids?'),
          Phrase('extended family'),
          Phrase('in-laws'),
          Phrase('I have two brothers and one sister.'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Talking About Aesthetics',
    subjects: [
      Subject(
        name: 'Talking About Aesthetics',
        phrases: [
          Phrase('That looks great on you.'),
          Phrase('style'),
          Phrase('I really like your outfit.'),
          Phrase('matching'),
          Phrase('trendy'),
          Phrase('That color suits you.'),
          Phrase('vintage'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Transportation',
    subjects: [
      Subject(
        name: 'Airports / Flying',
        phrases: [
          Phrase('boarding pass'),
          Phrase('gate'),
          Phrase('Where is baggage claim?'),
          Phrase('layover'),
          Phrase('security checkpoint'),
          Phrase('Is this flight on time?'),
          Phrase('carry-on'),
        ],
      ),
      Subject(
        name: 'Bus Stations',
        phrases: [
          Phrase('bus stop'),
          Phrase('fare'),
          Phrase('Which bus goes downtown?'),
          Phrase('schedule'),
          Phrase('Does this bus stop at the station?'),
          Phrase('transfer'),
        ],
      ),
      Subject(
        name: 'Taxis',
        phrases: [
          Phrase('Can you take me to this address?'),
          Phrase('meter'),
          Phrase('How much will it cost?'),
          Phrase('Please stop here.'),
          Phrase('tip'),
          Phrase('Is this the fastest route?'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Talking About Houses',
    subjects: [
      Subject(
        name: 'Talking About Houses',
        phrases: [
          Phrase('living room'),
          Phrase('backyard'),
          Phrase('How many bedrooms does it have?'),
          Phrase('landlord'),
          Phrase('rent'),
          Phrase('Make yourself at home.'),
          Phrase('neighborhood'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Museums',
    subjects: [
      Subject(
        name: 'Museums',
        phrases: [
          Phrase('exhibit'),
          Phrase('admission'),
          Phrase('Is there a guided tour?'),
          Phrase('gallery'),
          Phrase('artifact'),
          Phrase('Are photos allowed?'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Music',
    subjects: [
      Subject(
        name: 'Music',
        phrases: [
          Phrase('What kind of music do you like?'),
          Phrase('band'),
          Phrase('concert'),
          Phrase('playlist'),
          Phrase('This song is stuck in my head.'),
          Phrase('lyrics'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Occupations',
    subjects: [
      Subject(
        name: 'Occupations',
        phrases: [
          Phrase('What do you do for work?'),
          Phrase('coworker'),
          Phrase('I work as a teacher.'),
          Phrase('self-employed'),
          Phrase('shift'),
          Phrase('day off'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Speaking Casually',
    subjects: [
      Subject(
        name: 'Speaking Casually',
        phrases: [
          Phrase('What\'s up?'),
          Phrase('No worries.'),
          Phrase('For sure.'),
          Phrase('I\'m down.'),
          Phrase('That\'s wild.'),
          Phrase('Catch you later.'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Celebrations',
    subjects: [
      Subject(
        name: 'Wedding',
        phrases: [
          Phrase('bride'),
          Phrase('groom'),
          Phrase('Congratulations!'),
          Phrase('reception'),
          Phrase('toast'),
          Phrase('vows'),
        ],
      ),
      Subject(
        name: 'Graduation',
        phrases: [
          Phrase('diploma'),
          Phrase('Congratulations on graduating!'),
          Phrase('cap and gown'),
          Phrase('ceremony'),
          Phrase('What are your plans after graduation?'),
        ],
      ),
      Subject(
        name: 'Birthday',
        phrases: [
          Phrase('Happy birthday!'),
          Phrase('cake'),
          Phrase('How old are you turning?'),
          Phrase('candles'),
          Phrase('make a wish'),
        ],
      ),
      Subject(
        name: 'Holiday',
        phrases: [
          Phrase('Happy holidays!'),
          Phrase('tradition'),
          Phrase('decorations'),
          Phrase('What holidays do you celebrate?'),
          Phrase('gathering'),
        ],
      ),
    ],
  ),
  Category(
    name: 'TV Shows / Movies',
    subjects: [
      Subject(
        name: 'TV Shows / Movies',
        phrases: [
          Phrase('Have you seen this show?'),
          Phrase('episode'),
          Phrase('spoiler'),
          Phrase('season finale'),
          Phrase('What\'s your favorite movie?'),
          Phrase('plot twist'),
        ],
      ),
    ],
  ),
  Category(
    name: 'Going to a Party',
    subjects: [
      Subject(
        name: 'Going to a Party',
        phrases: [
          Phrase('Thanks for having me.'),
          Phrase('host'),
          Phrase('Can I bring anything?'),
          Phrase('guest list'),
          Phrase('Make yourself comfortable.'),
          Phrase('potluck'),
        ],
      ),
    ],
  ),
  Category(
    name: '20 Common Verbs',
    subjects: [
      Subject(
        name: '20 Common Verbs',
        phrases: [
          Phrase('to be'),
          Phrase('to have'),
          Phrase('to do'),
          Phrase('to say'),
          Phrase('to get'),
          Phrase('to make'),
          Phrase('to go'),
          Phrase('to know'),
          Phrase('to take'),
          Phrase('to see'),
          Phrase('to come'),
          Phrase('to think'),
          Phrase('to look'),
          Phrase('to want'),
          Phrase('to give'),
          Phrase('to use'),
          Phrase('to find'),
          Phrase('to tell'),
          Phrase('to ask'),
          Phrase('to work'),
        ],
      ),
    ],
  ),
];
