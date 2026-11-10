# 1.0.8 — lokalna lista kontroli

Status: **w weryfikacji**. Poniższe kontrole w kliencie Octo pozostają do wykonania.
Niczego nie publikujemy.
Weapon skill → crit pozostaje w dotychczasowym modelu; jego weryfikację odłożono.

1. **Zakładki:** obok Item Database jest Enchant Database. Nagłówek nie zasłania
   CLASS/RACE/BUILD ani LEVEL. Przejścia Planner → Enchants → Items → Talents
   pokazują jedną stronę; zamknięcie i ponowne otwarcie nie powoduje błędów Lua.
2. **Baza enchantów:** działa bez ekwipunku. Sprawdź wyszukiwanie, slot,
   Armor & Defense, Show lower ranks oraz Previous/Next/kółko myszy. Kliknięcie
   enchantu pokazuje zgodne wyposażone sloty; puste lub niezgodne są wyszarzone.
   Wybranie zgodnego slotu nakłada enchant i wraca do Plannera. Dotychczasowy
   wybór enchantu przy konkretnym przedmiocie nadal działa.
3. **Dostępność:** faza 2 i Unverified wyłączone ukrywają enchanty Sapphirona.
   Faza 6 je otwiera. Przełączenie fazy/Unverified odświeża obie bazy i picker.
   Wybór kilku instancji pozostawia menu otwarte. Scarlet Monastery pokazuje
   znane dropy, np. Ravager; dawne filtry skrzydeł przechodzą na wspólne SM.
4. **Paladyn:** porównaj 0/5 i 5/5 Divine Strength bez innych zmian. STR/AP
   wzrastają; BV może zmienić się skokowo wskutek zaokrągleń. Przykład Human 60,
   Thunderfury 19019, Elementium Reinforced Bulwark 19349 i Savage Gladiator
   Chain 11726 daje 118/396/77 → 130/420/78 (STR/AP/BV), bez innych talentów.
5. **Paladyn i wojownik:** sprawdź pasywny Block oraz podgląd Holy Shield /
   Redoubt / Shield Block. Defense nadal zwiększa właściwe kategorie obrony.
   Przeciw poziomowi 63 oba gapy są równe: sheet do 102,4% dla pełnych czterech
   kategorii oraz tabela przeciw atakującemu do 100%. Nałożenie Sigila Resilience
   obniża szansę otrzymania krytyka o 3 punkty, o ile wynik nie został już
   wypchnięty przez coverage; sam Sigil nie zwiększa coverage.
6. **Zapisy/import:** na niezapisanym planie otwórz Import. Anulowanie pytania
   zachowuje plan; zatwierdzenie wczytuje kod i zamyka okno. Uszkodzony kod
   zostawia plan bez zmian. Eksport/import zachowuje ekwipunek i enchanty.
   Brakujący rekord ma etykietę Unknown item/enchant oraz ostrzeżenie.
7. **Druga postać:** nowy alt tej samej klasy zaczyna od własnego planu.
   Powrót do pierwszej postaci zachowuje jej wyposażenie i powiązanie z zapisem.
   Istniejących planów nie kasujemy w ramach migracji.
8. **Wojownik/symulator:** uruchom dotychczasowy build. Niezgodny enchant nie
   powinien dodawać obrażeń ani proców. W porównaniu identycznych zwykłych
   trafień bossa aktywne Death Wish zwiększa obrażenia fizyczne otrzymywane
   wskutek kary pancerza; po wygaśnięciu kara znika.

Zachowania obliczeń sprawdzono lokalnie względem opisów zapisanych w danych
dodatku. Zgodność ograniczeń rasowych i wszystkich wartości z bieżącym Octo
wymaga porównania w grze; potwierdzone wyjątki można wpisać osobno.
