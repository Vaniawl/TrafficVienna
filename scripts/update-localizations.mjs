import fs from "node:fs";

const path = new URL("../TrafficVienna/Localizable.xcstrings", import.meta.url);
const catalog = JSON.parse(fs.readFileSync(path, "utf8"));
const original = JSON.stringify(catalog);

const newEnglish = [
  "Remove from recent", "Clear recent searches?", "Clear all", "This removes all recent stations from this device.",
  "Share departure", "Live departure: %@ to %@", "%@ to %@ is departing now from %@. — Traffic Vienna", "%@ to %@ departs from %@ in %lld min. — Traffic Vienna",
  "Privacy & data", "Your account", "Identity", "Email password verifiers stay in Keychain on this device. Sign in with Apple uses Apple’s system authentication service. Traffic Vienna has no account server.", "Email accounts and preferences do not sync between devices.", "Location", "Used only when needed", "Location access is optional and helps find nearby stops. Traffic Vienna does not save your coordinates or send them with transit requests.", "On this device", "Travel preferences", "Favourites, recent searches, routines, appearance, and widget state are stored locally in the app or its shared widget container.", "Network requests", "Wiener Linien live data", "Traffic Vienna requests departures and service alerts over HTTPS using public stop identifiers. Wiener Linien can observe the request’s source IP address.", "No advertising or tracking", "Traffic Vienna contains no ads, analytics, or tracking SDKs.",
  "Drag modules in Edit mode to choose their order. Hidden modules keep their data.", "Home modules", "Home screen", "Live departures for your favourite lines", "Quick access to your favourite stops", "Relevant alerts, routines, and updates", "Restore default layout", "Smart insight",
  "%@ leaves soon", "%@ → %@ in about %lld min.", "Account", "Active days", "Add a favourite station first, then create a daily routine.", "Add a favourite station first, then create a routine.", "Add routine", "Amber", "Appearance", "Cancel", "Cancel all", "Cancel all reminders", "Cancel all reminders?", "Choose how Traffic Vienna looks on this device.", "Couldn’t start Lock Screen tracking. Please try again.", "Dark", "Dashboard", "Departure reminder", "Departure reminders", "Display name", "Edit", "Edit display name", "Edit routine", "End", "End all", "End all activities", "End all Live Activities?", "Every day", "Forest", "Indigo", "Keep activities", "Keep reminders", "Light", "Live Activities", "Live Activities are turned off. Enable them in Settings to track departures on your Lock Screen.", "Lock Screen tracking", "Monochrome", "Night", "No departure reminders", "No Live Activities", "Not selected", "Ocean", "Rose", "Save", "Select at least one day", "Selected", "Set a reminder from any live departure to see it here.", "System", "This removes every Traffic Vienna departure from your Lock Screen.", "Track a live departure to see it on your Lock Screen.", "Tracking %@ on your Lock Screen.", "Twilight", "Updated %@ on your Lock Screen.", "Vienna", "Weekdays", "Weekends",
  "Remove account", "Remove account from device", "Couldn’t remove account",
  "Clear data", "Clear travel data",
  "This removes favourites, routines, recent searches, departure reminders, Live Activities, widget data, and cached departures. Your sign-in stays active.",
  "This removes every pending departure reminder from this device.",
  "This deletes the local email password verifier and signs you out. Your saved stations and routines remain on this device.",
  "This removes the Apple sign-in session from this device. It does not delete or revoke your Apple ID. Your saved stations and routines remain.",
  "Allow location once and turn every nearby stop into a live departure board.",
  "Affects your favourites", "Authentication mode", "Choose", "Create account", "Discover",
  "Email", "Email account", "Email accounts are stored securely on this device. Apple ID uses Apple's private authentication flow.",
  "Changes whether the password is visible on screen", "Collapsed", "CONNECTING", "departing now", "Double-tap to show or hide the full description",
  "Connecting your position to Vienna’s transport network.", "Enable it in Settings to see nearby stops and real-time departures.",
  "Enable location", "Everything around you, live.", "Expanded", "Finding nearby departures.", "Find your station", "Good afternoon", "Good evening", "Good morning", "Hide password",
  "Line %@ towards %@", "No departure time available", "next departure in %lld minutes",
  "Live changes across Vienna", "Live city departures", "Live departures", "Live departures within 500 metres", "Location is turned off.",
  "Live station", "Locate", "Nearby now", "Network", "No matching stops", "No routines", "No stops within 500 m.", "Open in Maps",
  "Enable notifications in Settings to receive departure reminders.", "No connection. Check your internet and try again.", "No connection. Showing the most recently saved data.", "Password", "Preparing Vienna…", "Real-time departures and service updates", "Refresh", "Remind me before departure", "Routines", "This departure is too soon for a reminder.",
  "Remind", "Saved data", "Saved data, %@", "Saved routes", "Saved stations", "See all", "Service is busy right now. Please try again in a moment.", "Showing saved data", "Show password", "Track", "We’ll notify you shortly before %@ departs.",
  "Schedule only", "Search every station across Vienna", "Sign in", "Sign out", "Start typing to see live departures anywhere in Vienna.",
  "Station or stop", "The departures you care about", "Traffic Vienna user", "Travel routines", "Try again from another location or open the map to explore the city.", "Try another station name.",
  "NO RESULTS", "OFFLINE", "SET UP", "Uses your Apple ID to create or open your account", "VIENNA LIVE", "Where to next?", "Your city", "Your city, moving with you", "Your routines", "or",
  "%@, followed by %@ minutes", "Updates this line in your favourites"
];

