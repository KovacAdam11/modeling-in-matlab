# Modelovanie v MATLABe – spracovanie datasetu a vizualizácia (Praha, Legerova ulica)

Projekt z predmetu **Modelovanie v MATLABe**.  
Úlohou bolo spracovať dataset, pripraviť premenné (dátum, čas, intenzita, rýchlosť), spojiť ich do jednej tabuľky a pripraviť výstupy pre ďalšiu analýzu / tvorbu grafov.

---

## Čo projekt robí

Hlavný skript **main_combine.m**:

1. Načíta 4 uložené premenné zo súborov `.mat`:
   - `Datum`
   - `Cas`
   - `Intenzita`
   - `Rychlost`

2. Skontroluje dĺžky dát (musí sedieť počet riadkov pre všetky premenné).

3. Prevedie typy:
   - `Datum` → `datetime` (formát `dd.MM.yyyy`)
   - `Cas` → `duration` (formát `hh:mm:ss` alebo `hh:mm`)
   - `Intenzita`, `Rychlost` → numerické hodnoty (`str2double` ak treba)

4. Vytvorí časovú os:
   - `ts = Datum + Cas` (datetime)

5. Vytvorí tabuľku `T` a zoradí ju podľa `ts`.

6. Uloží výsledok:
   - `results/combined.mat` (tabuľka `T`)
   - `results/combined.xlsx` (pre export a ďalšie spracovanie)

---

## Vstupy

Skript hľadá vstupné súbory prioritne v priečinku:

- `./results/`

Ak priečinok `results` neexistuje, skúsi aktuálny priečinok projektu.

Očakávané súbory:

- `results/variable_Datum.mat`
- `results/variable_Cas.mat`
- `results/variable_Intenzita.mat`
- `results/variable_Rychlost.mat`

---

## Výstupy

Po úspešnom spustení vzniknú:

- `results/combined.mat` – MATLAB tabuľka `T`
- `results/combined.xlsx` – export tabuľky s dátumom/časom aj ako text, aby sa zobrazoval jednotne

Skript zároveň vypíše náhľad prvých ~10 riadkov tabuľky.

