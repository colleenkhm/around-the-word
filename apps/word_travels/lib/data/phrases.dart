import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/phrase.dart';
import '../models/place.dart';
import '../theme/pocket_talk_theme.dart';

/// Mock Spanish content, seeded from the original UI mockup plus a few
/// extra categories so Home isn't just Food & drink. Placeholder data —
/// swap for real curated content later.
/// The language the phrases teach. Shown in the app bar so the user always
/// knows which language they're in.
const String targetLanguage = 'Spanish';

/// Countries a user can pick. Country variants and country-specific phrases
/// may only name countries from this list.
const List<String> spanishCountries = ['Mexico', 'Spain', 'Chile', 'Argentina'];

/// Kinds of setting a user can say they'll be in. Phrases may only name
/// settings from this list.
const List<EnvironmentOption> environmentOptions = [
  EnvironmentOption('Urban', 'Cities and large towns'),
  EnvironmentOption('Rural', 'Countryside and small villages'),
  EnvironmentOption('Coastal', 'Beaches, ports and seaside towns'),
  EnvironmentOption('Mountain', 'Highlands, hiking and altitude'),
];

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
  Category(
    id: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag_outlined,
    tint: PTTints.shopping,
  ),
  Category(
    id: 'lodging',
    name: 'Lodging',
    icon: Icons.hotel_outlined,
    tint: PTTints.lodging,
  ),
  Category(
    id: 'health',
    name: 'Health',
    icon: Icons.medical_services_outlined,
    tint: PTTints.health,
  ),
];