const de = {
  "Remove from recent":"Aus Verlauf entfernen", "Clear recent searches?":"Letzte Suchanfragen löschen?", "Clear all":"Alle löschen", "This removes all recent stations from this device.":"Dadurch werden alle zuletzt verwendeten Stationen von diesem Gerät entfernt.",
  "Share departure":"Abfahrt teilen", "Live departure: %@ to %@":"Live-Abfahrt: %@ nach %@", "%@ to %@ is departing now from %@. — Traffic Vienna":"%@ nach %@ fährt jetzt von %@ ab. — Traffic Vienna", "%@ to %@ departs from %@ in %lld min. — Traffic Vienna":"%@ nach %@ fährt von %@ in %lld Min. ab. — Traffic Vienna",
  "Privacy & data":"Datenschutz & Daten", "Your account":"Dein Konto", "Identity":"Identität", "Email password verifiers stay in Keychain on this device. Sign in with Apple uses Apple’s system authentication service. Traffic Vienna has no account server.":"E-Mail-Passwortprüfwerte bleiben im Schlüsselbund auf diesem Gerät. Mit Apple anmelden nutzt Apples Systemdienst zur Authentifizierung. Traffic Vienna betreibt keinen Kontoserver.", "Email accounts and preferences do not sync between devices.":"E-Mail-Konten und Einstellungen werden nicht zwischen Geräten synchronisiert.", "Location":"Standort", "Used only when needed":"Nur bei Bedarf verwendet", "Location access is optional and helps find nearby stops. Traffic Vienna does not save your coordinates or send them with transit requests.":"Der Standortzugriff ist optional und hilft, Haltestellen in der Nähe zu finden. Traffic Vienna speichert deine Koordinaten nicht und sendet sie nicht mit Verkehrsanfragen.", "On this device":"Auf diesem Gerät", "Travel preferences":"Reiseeinstellungen", "Favourites, recent searches, routines, appearance, and widget state are stored locally in the app or its shared widget container.":"Favoriten, letzte Suchanfragen, Routinen, Erscheinungsbild und Widget-Status werden lokal in der App oder ihrem gemeinsamen Widget-Container gespeichert.", "Network requests":"Netzwerkanfragen", "Wiener Linien live data":"Live-Daten der Wiener Linien", "Traffic Vienna requests departures and service alerts over HTTPS using public stop identifiers. Wiener Linien can observe the request’s source IP address.":"Traffic Vienna ruft Abfahrten und Verkehrsmeldungen per HTTPS mit öffentlichen Haltestellenkennungen ab. Die Wiener Linien können die Quell-IP-Adresse der Anfrage sehen.", "No advertising or tracking":"Keine Werbung oder Nachverfolgung", "Traffic Vienna contains no ads, analytics, or tracking SDKs.":"Traffic Vienna enthält keine Werbung, Analysen oder Tracking-SDKs.",
  "Drag modules in Edit mode to choose their order. Hidden modules keep their data.":"Ziehe Module im Bearbeitungsmodus in die gewünschte Reihenfolge. Ausgeblendete Module behalten ihre Daten.",
  "Home modules":"Startseitenmodule", "Home screen":"Startseite", "Live departures for your favourite lines":"Live-Abfahrten deiner Lieblingslinien", "Quick access to your favourite stops":"Schnellzugriff auf deine Lieblingshaltestellen", "Relevant alerts, routines, and updates":"Relevante Meldungen, Routinen und Aktualisierungen", "Restore default layout":"Standardlayout wiederherstellen", "Smart insight":"Smarte Übersicht",
  "CONNECTING":"VERBINDUNG", "NO RESULTS":"KEINE ERGEBNISSE", "OFFLINE":"OFFLINE", "SET UP":"EINRICHTEN",
  "Amber":"Bernstein", "Appearance":"Erscheinungsbild", "Choose how Traffic Vienna looks on this device.":"Wähle, wie Traffic Vienna auf diesem Gerät aussieht.", "Dark":"Dunkel", "Dashboard":"Dashboard", "Forest":"Wald", "Indigo":"Indigo", "Light":"Hell", "Monochrome":"Monochrom", "Night":"Nacht", "Ocean":"Ozean", "Rose":"Rosa", "System":"System", "Twilight":"Dämmerung", "Vienna":"Wien",
  "Changes whether the password is visible on screen":"Legt fest, ob das Passwort auf dem Bildschirm sichtbar ist", "Collapsed":"Eingeklappt",
  "Allow location once and turn every nearby stop into a live departure board.":"Erlaube einmalig den Standortzugriff und verwandle jede Haltestelle in der Nähe in eine Live-Abfahrtstafel.",
  "Connecting your position to Vienna’s transport network.":"Dein Standort wird mit dem Wiener Verkehrsnetz verbunden.",
  "Enable it in Settings to see nearby stops and real-time departures.":"Aktiviere den Standort in den Einstellungen, um Haltestellen und Echtzeit-Abfahrten in deiner Nähe zu sehen.",
  "departing now":"fährt jetzt ab", "Double-tap to show or hide the full description":"Doppeltippen, um die vollständige Beschreibung ein- oder auszublenden",
  "Expanded":"Ausgeklappt", "Hide password":"Passwort ausblenden", "Line %@ towards %@":"Linie %@ Richtung %@",
  "Finding nearby departures.":"Abfahrten in der Nähe werden gesucht.", "Location is turned off.":"Der Standort ist deaktiviert.", "No stops within 500 m.":"Keine Haltestellen im Umkreis von 500 m.",
  "No departure time available":"Keine Abfahrtszeit verfügbar", "next departure in %lld minutes":"nächste Abfahrt in %lld Minuten",
  "No connection. Check your internet and try again.":"Keine Verbindung. Prüfe deine Internetverbindung und versuche es erneut.",
  "No connection. Showing the most recently saved data.":"Keine Verbindung. Die zuletzt gespeicherten Daten werden angezeigt.",
  "Saved data":"Gespeicherte Daten", "Saved data, %@":"Gespeicherte Daten, %@", "Saved routes":"Gespeicherte Verbindungen", "Saved stations":"Gespeicherte Stationen", "See all":"Alle anzeigen", "Service is busy right now. Please try again in a moment.":"Der Dienst ist gerade ausgelastet. Versuche es gleich noch einmal.", "Showing saved data":"Gespeicherte Daten werden angezeigt",
  "Show password":"Passwort anzeigen", "Uses your Apple ID to create or open your account":"Verwendet deine Apple-ID, um dein Konto zu erstellen oder zu öffnen",
  "Try again from another location or open the map to explore the city.":"Versuche es an einem anderen Ort erneut oder öffne die Karte, um die Stadt zu erkunden.",
  "%@, followed by %@ minutes":"%@, danach in %@ Minuten", "Updates this line in your favourites":"Aktualisiert diese Linie in deinen Favoriten",
  "%@ leaves soon":"%@ fährt bald ab", "%@ → %@ in about %lld min.":"%@ → %@ in etwa %lld Min.", "%lld":"%lld", "—":"—",
  "Account":"Konto", "Add a favourite station first, then create a daily routine.":"Füge zuerst eine Lieblingsstation hinzu und erstelle dann eine tägliche Routine.",
  "Active days":"Aktive Tage", "Add a favourite station first, then create a routine.":"Füge zuerst eine Lieblingsstation hinzu und erstelle dann eine Routine.", "Every day":"Jeden Tag", "Not selected":"Nicht ausgewählt", "Select at least one day":"Wähle mindestens einen Tag aus", "Selected":"Ausgewählt", "Weekdays":"Werktags", "Weekends":"Am Wochenende",
  "Couldn’t start Lock Screen tracking. Please try again.":"Das Tracking auf dem Sperrbildschirm konnte nicht gestartet werden. Versuche es erneut.", "Departure reminder":"Abfahrtserinnerung", "Live Activities are turned off. Enable them in Settings to track departures on your Lock Screen.":"Live-Aktivitäten sind deaktiviert. Aktiviere sie in den Einstellungen, um Abfahrten auf deinem Sperrbildschirm zu verfolgen.", "Lock Screen tracking":"Sperrbildschirm-Tracking", "Tracking %@ on your Lock Screen.":"%@ wird auf deinem Sperrbildschirm verfolgt.", "Updated %@ on your Lock Screen.":"%@ wurde auf deinem Sperrbildschirm aktualisiert.",
  "End":"Beenden", "End all":"Alle beenden", "End all activities":"Alle Aktivitäten beenden", "End all Live Activities?":"Alle Live-Aktivitäten beenden?", "Keep activities":"Aktivitäten behalten", "Live Activities":"Live-Aktivitäten", "No Live Activities":"Keine Live-Aktivitäten", "This removes every Traffic Vienna departure from your Lock Screen.":"Dadurch werden alle Traffic-Vienna-Abfahrten von deinem Sperrbildschirm entfernt.", "Track a live departure to see it on your Lock Screen.":"Verfolge eine Live-Abfahrt, um sie auf deinem Sperrbildschirm zu sehen.",
  "Add routine":"Routine hinzufügen", "Affects your favourites":"Betrifft deine Favoriten", "All clear":"Alles frei", "Cancel":"Abbrechen", "Edit":"Bearbeiten", "Edit routine":"Routine bearbeiten", "Save":"Sichern",
  "Cancel all":"Alle löschen", "Cancel all reminders":"Alle Erinnerungen löschen", "Cancel all reminders?":"Alle Erinnerungen löschen?", "Departure reminders":"Abfahrtserinnerungen", "Keep reminders":"Erinnerungen behalten", "No departure reminders":"Keine Abfahrtserinnerungen", "Set a reminder from any live departure to see it here.":"Lege bei einer Live-Abfahrt eine Erinnerung fest, um sie hier zu sehen.",
  "Display name":"Anzeigename", "Edit display name":"Anzeigenamen bearbeiten",
  "Enable notifications in Settings to receive departure reminders.":"Aktiviere Mitteilungen in den Einstellungen, um Abfahrtserinnerungen zu erhalten.",
  "Remove account":"Konto entfernen", "Remove account from device":"Konto von diesem Gerät entfernen", "Couldn’t remove account":"Konto konnte nicht entfernt werden",
  "Clear data":"Daten löschen", "Clear travel data":"Reisedaten löschen",
  "This removes favourites, routines, recent searches, departure reminders, Live Activities, widget data, and cached departures. Your sign-in stays active.":"Dadurch werden Favoriten, Routinen, letzte Suchanfragen, Abfahrtserinnerungen, Live-Aktivitäten, Widget-Daten und zwischengespeicherte Abfahrten gelöscht. Deine Anmeldung bleibt aktiv.",
  "This removes every pending departure reminder from this device.":"Dadurch werden alle ausstehenden Abfahrtserinnerungen von diesem Gerät entfernt.",
  "This deletes the local email password verifier and signs you out. Your saved stations and routines remain on this device.":"Dadurch werden der lokale E-Mail-Passwortprüfwert gelöscht und du abgemeldet. Deine gespeicherten Stationen und Routinen bleiben auf diesem Gerät.",
  "This removes the Apple sign-in session from this device. It does not delete or revoke your Apple ID. Your saved stations and routines remain.":"Dadurch wird die Apple-Anmeldesitzung von diesem Gerät entfernt. Deine Apple-ID wird weder gelöscht noch widerrufen. Deine gespeicherten Stationen und Routinen bleiben erhalten.",
  "Authentication mode":"Anmeldemodus", "Change theme":"Design ändern", "Choose":"Auswählen", "Couldn't load departures":"Abfahrten konnten nicht geladen werden",
  "Create account":"Konto erstellen", "Discover":"Entdecken", "Email":"E-Mail", "Email account":"E-Mail-Konto",
  "Email accounts are stored securely on this device. Apple ID uses Apple's private authentication flow.":"E-Mail-Konten werden sicher auf diesem Gerät gespeichert. Die Apple-ID nutzt Apples privaten Anmeldevorgang.",
  "Enable location":"Standort aktivieren", "Error":"Fehler", "Everything around you, live.":"Alles um dich herum – live.",
  "Filter":"Filtern", "Find your station":"Finde deine Station", "Good afternoon":"Guten Tag", "Good evening":"Guten Abend", "Good morning":"Guten Morgen",
  "Live changes across Vienna":"Aktuelle Änderungen in ganz Wien", "Live city departures":"Live-Abfahrten in der Stadt", "Live departures":"Live-Abfahrten",
  "Live departures, wherever you are.":"Live-Abfahrten, egal wo du bist.",
  "Live departures within 500 metres":"Live-Abfahrten im Umkreis von 500 Metern", "Live station":"Live-Station", "Locate":"Standort",
  "Loading...":"Wird geladen…", "Nearby now":"Jetzt in der Nähe", "Network":"Netz", "No matching stops":"Keine passenden Haltestellen",
  "No routines":"Keine Routinen", "Offline":"Offline", "Open in Maps":"In Karten öffnen", "Password":"Passwort", "Preparing Vienna…":"Wien wird vorbereitet…",
  "Real-time departures and service updates":"Echtzeit-Abfahrten und Verkehrsmeldungen", "Refresh":"Aktualisieren", "Remind me before departure":"Vor der Abfahrt erinnern",
  "Remind":"Erinnern", "Track":"Verfolgen",
  "This departure is too soon for a reminder.":"Diese Abfahrt ist zu kurzfristig für eine Erinnerung.",
  "We’ll notify you shortly before %@ departs.":"Wir benachrichtigen dich kurz bevor %@ abfährt.",
  "Retry":"Erneut versuchen", "Routines":"Routinen", "Schedule only":"Nur Fahrplan", "Search every station across Vienna":"Alle Stationen in Wien durchsuchen",
  "Sign in":"Anmelden", "Sign out":"Abmelden", "Start typing to see live departures anywhere in Vienna.":"Tippe, um Live-Abfahrten in ganz Wien zu sehen.",
  "Station or stop":"Station oder Haltestelle", "The departures you care about":"Die Abfahrten, die dir wichtig sind", "Traffic Vienna user":"Traffic-Vienna-Nutzer",
  "Showing Vienna centre — enable location to see stops near you.":"Wien Zentrum wird angezeigt – aktiviere den Standort für Haltestellen in deiner Nähe.",
  "Travel routines":"Fahrtroutinen", "Try another station name.":"Versuche einen anderen Stationsnamen.", "VIENNA LIVE":"WIEN LIVE",
  "Where to next?":"Wohin als Nächstes?", "Your city":"Deine Stadt", "Your city, moving with you":"Deine Stadt bewegt sich mit dir",
  "Your routines":"Deine Routinen", "or":"oder"
};

