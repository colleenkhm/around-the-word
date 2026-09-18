import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/phrase.dart';
import '../theme/pocket_talk_theme.dart';

/// Mock Spanish content, seeded from the original UI mockup plus a few
/// extra categories so Home isn't just Food & drink. Placeholder data —
/// swap for real curated content later.
const List<Category> categories = [
  Category(
    id: 'food',
    name: 'Food & drink',
    icon: Icons.local_cafe_outlined,
    tint: PTTints.food,
  ),
  Category(
    id: 'transportation',
    name: 'Transportation',
    icon: Icons.directions_bus_filled_outlined,
    tint: PTTints.transport,
  ),
  Category(
    id: 'conversation',
    name: 'Conversation',
    icon: Icons.chat_bubble_outline,
    tint: PTTints.conversation,
  ),
  Category(
    id: 'emergencies',
    name: 'Emergencies',
    icon: Icons.emergency_outlined,
    tint: PTTints.emergencies,
  ),
  Category(
    id: 'basics',
    name: 'Basics',
    icon: Icons.book_outlined,
    tint: PTTints.basics,
  ),
];

const List<Phrase> allPhrases = [
  // Food & drink
  Phrase(id: 'food_1', categoryId: 'food', english: 'The check, please', target: 'La cuenta, por favor', pronunciation: 'lah KWEN-tah por fah-VOR', blankWord: 'cuenta'),
  Phrase(id: 'food_2', categoryId: 'food', english: 'What do you recommend?', target: '¿Qué recomienda?', pronunciation: 'keh reh-koh-mee-EN-dah', blankWord: 'recomienda'),
  Phrase(id: 'food_3', categoryId: 'food', english: 'Is this spicy?', target: '¿Esto pica?', pronunciation: 'EHS-toh PEE-kah', blankWord: 'pica'),
  Phrase(id: 'food_4', categoryId: 'food', english: 'A table for two', target: 'Una mesa para dos', pronunciation: 'OO-nah MEH-sah PAH-rah dohs', blankWord: 'mesa'),
  Phrase(id: 'food_5', categoryId: 'food', english: 'Still or sparkling water?', target: '¿Agua con o sin gas?', pronunciation: 'AH-gwah kohn oh seen gahs', blankWord: 'Agua'),
  Phrase(id: 'food_6', categoryId: 'food', english: 'Can I see the menu?', target: '¿Puedo ver el menú?', pronunciation: 'PWEH-doh vehr el meh-NOO', blankWord: 'menú'),
  Phrase(id: 'food_7', categoryId: 'food', english: 'One more, please', target: 'Uno más, por favor', pronunciation: 'OO-noh mahs por fah-VOR', blankWord: 'más'),
  Phrase(id: 'food_8', categoryId: 'food', english: 'How much is this?', target: '¿Cuánto cuesta esto?', pronunciation: 'KWAHN-toh KWEHS-tah EHS-toh', blankWord: 'cuesta'),
  Phrase(id: 'food_9', categoryId: 'food', english: "I'm allergic to nuts", target: 'Soy alérgico a los frutos secos', pronunciation: 'soy ah-LEHR-hee-koh ah lohs FROO-tohs SEH-kohs', blankWord: 'alérgico'),
  Phrase(id: 'food_10', categoryId: 'food', english: 'Does this contain dairy?', target: '¿Esto contiene lácteos?', pronunciation: 'EHS-toh kohn-tee-EH-neh LAHK-teh-ohs', blankWord: 'lácteos'),

  // Transportation
  Phrase(id: 'transportation_1', categoryId: 'transportation', english: 'Where is the train station?', target: '¿Dónde está la estación de tren?', pronunciation: 'DOHN-deh ehs-TAH lah ehs-tah-see-OHN deh trehn', blankWord: 'estación'),
  Phrase(id: 'transportation_2', categoryId: 'transportation', english: 'One ticket to the city center', target: 'Un boleto al centro', pronunciation: 'oon boh-LEH-toh al SEHN-troh', blankWord: 'boleto'),
  Phrase(id: 'transportation_3', categoryId: 'transportation', english: 'Does this bus go downtown?', target: '¿Este autobús va al centro?', pronunciation: 'EHS-teh ow-toh-BOOS vah al SEHN-troh', blankWord: 'autobús'),
  Phrase(id: 'transportation_4', categoryId: 'transportation', english: 'How much is a taxi to the airport?', target: '¿Cuánto cuesta un taxi al aeropuerto?', pronunciation: 'KWAHN-toh KWEHS-tah oon TAHK-see al ah-eh-roh-PWEHR-toh', blankWord: 'aeropuerto'),
  Phrase(id: 'transportation_5', categoryId: 'transportation', english: 'Is this seat taken?', target: '¿Está ocupado este asiento?', pronunciation: 'ehs-TAH oh-koo-PAH-doh EHS-teh ah-see-EHN-toh', blankWord: 'asiento'),

  // Conversation
  Phrase(id: 'conversation_1', categoryId: 'conversation', english: 'Nice to meet you', target: 'Mucho gusto', pronunciation: 'MOO-choh GOOS-toh', blankWord: 'gusto'),
  Phrase(id: 'conversation_2', categoryId: 'conversation', english: "I don't understand", target: 'No entiendo', pronunciation: 'noh en-tee-EHN-doh', blankWord: 'entiendo'),
  Phrase(id: 'conversation_3', categoryId: 'conversation', english: 'Can you speak slower?', target: '¿Puede hablar más despacio?', pronunciation: 'PWEH-deh ah-BLAR mahs dehs-PAH-see-oh', blankWord: 'despacio'),
  Phrase(id: 'conversation_4', categoryId: 'conversation', english: "What's your name?", target: '¿Cómo te llamas?', pronunciation: 'KOH-moh teh YAH-mahs', blankWord: 'llamas'),
  Phrase(id: 'conversation_5', categoryId: 'conversation', english: 'See you later', target: 'Hasta luego', pronunciation: 'AHS-tah LWEH-goh', blankWord: 'luego'),

  // Emergencies
  Phrase(id: 'emergencies_1', categoryId: 'emergencies', english: 'Call an ambulance', target: 'Llame a una ambulancia', pronunciation: 'YAH-meh ah OO-nah ahm-boo-LAHN-see-ah', blankWord: 'ambulancia'),
  Phrase(id: 'emergencies_2', categoryId: 'emergencies', english: 'I need a doctor', target: 'Necesito un médico', pronunciation: 'neh-seh-SEE-toh oon MEH-dee-koh', blankWord: 'médico'),
  Phrase(id: 'emergencies_3', categoryId: 'emergencies', english: 'Where is the nearest hospital?', target: '¿Dónde está el hospital más cercano?', pronunciation: 'DOHN-deh ehs-TAH el ohs-pee-TAHL mahs sehr-KAH-noh', blankWord: 'hospital'),
  Phrase(id: 'emergencies_4', categoryId: 'emergencies', english: "I've lost my passport", target: 'He perdido mi pasaporte', pronunciation: 'eh pehr-DEE-doh mee pah-sah-POR-teh', blankWord: 'pasaporte'),

  // Basics
  Phrase(id: 'basics_1', categoryId: 'basics', english: 'Please', target: 'Por favor', pronunciation: 'por fah-VOR', blankWord: 'favor'),
  Phrase(id: 'basics_2', categoryId: 'basics', english: 'Thank you', target: 'Gracias', pronunciation: 'GRAH-see-ahs', blankWord: 'Gracias'),
  Phrase(id: 'basics_3', categoryId: 'basics', english: 'Good morning', target: 'Buenos días', pronunciation: 'BWEH-nohs DEE-ahs', blankWord: 'días'),
  Phrase(id: 'basics_4', categoryId: 'basics', english: 'Excuse me', target: 'Disculpe', pronunciation: 'dees-KOOL-peh', blankWord: 'Disculpe'),
  Phrase(id: 'basics_5', categoryId: 'basics', english: "I'm sorry", target: 'Lo siento', pronunciation: 'loh see-EHN-toh', blankWord: 'siento'),
];

Category categoryById(String id) => categories.firstWhere((c) => c.id == id);

List<Phrase> phrasesForCategory(String categoryId) =>
    allPhrases.where((p) => p.categoryId == categoryId).toList();