const List<Phrase> allPhrases = [
  // Food & drink
  Phrase(id: 'food_1', categoryId: 'food', english: 'The check, please', target: 'La cuenta, por favor', pronunciation: 'lah KWEN-tah por fah-VOR', blankWord: 'cuenta'),
  Phrase(id: 'food_2', categoryId: 'food', english: 'What do you recommend?', target: '¿Qué recomienda?', pronunciation: 'keh reh-koh-mee-EN-dah', blankWord: 'recomienda'),
  Phrase(id: 'food_3', categoryId: 'food', english: 'Is this spicy?', target: '¿Esto pica?', pronunciation: 'EHS-toh PEE-kah', blankWord: 'pica'),
  Phrase(id: 'food_4', categoryId: 'food', english: 'A table for two', target: 'Una mesa para dos', pronunciation: 'OO-nah MEH-sah PAH-rah dohs', blankWord: 'mesa'),
  Phrase(id: 'food_5', categoryId: 'food', english: 'Still or sparkling water?', target: '¿Agua con o sin gas?', pronunciation: 'AH-gwah kohn oh seen gahs', blankWord: 'Agua'),
  Phrase(
    id: 'food_6',
    categoryId: 'food',
    english: 'Can I see the menu?',
    target: '¿Puedo ver el menú?',
    pronunciation: 'PWEH-doh vehr el meh-NOO',
    blankWord: 'menú',
    variants: [
      CountryVariant(
        countries: ['Mexico'],
        target: '¿Puedo ver el menú?',
        pronunciation: 'PWEH-doh vehr el meh-NOO',
        blankWord: 'menú',
      ),
      CountryVariant(
        countries: ['Spain', 'Chile'],
        target: '¿Puedo ver la carta?',
        pronunciation: 'PWEH-doh vehr lah KAR-tah',
        blankWord: 'carta',
      ),
    ],
  ),
  Phrase(id: 'food_7', categoryId: 'food', english: 'One more, please', target: 'Uno más, por favor', pronunciation: 'OO-noh mahs por fah-VOR', blankWord: 'más'),
  Phrase(id: 'food_8', categoryId: 'food', english: 'How much is this?', target: '¿Cuánto cuesta esto?', pronunciation: 'KWAHN-toh KWEHS-tah EHS-toh', blankWord: 'cuesta'),
  Phrase(id: 'food_9', categoryId: 'food', english: "I'm allergic to nuts", target: 'Soy alérgico a los frutos secos', pronunciation: 'soy ah-LEHR-hee-koh ah lohs FROO-tohs SEH-kohs', blankWord: 'alérgico'),
  Phrase(id: 'food_10', categoryId: 'food', english: 'Does this contain dairy?', target: '¿Esto contiene lácteos?', pronunciation: 'EHS-toh kohn-tee-EH-neh LAHK-teh-ohs', blankWord: 'lácteos'),
  Phrase(id: 'food_11', categoryId: 'food', english: 'I would like a coffee', target: 'Quisiera un café', pronunciation: 'kee-see-EH-rah oon kah-FEH', blankWord: 'café'),
  Phrase(id: 'food_12', categoryId: 'food', english: "I'm vegetarian", target: 'Soy vegetariano', pronunciation: 'soy veh-heh-tah-ree-AH-noh', blankWord: 'vegetariano'),
  Phrase(id: 'food_13', categoryId: 'food', english: 'Water, please', target: 'Agua, por favor', pronunciation: 'AH-gwah por fah-VOR', blankWord: 'Agua'),
  Phrase(id: 'food_14', categoryId: 'food', english: 'Cheers!', target: '¡Salud!', pronunciation: 'sah-LOOD', blankWord: 'Salud'),
  Phrase(id: 'food_15', categoryId: 'food', english: "It's delicious", target: 'Está delicioso', pronunciation: 'ehs-TAH deh-lee-see-OH-soh', blankWord: 'delicioso'),
  Phrase(id: 'food_16', categoryId: 'food', english: "I'm hungry", target: 'Tengo hambre', pronunciation: 'TEHN-goh AHM-breh', blankWord: 'hambre'),
  Phrase(id: 'food_17', categoryId: 'food', english: "I'm thirsty", target: 'Tengo sed', pronunciation: 'TEHN-goh sehd', blankWord: 'sed'),
  Phrase(id: 'food_18', categoryId: 'food', english: 'Without meat, please', target: 'Sin carne, por favor', pronunciation: 'seen KAR-neh por fah-VOR', blankWord: 'carne'),
  Phrase(id: 'food_19', categoryId: 'food', english: 'Can we split the bill?', target: '¿Podemos dividir la cuenta?', pronunciation: 'poh-DEH-mohs dee-vee-DEER lah KWEN-tah', blankWord: 'dividir'),
  Phrase(id: 'food_20', categoryId: 'food', english: 'Do you take cards?', target: '¿Aceptan tarjetas?', pronunciation: 'ah-SEHP-tahn tar-HEH-tahs', blankWord: 'tarjetas'),
  Phrase(id: 'food_21', categoryId: 'food', english: 'Is the tip included?', target: '¿Está incluida la propina?', pronunciation: 'ehs-TAH een-kloo-EE-dah lah proh-PEE-nah', blankWord: 'propina'),
  Phrase(id: 'food_22', categoryId: 'food', english: 'Coffee with milk', target: 'Café con leche', pronunciation: 'kah-FEH kohn LEH-cheh', blankWord: 'leche'),
  Phrase(id: 'food_23', categoryId: 'food', english: "I'll have the same", target: 'Yo quiero lo mismo', pronunciation: 'yoh kee-EH-roh loh MEES-moh', blankWord: 'mismo'),
  Phrase(id: 'food_24', categoryId: 'food', english: 'A bottle of red wine', target: 'Una botella de vino tinto', pronunciation: 'OO-nah boh-TEH-yah deh VEE-noh TEEN-toh', blankWord: 'botella'),

  // Transportation
  Phrase(id: 'transportation_1', categoryId: 'transportation', english: 'Where is the train station?', target: '¿Dónde está la estación de tren?', pronunciation: 'DOHN-deh ehs-TAH lah ehs-tah-see-OHN deh trehn', blankWord: 'estación'),
  Phrase(
    id: 'transportation_2',
    categoryId: 'transportation',
    english: 'One ticket to the city center',
    target: 'Un boleto al centro',
    pronunciation: 'oon boh-LEH-toh al SEHN-troh',
    blankWord: 'boleto',
    variants: [
      CountryVariant(
        countries: ['Mexico'],
        target: 'Un boleto al centro',
        pronunciation: 'oon boh-LEH-toh al SEHN-troh',
        blankWord: 'boleto',
      ),
      CountryVariant(
        countries: ['Chile'],
        target: 'Un pasaje al centro',
        pronunciation: 'oon pah-SAH-heh al SEHN-troh',
        blankWord: 'pasaje',
      ),
      CountryVariant(
        countries: ['Spain'],
        target: 'Un billete al centro',
        pronunciation: 'oon bee-YEH-teh al SEHN-troh',
        blankWord: 'billete',
      ),
    ],
  ),
  Phrase(
    id: 'transportation_3',
    categoryId: 'transportation',
    english: 'Does this bus go downtown?',
    target: '¿Este camión va al centro?',
    pronunciation: 'EHS-teh kah-mee-OHN vah al SEHN-troh',
    blankWord: 'camión',
    variants: [
      CountryVariant(
        countries: ['Mexico'],
        target: '¿Este camión va al centro?',
        pronunciation: 'EHS-teh kah-mee-OHN vah al SEHN-troh',
        blankWord: 'camión',
      ),
      CountryVariant(
        countries: ['Chile'],
        target: '¿Esta micro va al centro?',
        pronunciation: 'EHS-tah MEE-kroh vah al SEHN-troh',
        blankWord: 'micro',
      ),
      CountryVariant(
        countries: ['Argentina'],
        target: '¿Este colectivo va al centro?',
        pronunciation: 'EHS-teh koh-lehk-TEE-voh vah al SEHN-troh',
        blankWord: 'colectivo',
      ),
      CountryVariant(
        countries: ['Spain'],
        target: '¿Este autobús va al centro?',
        pronunciation: 'EHS-teh ow-toh-BOOS vah al SEHN-troh',
        blankWord: 'autobús',
      ),
    ],
  ),
  Phrase(id: 'transportation_4', categoryId: 'transportation', english: 'How much is a taxi to the airport?', target: '¿Cuánto cuesta un taxi al aeropuerto?', pronunciation: 'KWAHN-toh KWEHS-tah oon TAHK-see al ah-eh-roh-PWEHR-toh', blankWord: 'aeropuerto'),
  Phrase(id: 'transportation_5', categoryId: 'transportation', english: 'Is this seat taken?', target: '¿Está ocupado este asiento?', pronunciation: 'ehs-TAH oh-koo-PAH-doh EHS-teh ah-see-EHN-toh', blankWord: 'asiento'),
  Phrase(id: 'transportation_6', categoryId: 'transportation', english: 'Where is the bus stop?', target: '¿Dónde está la parada de autobús?', pronunciation: 'DOHN-deh ehs-TAH lah pah-RAH-dah deh ow-toh-BOOS', blankWord: 'parada'),
  Phrase(id: 'transportation_7', categoryId: 'transportation', english: 'What time does the train leave?', target: '¿A qué hora sale el tren?', pronunciation: 'ah keh OH-rah SAH-leh el trehn', blankWord: 'sale'),
  Phrase(id: 'transportation_8', categoryId: 'transportation', english: 'Round trip, please', target: 'Ida y vuelta, por favor', pronunciation: 'EE-dah ee VWEHL-tah por fah-VOR', blankWord: 'vuelta'),
  Phrase(id: 'transportation_9', categoryId: 'transportation', english: 'Where is the subway?', target: '¿Dónde está el metro?', pronunciation: 'DOHN-deh ehs-TAH el MEH-troh', blankWord: 'metro'),
  Phrase(id: 'transportation_10', categoryId: 'transportation', english: 'Please stop here', target: 'Pare aquí, por favor', pronunciation: 'PAH-reh ah-KEE por fah-VOR', blankWord: 'aquí'),
  Phrase(id: 'transportation_11', categoryId: 'transportation', english: 'Turn left', target: 'Gire a la izquierda', pronunciation: 'HEE-reh ah lah ees-kee-EHR-dah', blankWord: 'izquierda'),
  Phrase(id: 'transportation_12', categoryId: 'transportation', english: 'Turn right', target: 'Gire a la derecha', pronunciation: 'HEE-reh ah lah deh-REH-chah', blankWord: 'derecha'),
  Phrase(id: 'transportation_13', categoryId: 'transportation', english: 'Go straight ahead', target: 'Siga derecho', pronunciation: 'SEE-gah deh-REH-choh', blankWord: 'derecho'),
  Phrase(id: 'transportation_14', categoryId: 'transportation', english: 'Is it far from here?', target: '¿Está lejos de aquí?', pronunciation: 'ehs-TAH LEH-hohs deh ah-KEE', blankWord: 'lejos'),
  Phrase(
    id: 'transportation_15',
    categoryId: 'transportation',
    english: 'Where can I rent a car?',
    target: '¿Dónde puedo rentar un carro?',
    pronunciation: 'DOHN-deh PWEH-doh rehn-TAR oon KAH-rroh',
    blankWord: 'carro',
    variants: [
      CountryVariant(
        countries: ['Mexico'],
        target: '¿Dónde puedo rentar un carro?',
        pronunciation: 'DOHN-deh PWEH-doh rehn-TAR oon KAH-rroh',
        blankWord: 'carro',
      ),
      CountryVariant(
        countries: ['Chile'],
        target: '¿Dónde puedo arrendar un auto?',
        pronunciation: 'DOHN-deh PWEH-doh ah-rrehn-DAR oon OW-toh',
        blankWord: 'auto',
      ),
      CountryVariant(
        countries: ['Spain'],
        target: '¿Dónde puedo alquilar un coche?',
        pronunciation: 'DOHN-deh PWEH-doh al-kee-LAR oon KOH-cheh',
        blankWord: 'coche',
      ),
    ],
  ),
  Phrase(id: 'transportation_16', categoryId: 'transportation', english: 'Where is the departure gate?', target: '¿Dónde está la puerta de embarque?', pronunciation: 'DOHN-deh ehs-TAH lah PWEHR-tah deh ehm-BAR-keh', blankWord: 'embarque'),
  Phrase(id: 'transportation_17', categoryId: 'transportation', english: 'I missed my flight', target: 'Perdí mi vuelo', pronunciation: 'pehr-DEE mee VWEH-loh', blankWord: 'vuelo'),
  Phrase(id: 'transportation_18', categoryId: 'transportation', english: 'Where is my luggage?', target: '¿Dónde está mi equipaje?', pronunciation: 'DOHN-deh ehs-TAH mee eh-kee-PAH-heh', blankWord: 'equipaje'),
  Phrase(id: 'transportation_19', categoryId: 'transportation', english: 'Which metro line goes to the center?', target: '¿Qué línea del metro va al centro?', pronunciation: 'keh LEE-neh-ah del MEH-troh vah al SEHN-troh', blankWord: 'línea', environments: ['Urban']),
  Phrase(id: 'transportation_20', categoryId: 'transportation', english: 'Where can I get a taxi?', target: '¿Dónde puedo tomar un taxi?', pronunciation: 'DOHN-deh PWEH-doh toh-MAR oon TAHK-see', blankWord: 'tomar', environments: ['Urban']),
  Phrase(id: 'transportation_21', categoryId: 'transportation', english: 'Is there a night bus?', target: '¿Hay autobús nocturno?', pronunciation: 'eye ow-toh-BOOS nohk-TOOR-noh', blankWord: 'nocturno', environments: ['Urban']),
  Phrase(id: 'transportation_22', categoryId: 'transportation', english: 'Is there a bus to the village?', target: '¿Hay un autobús al pueblo?', pronunciation: 'eye oon ow-toh-BOOS al PWEH-bloh', blankWord: 'pueblo', environments: ['Rural']),
  Phrase(id: 'transportation_23', categoryId: 'transportation', english: 'Where is the nearest gas station?', target: '¿Dónde está la gasolinera más cercana?', pronunciation: 'DOHN-deh ehs-TAH lah gah-soh-lee-NEH-rah mahs sehr-KAH-nah', blankWord: 'gasolinera', environments: ['Rural']),
  Phrase(id: 'transportation_24', categoryId: 'transportation', english: 'What time does the boat leave?', target: '¿A qué hora sale el barco?', pronunciation: 'ah keh OH-rah SAH-leh el BAR-koh', blankWord: 'barco', environments: ['Coastal']),
  Phrase(id: 'transportation_25', categoryId: 'transportation', english: 'Is the trail open?', target: '¿Está abierto el sendero?', pronunciation: 'ehs-TAH ah-bee-EHR-toh el sehn-DEH-roh', blankWord: 'sendero', environments: ['Mountain', 'Rural']),
  Phrase(id: 'transportation_26', categoryId: 'transportation', english: 'How long is the hike?', target: '¿Cuánto dura la caminata?', pronunciation: 'KWAHN-toh DOO-rah lah kah-mee-NAH-tah', blankWord: 'caminata', environments: ['Mountain', 'Rural']),

  // Conversation
  Phrase(id: 'conversation_1', categoryId: 'conversation', english: 'Nice to meet you', target: 'Mucho gusto', pronunciation: 'MOO-choh GOOS-toh', blankWord: 'gusto'),
  Phrase(id: 'conversation_2', categoryId: 'conversation', english: "I don't understand", target: 'No entiendo', pronunciation: 'noh en-tee-EHN-doh', blankWord: 'entiendo'),
  Phrase(id: 'conversation_3', categoryId: 'conversation', english: 'Can you speak slower?', target: '¿Puede hablar más despacio?', pronunciation: 'PWEH-deh ah-BLAR mahs dehs-PAH-see-oh', blankWord: 'despacio'),
  Phrase(id: 'conversation_4', categoryId: 'conversation', english: "What's your name?", target: '¿Cómo te llamas?', pronunciation: 'KOH-moh teh YAH-mahs', blankWord: 'llamas'),
  Phrase(id: 'conversation_5', categoryId: 'conversation', english: 'See you later', target: 'Hasta luego', pronunciation: 'AHS-tah LWEH-goh', blankWord: 'luego'),
  Phrase(id: 'conversation_6', categoryId: 'conversation', english: 'How are you?', target: '¿Cómo estás?', pronunciation: 'KOH-moh ehs-TAHS', blankWord: 'estás'),
  Phrase(id: 'conversation_7', categoryId: 'conversation', english: "I'm fine, thanks", target: 'Estoy bien, gracias', pronunciation: 'ehs-TOY bee-EHN GRAH-see-ahs', blankWord: 'bien'),
  Phrase(id: 'conversation_8', categoryId: 'conversation', english: 'Do you speak English?', target: '¿Habla inglés?', pronunciation: 'AH-blah een-GLEHS', blankWord: 'inglés'),
  Phrase(id: 'conversation_9', categoryId: 'conversation', english: 'I speak a little Spanish', target: 'Hablo un poco de español', pronunciation: 'AH-bloh oon POH-koh deh ehs-pah-NYOL', blankWord: 'poco'),
  Phrase(id: 'conversation_10', categoryId: 'conversation', english: 'Can you repeat that?', target: '¿Puede repetir?', pronunciation: 'PWEH-deh reh-peh-TEER', blankWord: 'repetir'),
  Phrase(id: 'conversation_11', categoryId: 'conversation', english: 'Where are you from?', target: '¿De dónde eres?', pronunciation: 'deh DOHN-deh EH-rehs', blankWord: 'eres'),
  Phrase(id: 'conversation_12', categoryId: 'conversation', english: "I'm from the United States", target: 'Soy de Estados Unidos', pronunciation: 'soy deh ehs-TAH-dohs oo-NEE-dohs', blankWord: 'Estados'),
  Phrase(id: 'conversation_13', categoryId: 'conversation', english: 'What does that mean?', target: '¿Qué significa eso?', pronunciation: 'keh seeg-nee-FEE-kah EH-soh', blankWord: 'significa'),
  Phrase(id: 'conversation_14', categoryId: 'conversation', english: 'How do you say that?', target: '¿Cómo se dice eso?', pronunciation: 'KOH-moh seh DEE-seh EH-soh', blankWord: 'dice'),
  Phrase(id: 'conversation_15', categoryId: 'conversation', english: 'Good afternoon', target: 'Buenas tardes', pronunciation: 'BWEH-nahs TAR-dehs', blankWord: 'tardes'),
  Phrase(id: 'conversation_16', categoryId: 'conversation', english: 'Good night', target: 'Buenas noches', pronunciation: 'BWEH-nahs NOH-chehs', blankWord: 'noches'),
  Phrase(id: 'conversation_17', categoryId: 'conversation', english: 'Have a nice day', target: 'Que tenga un buen día', pronunciation: 'keh TEHN-gah oon bwehn DEE-ah', blankWord: 'día'),
  Phrase(id: 'conversation_18', categoryId: 'conversation', english: 'Congratulations!', target: '¡Felicidades!', pronunciation: 'feh-lee-see-DAH-dehs', blankWord: 'Felicidades'),
  Phrase(id: 'conversation_19', categoryId: 'conversation', english: 'Of course', target: 'Claro que sí', pronunciation: 'KLAH-roh keh see', blankWord: 'Claro'),
  Phrase(id: 'conversation_20', categoryId: 'conversation', english: 'I agree', target: 'Estoy de acuerdo', pronunciation: 'ehs-TOY deh ah-KWEHR-doh', blankWord: 'acuerdo'),
  Phrase(id: 'conversation_21', categoryId: 'conversation', english: "What's up?", target: '¿Qué onda?', pronunciation: 'keh OHN-dah', blankWord: 'onda', countries: ['Mexico']),
  Phrase(id: 'conversation_22', categoryId: 'conversation', english: 'Pardon?', target: '¿Mande?', pronunciation: 'MAHN-deh', blankWord: 'Mande', countries: ['Mexico']),
  Phrase(id: 'conversation_23', categoryId: 'conversation', english: 'Okay!', target: '¡Vale!', pronunciation: 'BAH-leh', blankWord: 'Vale', countries: ['Spain']),
  Phrase(id: 'conversation_24', categoryId: 'conversation', english: 'Do you get it?', target: '¿Cachai?', pronunciation: 'kah-CHIE', blankWord: 'Cachai', countries: ['Chile']),
  Phrase(id: 'conversation_25', categoryId: 'conversation', english: "How's it going?", target: '¿Cómo andás?', pronunciation: 'KOH-moh ahn-DAHS', blankWord: 'andás', countries: ['Argentina']),
  Phrase(id: 'conversation_26', categoryId: 'conversation', english: 'Is this neighborhood safe?', target: '¿Es seguro este barrio?', pronunciation: 'ehs seh-GOO-roh EHS-teh BAH-rree-oh', blankWord: 'barrio', environments: ['Urban']),

  // Emergencies
  Phrase(id: 'emergencies_1', categoryId: 'emergencies', english: 'Call an ambulance', target: 'Llame a una ambulancia', pronunciation: 'YAH-meh ah OO-nah ahm-boo-LAHN-see-ah', blankWord: 'ambulancia'),
  Phrase(id: 'emergencies_2', categoryId: 'emergencies', english: 'I need a doctor', target: 'Necesito un médico', pronunciation: 'neh-seh-SEE-toh oon MEH-dee-koh', blankWord: 'médico'),
  Phrase(id: 'emergencies_3', categoryId: 'emergencies', english: 'Where is the nearest hospital?', target: '¿Dónde está el hospital más cercano?', pronunciation: 'DOHN-deh ehs-TAH el ohs-pee-TAHL mahs sehr-KAH-noh', blankWord: 'hospital'),
  Phrase(id: 'emergencies_4', categoryId: 'emergencies', english: "I've lost my passport", target: 'He perdido mi pasaporte', pronunciation: 'eh pehr-DEE-doh mee pah-sah-POR-teh', blankWord: 'pasaporte'),
  Phrase(id: 'emergencies_5', categoryId: 'emergencies', english: 'Help!', target: '¡Ayuda!', pronunciation: 'ah-YOO-dah', blankWord: 'Ayuda'),
  Phrase(id: 'emergencies_6', categoryId: 'emergencies', english: 'Call the police', target: 'Llame a la policía', pronunciation: 'YAH-meh ah lah poh-lee-SEE-ah', blankWord: 'policía'),
  Phrase(id: 'emergencies_7', categoryId: 'emergencies', english: "I'm lost", target: 'Estoy perdido', pronunciation: 'ehs-TOY pehr-DEE-doh', blankWord: 'perdido'),
  Phrase(id: 'emergencies_8', categoryId: 'emergencies', english: 'I feel sick', target: 'Me siento mal', pronunciation: 'meh see-EHN-toh mahl', blankWord: 'mal'),
  Phrase(id: 'emergencies_9', categoryId: 'emergencies', english: 'It hurts here', target: 'Me duele aquí', pronunciation: 'meh DWEH-leh ah-KEE', blankWord: 'duele'),
  Phrase(id: 'emergencies_10', categoryId: 'emergencies', english: 'I need a pharmacy', target: 'Necesito una farmacia', pronunciation: 'neh-seh-SEE-toh OO-nah far-MAH-see-ah', blankWord: 'farmacia'),
  Phrase(id: 'emergencies_11', categoryId: 'emergencies', english: 'Fire!', target: '¡Fuego!', pronunciation: 'FWEH-goh', blankWord: 'Fuego'),
  Phrase(
    id: 'emergencies_12',
    categoryId: 'emergencies',
    english: 'My wallet was stolen',
    target: 'Me robaron la cartera',
    pronunciation: 'meh roh-BAH-rohn lah kar-TEH-rah',
    blankWord: 'cartera',
    variants: [
      CountryVariant(
        countries: ['Mexico', 'Spain'],
        target: 'Me robaron la cartera',
        pronunciation: 'meh roh-BAH-rohn lah kar-TEH-rah',
        blankWord: 'cartera',
      ),
      CountryVariant(
        countries: ['Chile', 'Argentina'],
        target: 'Me robaron la billetera',
        pronunciation: 'meh roh-BAH-rohn lah bee-yeh-TEH-rah',
        blankWord: 'billetera',
      ),
    ],
  ),
  Phrase(id: 'emergencies_13', categoryId: 'emergencies', english: 'I have a fever', target: 'Tengo fiebre', pronunciation: 'TEHN-goh fee-EH-breh', blankWord: 'fiebre'),
  Phrase(id: 'emergencies_14', categoryId: 'emergencies', english: "It's an emergency", target: 'Es una emergencia', pronunciation: 'ehs OO-nah eh-mehr-HEHN-see-ah', blankWord: 'emergencia'),
  Phrase(id: 'emergencies_15', categoryId: 'emergencies', english: 'I need help', target: 'Necesito ayuda', pronunciation: 'neh-seh-SEE-toh ah-YOO-dah', blankWord: 'ayuda'),
  Phrase(id: 'emergencies_16', categoryId: 'emergencies', english: 'Is it safe to swim here?', target: '¿Es seguro nadar aquí?', pronunciation: 'ehs seh-GOO-roh nah-DAR ah-KEE', blankWord: 'nadar', environments: ['Coastal']),
  Phrase(
    id: 'emergencies_17',
    categoryId: 'emergencies',
    english: 'Where is the lifeguard?',
    target: '¿Dónde está el salvavidas?',
    pronunciation: 'DOHN-deh ehs-TAH el sahl-vah-VEE-dahs',
    blankWord: 'salvavidas',
    environments: ['Coastal'],
    variants: [
      CountryVariant(countries: ['Mexico', 'Chile'], target: '¿Dónde está el salvavidas?', pronunciation: 'DOHN-deh ehs-TAH el sahl-vah-VEE-dahs', blankWord: 'salvavidas'),
      CountryVariant(countries: ['Spain'], target: '¿Dónde está el socorrista?', pronunciation: 'DOHN-deh ehs-TAH el soh-koh-RREES-tah', blankWord: 'socorrista'),
      CountryVariant(countries: ['Argentina'], target: '¿Dónde está el guardavidas?', pronunciation: 'DOHN-deh ehs-TAH el gwar-dah-VEE-dahs', blankWord: 'guardavidas'),
    ],
  ),

  // Basics
  Phrase(id: 'basics_1', categoryId: 'basics', english: 'Please', target: 'Por favor', pronunciation: 'por fah-VOR', blankWord: 'favor'),
  Phrase(id: 'basics_2', categoryId: 'basics', english: 'Thank you', target: 'Gracias', pronunciation: 'GRAH-see-ahs', blankWord: 'Gracias'),
  Phrase(id: 'basics_3', categoryId: 'basics', english: 'Good morning', target: 'Buenos días', pronunciation: 'BWEH-nohs DEE-ahs', blankWord: 'días'),
  Phrase(id: 'basics_4', categoryId: 'basics', english: 'Excuse me', target: 'Disculpe', pronunciation: 'dees-KOOL-peh', blankWord: 'Disculpe'),
  Phrase(id: 'basics_5', categoryId: 'basics', english: "I'm sorry", target: 'Lo siento', pronunciation: 'loh see-EHN-toh', blankWord: 'siento'),
  Phrase(id: 'basics_6', categoryId: 'basics', english: 'Yes', target: 'Sí', pronunciation: 'see', blankWord: 'Sí'),
  Phrase(id: 'basics_7', categoryId: 'basics', english: 'Hello', target: 'Hola', pronunciation: 'OH-lah', blankWord: 'Hola'),
  Phrase(id: 'basics_8', categoryId: 'basics', english: 'Goodbye', target: 'Adiós', pronunciation: 'ah-dee-OHS', blankWord: 'Adiós'),
  Phrase(id: 'basics_9', categoryId: 'basics', english: "You're welcome", target: 'De nada', pronunciation: 'deh NAH-dah', blankWord: 'nada'),
  Phrase(id: 'basics_10', categoryId: 'basics', english: 'Where is the restroom?', target: '¿Dónde está el baño?', pronunciation: 'DOHN-deh ehs-TAH el BAH-nyoh', blankWord: 'baño'),
  Phrase(id: 'basics_11', categoryId: 'basics', english: 'What time is it?', target: '¿Qué hora es?', pronunciation: 'keh OH-rah ehs', blankWord: 'hora'),
  Phrase(id: 'basics_12', categoryId: 'basics', english: 'Today', target: 'Hoy', pronunciation: 'oy', blankWord: 'Hoy'),
  Phrase(id: 'basics_13', categoryId: 'basics', english: 'Tomorrow', target: 'Mañana', pronunciation: 'mah-NYAH-nah', blankWord: 'Mañana'),
  Phrase(id: 'basics_14', categoryId: 'basics', english: 'Yesterday', target: 'Ayer', pronunciation: 'ah-YEHR', blankWord: 'Ayer'),
  Phrase(id: 'basics_15', categoryId: 'basics', english: 'One, two, three', target: 'Uno, dos, tres', pronunciation: 'OO-noh dohs trehs', blankWord: 'tres'),
  Phrase(id: 'basics_16', categoryId: 'basics', english: "I don't know", target: 'No sé', pronunciation: 'noh seh', blankWord: 'sé'),
  Phrase(id: 'basics_17', categoryId: 'basics', english: 'Maybe', target: 'Quizás', pronunciation: 'kee-SAHS', blankWord: 'Quizás'),
  Phrase(id: 'basics_18', categoryId: 'basics', english: 'Just a moment', target: 'Un momento', pronunciation: 'oon moh-MEHN-toh', blankWord: 'momento'),
  Phrase(id: 'basics_19', categoryId: 'basics', english: 'Very good', target: 'Muy bien', pronunciation: 'mwee bee-EHN', blankWord: 'bien'),

  // Shopping
  Phrase(id: 'shopping_1', categoryId: 'shopping', english: 'Do you have a smaller size?', target: '¿Tiene una talla más pequeña?', pronunciation: 'tee-EH-neh OO-nah TAH-yah mahs peh-KEH-nyah', blankWord: 'talla'),
  Phrase(id: 'shopping_2', categoryId: 'shopping', english: "I'm just looking", target: 'Solo estoy mirando', pronunciation: 'SOH-loh ehs-TOY mee-RAHN-doh', blankWord: 'mirando'),
  Phrase(id: 'shopping_3', categoryId: 'shopping', english: 'Can I try it on?', target: '¿Me lo puedo probar?', pronunciation: 'meh loh PWEH-doh proh-BAR', blankWord: 'probar'),
  Phrase(id: 'shopping_4', categoryId: 'shopping', english: "It's too expensive", target: 'Es muy caro', pronunciation: 'ehs mwee KAH-roh', blankWord: 'caro'),
  Phrase(id: 'shopping_5', categoryId: 'shopping', english: 'Do you have a discount?', target: '¿Tiene descuento?', pronunciation: 'tee-EH-neh dehs-KWEHN-toh', blankWord: 'descuento'),
  Phrase(id: 'shopping_6', categoryId: 'shopping', english: "I'll take it", target: 'Me lo llevo', pronunciation: 'meh loh YEH-voh', blankWord: 'llevo'),
  Phrase(id: 'shopping_7', categoryId: 'shopping', english: 'Can I pay by card?', target: '¿Puedo pagar con tarjeta?', pronunciation: 'PWEH-doh pah-GAR kohn tar-HEH-tah', blankWord: 'pagar'),
  Phrase(id: 'shopping_8', categoryId: 'shopping', english: 'Where is the ATM?', target: '¿Dónde hay un cajero automático?', pronunciation: 'DOHN-deh eye oon kah-HEH-roh ow-toh-MAH-tee-koh', blankWord: 'cajero'),
  Phrase(id: 'shopping_9', categoryId: 'shopping', english: 'Can I have a bag?', target: '¿Me da una bolsa?', pronunciation: 'meh dah OO-nah BOHL-sah', blankWord: 'bolsa'),
  Phrase(id: 'shopping_10', categoryId: 'shopping', english: 'What time do you open?', target: '¿A qué hora abren?', pronunciation: 'ah keh OH-rah AH-brehn', blankWord: 'abren'),
  Phrase(id: 'shopping_11', categoryId: 'shopping', english: 'What time do you close?', target: '¿A qué hora cierran?', pronunciation: 'ah keh OH-rah see-EH-rrahn', blankWord: 'cierran'),
  Phrase(id: 'shopping_12', categoryId: 'shopping', english: 'Do you have this in blue?', target: '¿Lo tiene en azul?', pronunciation: 'loh tee-EH-neh ehn ah-SOOL', blankWord: 'azul'),
  Phrase(id: 'shopping_13', categoryId: 'shopping', english: 'A receipt, please', target: 'El recibo, por favor', pronunciation: 'ehl reh-SEE-boh por fah-VOR', blankWord: 'recibo'),

  // Lodging
  Phrase(
    id: 'lodging_1',
    categoryId: 'lodging',
    english: 'I have a reservation',
    target: 'Tengo una reservación',
    pronunciation: 'TEHN-goh OO-nah reh-sehr-vah-see-OHN',
    blankWord: 'reservación',
    variants: [
      CountryVariant(
        countries: ['Mexico'],
        target: 'Tengo una reservación',
        pronunciation: 'TEHN-goh OO-nah reh-sehr-vah-see-OHN',
        blankWord: 'reservación',
      ),
      CountryVariant(
        countries: ['Spain', 'Chile'],
        target: 'Tengo una reserva',
        pronunciation: 'TEHN-goh OO-nah reh-SEHR-vah',
        blankWord: 'reserva',
      ),
    ],
  ),
  Phrase(id: 'lodging_2', categoryId: 'lodging', english: 'Do you have any rooms available?', target: '¿Tiene habitaciones disponibles?', pronunciation: 'tee-EH-neh ah-bee-tah-see-OH-nehs dees-poh-NEE-blehs', blankWord: 'disponibles'),
  Phrase(id: 'lodging_3', categoryId: 'lodging', english: 'A single room, please', target: 'Una habitación individual, por favor', pronunciation: 'OO-nah ah-bee-tah-see-OHN een-dee-vee-doo-AHL por fah-VOR', blankWord: 'individual'),
  Phrase(id: 'lodging_4', categoryId: 'lodging', english: 'A double room, please', target: 'Una habitación doble, por favor', pronunciation: 'OO-nah ah-bee-tah-see-OHN DOH-bleh por fah-VOR', blankWord: 'doble'),
  Phrase(id: 'lodging_5', categoryId: 'lodging', english: 'How much is it per night?', target: '¿Cuánto cuesta por noche?', pronunciation: 'KWAHN-toh KWEHS-tah por NOH-cheh', blankWord: 'noche'),
  Phrase(id: 'lodging_6', categoryId: 'lodging', english: 'Is breakfast included?', target: '¿Incluye el desayuno?', pronunciation: 'een-KLOO-yeh el deh-sah-YOO-noh', blankWord: 'desayuno'),
  Phrase(id: 'lodging_7', categoryId: 'lodging', english: 'What is the wifi password?', target: '¿Cuál es la contraseña del wifi?', pronunciation: 'kwahl ehs lah kohn-trah-SEH-nyah del WEE-fee', blankWord: 'contraseña'),
  Phrase(id: 'lodging_8', categoryId: 'lodging', english: 'What time is check-out?', target: '¿A qué hora es la salida?', pronunciation: 'ah keh OH-rah ehs lah sah-LEE-dah', blankWord: 'salida'),
  Phrase(id: 'lodging_9', categoryId: 'lodging', english: 'Can I leave my luggage here?', target: '¿Puedo dejar mi equipaje aquí?', pronunciation: 'PWEH-doh deh-HAR mee eh-kee-PAH-heh ah-KEE', blankWord: 'dejar'),
  Phrase(id: 'lodging_10', categoryId: 'lodging', english: "The air conditioning doesn't work", target: 'El aire acondicionado no funciona', pronunciation: 'el EYE-reh ah-kohn-dee-see-oh-NAH-doh noh foon-see-OH-nah', blankWord: 'funciona'),
  Phrase(id: 'lodging_11', categoryId: 'lodging', english: 'I need more towels', target: 'Necesito más toallas', pronunciation: 'neh-seh-SEE-toh mahs toh-AH-yahs', blankWord: 'toallas'),
  Phrase(id: 'lodging_12', categoryId: 'lodging', english: 'I lost my room key', target: 'Perdí la llave de mi habitación', pronunciation: 'pehr-DEE lah YAH-veh deh mee ah-bee-tah-see-OHN', blankWord: 'llave'),
  Phrase(id: 'lodging_13', categoryId: 'lodging', english: 'Can I get a late check-out?', target: '¿Puedo salir más tarde?', pronunciation: 'PWEH-doh sah-LEER mahs TAR-deh', blankWord: 'tarde'),
  Phrase(id: 'lodging_14', categoryId: 'lodging', english: 'Could you call me a taxi?', target: '¿Me puede llamar un taxi?', pronunciation: 'meh PWEH-deh yah-MAR oon TAHK-see', blankWord: 'llamar'),

  // Health
  Phrase(id: 'health_1', categoryId: 'health', english: 'I have a headache', target: 'Me duele la cabeza', pronunciation: 'meh DWEH-leh lah kah-BEH-sah', blankWord: 'cabeza'),
  Phrase(id: 'health_2', categoryId: 'health', english: 'I have a stomachache', target: 'Me duele el estómago', pronunciation: 'meh DWEH-leh el ehs-TOH-mah-goh', blankWord: 'estómago'),
  Phrase(id: 'health_3', categoryId: 'health', english: 'I have a sore throat', target: 'Me duele la garganta', pronunciation: 'meh DWEH-leh lah gar-GAHN-tah', blankWord: 'garganta'),
  Phrase(id: 'health_4', categoryId: 'health', english: 'I have a cough', target: 'Tengo tos', pronunciation: 'TEHN-goh tohs', blankWord: 'tos'),
  Phrase(id: 'health_5', categoryId: 'health', english: 'I feel dizzy', target: 'Me siento mareado', pronunciation: 'meh see-EHN-toh mah-reh-AH-doh', blankWord: 'mareado'),
  Phrase(id: 'health_6', categoryId: 'health', english: 'I need to see a doctor', target: 'Necesito ver a un doctor', pronunciation: 'neh-seh-SEE-toh vehr ah oon dohk-TOR', blankWord: 'doctor'),
  Phrase(id: 'health_7', categoryId: 'health', english: 'I need an appointment', target: 'Necesito una cita', pronunciation: 'neh-seh-SEE-toh OO-nah SEE-tah', blankWord: 'cita'),
  Phrase(id: 'health_8', categoryId: 'health', english: "I'm allergic to penicillin", target: 'Soy alérgico a la penicilina', pronunciation: 'soy ah-LEHR-hee-koh ah lah peh-nee-see-LEE-nah', blankWord: 'penicilina'),
  Phrase(id: 'health_9', categoryId: 'health', english: 'I take this medication', target: 'Tomo este medicamento', pronunciation: 'TOH-moh EHS-teh meh-dee-kah-MEHN-toh', blankWord: 'medicamento'),
  Phrase(id: 'health_10', categoryId: 'health', english: 'I have asthma', target: 'Tengo asma', pronunciation: 'TEHN-goh AHS-mah', blankWord: 'asma'),
  Phrase(id: 'health_11', categoryId: 'health', english: 'I have diabetes', target: 'Tengo diabetes', pronunciation: 'TEHN-goh dee-ah-BEH-tehs', blankWord: 'diabetes'),
  Phrase(id: 'health_12', categoryId: 'health', english: 'Do you have something for a cold?', target: '¿Tiene algo para el resfriado?', pronunciation: 'tee-EH-neh AHL-goh PAH-rah el rehs-free-AH-doh', blankWord: 'resfriado'),
  Phrase(id: 'health_13', categoryId: 'health', english: 'I need a prescription', target: 'Necesito una receta', pronunciation: 'neh-seh-SEE-toh OO-nah reh-SEH-tah', blankWord: 'receta'),
  Phrase(id: 'health_14', categoryId: 'health', english: 'I have travel insurance', target: 'Tengo seguro de viaje', pronunciation: 'TEHN-goh seh-GOO-roh deh vee-AH-heh', blankWord: 'seguro'),
  Phrase(id: 'health_15', categoryId: 'health', english: 'I need sunscreen', target: 'Necesito protector solar', pronunciation: 'neh-seh-SEE-toh proh-tehk-TOR soh-LAR', blankWord: 'protector', environments: ['Coastal', 'Mountain']),
  Phrase(id: 'health_16', categoryId: 'health', english: 'I feel sick from the altitude', target: 'Me siento mal por la altura', pronunciation: 'meh see-EHN-toh mahl por lah ahl-TOO-rah', blankWord: 'altura', environments: ['Mountain']),
  Phrase(id: 'health_17', categoryId: 'health', english: 'Is the water safe to drink?', target: '¿Se puede beber el agua?', pronunciation: 'seh PWEH-deh beh-BEHR el AH-gwah', blankWord: 'beber', environments: ['Rural', 'Mountain']),
];

Category categoryById(String id) => categories.firstWhere((c) => c.id == id);

/// Everything a user in [place] should see: phrases for the whole language and
/// any setting, plus those specific to their country and settings.
List<Phrase> phrasesForPlace(Place place) =>
    allPhrases.where((p) => p.appliesTo(place)).toList();

List<Phrase> phrasesForCategory(String categoryId, Place place) =>
    phrasesForPlace(place).where((p) => p.categoryId == categoryId).toList();

/// Looks up a phrase by id, or null if it no longer exists — used to resolve
/// ids saved earlier (recently-viewed history) that shouldn't crash the app
/// if the underlying phrase data ever changes.
Phrase? phraseById(String id) {
  for (final p in allPhrases) {
    if (p.id == id) return p;
  }
  return null;
}