const uk = {
  "Remove from recent":"Видалити з недавніх", "Clear recent searches?":"Очистити недавні пошуки?", "Clear all":"Очистити все", "This removes all recent stations from this device.":"Це видалить усі недавні станції з цього пристрою.",
  "Share departure":"Поділитися відправленням", "Live departure: %@ to %@":"Актуальне відправлення: %@ до %@", "%@ to %@ is departing now from %@. — Traffic Vienna":"%@ до %@ відправляється зараз зі станції %@. — Traffic Vienna", "%@ to %@ departs from %@ in %lld min. — Traffic Vienna":"%@ до %@ відправляється зі станції %@ через %lld хв. — Traffic Vienna",
  "Privacy & data":"Приватність і дані", "Your account":"Ваш акаунт", "Identity":"Ідентифікація", "Email password verifiers stay in Keychain on this device. Sign in with Apple uses Apple’s system authentication service. Traffic Vienna has no account server.":"Засіб перевірки пароля електронної пошти зберігається у Keychain на цьому пристрої. Вхід з Apple використовує системну службу автентифікації Apple. Traffic Vienna не має сервера акаунтів.", "Email accounts and preferences do not sync between devices.":"Акаунти електронної пошти й налаштування не синхронізуються між пристроями.", "Location":"Геолокація", "Used only when needed":"Використовується лише за потреби", "Location access is optional and helps find nearby stops. Traffic Vienna does not save your coordinates or send them with transit requests.":"Доступ до геолокації необов’язковий і допомагає знаходити зупинки поруч. Traffic Vienna не зберігає ваші координати й не надсилає їх у запитах до транспортного сервісу.", "On this device":"На цьому пристрої", "Travel preferences":"Налаштування поїздок", "Favourites, recent searches, routines, appearance, and widget state are stored locally in the app or its shared widget container.":"Обране, недавні пошуки, сценарії, вигляд і стан віджета зберігаються локально в застосунку або спільному контейнері віджета.", "Network requests":"Мережеві запити", "Wiener Linien live data":"Актуальні дані Wiener Linien", "Traffic Vienna requests departures and service alerts over HTTPS using public stop identifiers. Wiener Linien can observe the request’s source IP address.":"Traffic Vienna запитує відправлення та зміни руху через HTTPS, використовуючи публічні ідентифікатори зупинок. Wiener Linien може бачити IP-адресу джерела запиту.", "No advertising or tracking":"Без реклами та відстеження", "Traffic Vienna contains no ads, analytics, or tracking SDKs.":"Traffic Vienna не містить реклами, аналітики чи SDK для відстеження.",
  "Drag modules in Edit mode to choose their order. Hidden modules keep their data.":"Перетягуйте модулі в режимі редагування, щоб змінити їх порядок. Приховані модулі зберігають дані.",
  "Home modules":"Модулі головного екрана", "Home screen":"Головний екран", "Live departures for your favourite lines":"Актуальні відправлення обраних ліній", "Quick access to your favourite stops":"Швидкий доступ до улюблених зупинок", "Relevant alerts, routines, and updates":"Актуальні зміни руху, сценарії та оновлення", "Restore default layout":"Відновити типовий вигляд", "Smart insight":"Розумна підказка",
  "CONNECTING":"ПІДКЛЮЧЕННЯ", "NO RESULTS":"НЕМАЄ РЕЗУЛЬТАТІВ", "OFFLINE":"ОФЛАЙН", "SET UP":"НАЛАШТУВАТИ",
  "Amber":"Бурштинова", "Appearance":"Вигляд", "Choose how Traffic Vienna looks on this device.":"Виберіть вигляд Traffic Vienna на цьому пристрої.", "Dark":"Темна", "Dashboard":"Панель", "Forest":"Ліс", "Indigo":"Індиго", "Light":"Світла", "Monochrome":"Монохромна", "Night":"Нічна", "Ocean":"Океан", "Rose":"Рожева", "System":"Системна", "Twilight":"Сутінки", "Vienna":"Відень",
  "Changes whether the password is visible on screen":"Змінює видимість пароля на екрані", "Collapsed":"Згорнуто",
  "Allow location once and turn every nearby stop into a live departure board.":"Надайте доступ до геолокації один раз і перетворіть кожну зупинку поруч на табло актуальних відправлень.",
  "Connecting your position to Vienna’s transport network.":"Підключаємо ваше місцезнаходження до транспортної мережі Відня.",
  "Enable it in Settings to see nearby stops and real-time departures.":"Увімкніть геолокацію в Параметрах, щоб бачити зупинки поруч і відправлення в реальному часі.",
  "departing now":"відправляється зараз", "Double-tap to show or hide the full description":"Двічі торкніться, щоб показати або приховати повний опис",
  "Expanded":"Розгорнуто", "Hide password":"Приховати пароль", "Line %@ towards %@":"Лінія %@ у напрямку %@",
  "Finding nearby departures.":"Шукаємо найближчі відправлення.", "Location is turned off.":"Геолокацію вимкнено.", "No stops within 500 m.":"У радіусі 500 м немає зупинок.",
  "No departure time available":"Час відправлення недоступний", "next departure in %lld minutes":"наступне відправлення через %lld хв",
  "No connection. Check your internet and try again.":"Немає з’єднання. Перевірте інтернет і спробуйте ще раз.",
  "No connection. Showing the most recently saved data.":"Немає з’єднання. Показано останні збережені дані.",
  "Saved data":"Збережені дані", "Saved data, %@":"Збережені дані, %@", "Saved routes":"Збережені маршрути", "Saved stations":"Збережені станції", "See all":"Переглянути всі", "Service is busy right now. Please try again in a moment.":"Сервіс зараз перевантажений. Спробуйте ще раз за мить.", "Showing saved data":"Показано збережені дані",
  "Show password":"Показати пароль", "Uses your Apple ID to create or open your account":"Використовує Apple ID для створення або відкриття облікового запису",
  "Try again from another location or open the map to explore the city.":"Спробуйте ще раз в іншому місці або відкрийте мапу, щоб переглянути місто.",
  "%@, followed by %@ minutes":"%@, далі через %@ хв", "Updates this line in your favourites":"Оновлює цю лінію в обраному",
  "%@ leaves soon":"%@ скоро відправляється", "%@ → %@ in about %lld min.":"%@ → %@ приблизно через %lld хв.", "%lld":"%lld", "—":"—", "About":"Про застосунок", "Account":"Обліковий запис", "Add station to favourites":"Додати станцію до обраного",
  "Active days":"Активні дні", "Add a favourite station first, then create a routine.":"Спочатку додайте улюблену станцію, а потім створіть сценарій.", "Every day":"Щодня", "Not selected":"Не вибрано", "Select at least one day":"Виберіть принаймні один день", "Selected":"Вибрано", "Weekdays":"Будні", "Weekends":"Вихідні",
  "Couldn’t start Lock Screen tracking. Please try again.":"Не вдалося запустити відстеження на екрані блокування. Спробуйте ще раз.", "Departure reminder":"Нагадування про відправлення", "Live Activities are turned off. Enable them in Settings to track departures on your Lock Screen.":"Live Activities вимкнено. Увімкніть їх у Параметрах, щоб відстежувати відправлення на екрані блокування.", "Lock Screen tracking":"Відстеження на екрані блокування", "Tracking %@ on your Lock Screen.":"%@ відстежується на екрані блокування.", "Updated %@ on your Lock Screen.":"%@ оновлено на екрані блокування.",
  "End":"Завершити", "End all":"Завершити всі", "End all activities":"Завершити всі дії", "End all Live Activities?":"Завершити всі дії наживо?", "Keep activities":"Залишити дії", "Live Activities":"Дії наживо", "No Live Activities":"Немає дій наживо", "This removes every Traffic Vienna departure from your Lock Screen.":"Це прибере всі відправлення Traffic Vienna з екрана блокування.", "Track a live departure to see it on your Lock Screen.":"Почніть відстежувати відправлення наживо, щоб бачити його на екрані блокування.",
  "Add to favourites":"Додати до обраного", "Add a favourite station first, then create a daily routine.":"Спочатку додайте улюблену станцію, а потім створіть щоденний сценарій.",
  "Add routine":"Додати сценарій", "Affects your favourites":"Впливає на обрані маршрути", "Alerts":"Сповіщення", "All":"Усі", "All clear":"Усе гаразд", "Cancel":"Скасувати", "Edit":"Редагувати", "Edit routine":"Редагувати сценарій", "Save":"Зберегти",
  "Cancel all":"Скасувати всі", "Cancel all reminders":"Скасувати всі нагадування", "Cancel all reminders?":"Скасувати всі нагадування?", "Departure reminders":"Нагадування про відправлення", "Keep reminders":"Залишити нагадування", "No departure reminders":"Немає нагадувань про відправлення", "Set a reminder from any live departure to see it here.":"Установіть нагадування для будь-якого актуального відправлення, щоб побачити його тут.",
  "Display name":"Ім’я профілю", "Edit display name":"Редагувати ім’я профілю",
  "Enable notifications in Settings to receive departure reminders.":"Увімкніть сповіщення в Налаштуваннях, щоб отримувати нагадування про відправлення.",
  "Remove account":"Видалити акаунт", "Remove account from device":"Видалити акаунт із пристрою", "Couldn’t remove account":"Не вдалося видалити акаунт",
  "Clear data":"Очистити дані", "Clear travel data":"Очистити дані поїздок",
  "This removes favourites, routines, recent searches, departure reminders, Live Activities, widget data, and cached departures. Your sign-in stays active.":"Це видалить обране, сценарії, недавні пошуки, нагадування про відправлення, Live Activities, дані віджета та кешовані відправлення. Вхід в акаунт залишиться активним.",
  "This removes every pending departure reminder from this device.":"Це видалить усі заплановані нагадування про відправлення з цього пристрою.",
  "This deletes the local email password verifier and signs you out. Your saved stations and routines remain on this device.":"Це видалить локальний засіб перевірки пароля електронної пошти та виконає вихід. Збережені станції й сценарії залишаться на цьому пристрої.",
  "This removes the Apple sign-in session from this device. It does not delete or revoke your Apple ID. Your saved stations and routines remain.":"Це видалить сеанс входу Apple із цього пристрою. Ваш Apple ID не буде видалено чи відкликано. Збережені станції й сценарії залишаться.",
  "All lines are running normally.":"Усі лінії працюють нормально.", "Authentication mode":"Режим входу", "Change theme":"Змінити тему", "Choose":"Обрати",
  "Clear":"Очистити", "Couldn't load departures":"Не вдалося завантажити відправлення", "Couldn’t load departures":"Не вдалося завантажити відправлення",
  "Create account":"Створити акаунт", "Data":"Дані", "Data: Wiener Linien (Stadt Wien, CC BY).":"Дані: Wiener Linien (місто Відень, CC BY).",
  "data.gv.at":"data.gv.at", "Departure times are provided live by Wiener Linien and may differ from actual service.":"Час відправлення надається Wiener Linien у реальному часі та може відрізнятися від фактичного руху.",
  "Departures":"Відправлення", "Discover":"Відкрийте", "Done":"Готово", "Email":"Електронна пошта", "Email account":"Акаунт електронної пошти",
  "Email accounts are stored securely on this device. Apple ID uses Apple's private authentication flow.":"Акаунти електронної пошти безпечно зберігаються на цьому пристрої. Apple ID використовує приватний процес автентифікації Apple.",
  "Enable location":"Увімкнути геолокацію", "Enter a station name to see live departures.":"Введіть назву станції, щоб побачити актуальні відправлення.",
  "Enter stop name…":"Введіть назву зупинки…", "Error":"Помилка", "Everything around you, live.":"Усе навколо вас — наживо.", "Favourites":"Обране",
  "Filter":"Фільтр", "Find your station":"Знайдіть свою станцію", "Get started":"Почати", "Good afternoon":"Добрий день", "Good evening":"Добрий вечір",
  "Good morning":"Доброго ранку", "Licence":"Ліцензія", "Lines":"Лінії", "Live changes across Vienna":"Актуальні зміни по всьому Відню",
  "Live city departures":"Міські відправлення наживо", "Live departures":"Відправлення наживо", "Live departures within 500 metres":"Відправлення в межах 500 метрів",
  "Live departures, wherever you are.":"Актуальні відправлення, де б ви не були.", "Live station":"Станція наживо",
  "Live Wiener Linien departures, wherever you are.":"Актуальні відправлення Wiener Linien, де б ви не були.", "Loading...":"Завантаження…", "Loading…":"Завантаження…",
  "Locate":"Знайти мене", "Locating you…":"Визначаємо ваше місцезнаходження…", "Map":"Мапа", "min":"хв", "Nearby":"Поруч", "Nearby now":"Зараз поруч",
  "Network":"Мережа", "No departures":"Немає відправлень", "No favourites yet":"Обраного ще немає", "No matching stops":"Зупинок не знайдено",
  "No routines":"Немає сценаріїв", "Nothing scheduled right now.":"Зараз нічого не заплановано.", "now":"зараз", "Offline":"Офлайн", "Open in Maps":"Відкрити в Картах",
  "Password":"Пароль", "Preparing Vienna…":"Готуємо Відень…", "Provider":"Постачальник", "Real-time departures and service updates":"Відправлення та зміни руху в реальному часі", "Recent":"Нещодавні",
  "Refresh":"Оновити", "Refresh alerts":"Оновити сповіщення", "Refresh departures":"Оновити відправлення", "Remind me before departure":"Нагадати перед відправленням",
  "Remind":"Нагадати", "Track":"Відстежувати",
  "This departure is too soon for a reminder.":"Це відправлення вже надто близько для нагадування.",
  "We’ll notify you shortly before %@ departs.":"Ми сповістимо вас незадовго до відправлення %@.",
  "Remove":"Видалити", "Remove %@ from favourites":"Видалити %@ з обраного", "Remove favourite":"Видалити з обраного", "Remove station from favourites":"Видалити станцію з обраного",
  "Retry":"Спробувати ще", "Routines":"Сценарії", "Save %@ to favourites":"Зберегти %@ в обране", "Schedule only":"Лише розклад", "Search":"Пошук",
  "Search every station across Vienna":"Шукайте серед усіх станцій Відня", "Search for a stop":"Знайти зупинку", "Service alerts":"Зміни руху", "Show less":"Показати менше",
  "Show more":"Показати більше", "Showing Vienna centre — enable location to see stops near you.":"Показано центр Відня — увімкніть геолокацію, щоб побачити зупинки поруч.",
  "Sign in":"Увійти", "Sign out":"Вийти", "Source":"Джерело", "Star a station, or tap the heart on a line, to save it here.":"Позначте станцію зірочкою або натисніть серце біля лінії, щоб зберегти її тут.",
  "Start typing to see live departures anywhere in Vienna.":"Почніть вводити назву, щоб побачити актуальні відправлення по всьому Відню.", "Station or stop":"Станція або зупинка",
  "Stations":"Станції", "The departures you care about":"Важливі для вас відправлення", "Track on Lock Screen":"Відстежувати на екрані блокування",
  "Traffic Vienna":"Traffic Vienna", "Traffic Vienna user":"Користувач Traffic Vienna", "Travel routines":"Сценарії поїздок", "Try another station name.":"Спробуйте іншу назву станції.",
  "Version %@":"Версія %@", "VIENNA LIVE":"ВІДЕНЬ НАЖИВО", "Where to next?":"Куди далі?", "Your city":"Ваше місто", "Your city, moving with you":"Ваше місто рухається разом із вами",
  "Your routines":"Ваші сценарії", "or":"або", "updated %lldh ago":"оновлено %lld год тому", "updated %lldm ago":"оновлено %lld хв тому", "updated %llds ago":"оновлено %lld с тому",
  "updated just now":"щойно оновлено"
};

for (const key of newEnglish) catalog.strings[key] ??= {};
for (const [language, values] of Object.entries({ de, uk })) {
  for (const [key, value] of Object.entries(values)) {
    catalog.strings[key] ??= {};
    catalog.strings[key].localizations ??= {};
    catalog.strings[key].localizations[language] = { stringUnit: { state: "translated", value } };
  }
}

catalog.strings = Object.fromEntries(Object.entries(catalog.strings).sort(([a], [b]) => a.localeCompare(b)));
const incomplete = Object.entries(catalog.strings).filter(([, entry]) =>
  !entry.localizations?.de?.stringUnit?.value || !entry.localizations?.uk?.stringUnit?.value
);
if (incomplete.length) {
  console.error(`Missing de/uk localization: ${incomplete.map(([key]) => key).join(", ")}`);
  process.exit(1);
}
if (process.argv.includes("--check")) {
  if (original !== JSON.stringify(catalog)) {
    console.error("Localizable.xcstrings is stale; run node scripts/update-localizations.mjs");
    process.exit(1);
  }
} else {
  fs.writeFileSync(path, `${JSON.stringify(catalog, null, 2)}\n`);
}
