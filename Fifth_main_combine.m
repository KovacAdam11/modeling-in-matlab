%% main_combine.m
% Spojí 4 uložené MAT premenné (Datum, Cas, Intenzita, Rychlost)
% do jednej tabuľky, zoradí podľa dátumu+času a uloží výsledok.

clear; clc;

% --- 0) Nastav aktuálny priečinok na umiestnenie tohto skriptu (portable) ---
cd(fileparts(mfilename('fullpath')));

% --- 1) Kde hľadať vstupy (najprv ./results, inak .) ----------------------
inDirCandidates = { fullfile(pwd,'results'), pwd };
inDir = '';
for c = 1:numel(inDirCandidates)
    if exist(inDirCandidates{c}, 'dir')
        inDir = inDirCandidates{c}; break;
    end
end

if isempty(inDir)
    error('Nenašiel som pracovný priečinok. Skontroluj, že spúšťaš skript z projektu.');
end

% --- Načítanie jednotlivých premenných ---
S = struct();
need = {'Datum','Cas','Intenzita','Rychlost'};
files = {'variable_Datum.mat','variable_Cas.mat','variable_Intenzita.mat','variable_Rychlost.mat'};
for k = 1:numel(need)
    f = fullfile(inDir, files{k});
    if ~exist(f,'file')
        error('Chýba súbor: %s', f);
    end
    tmp = load(f);
    if ~isfield(tmp, need{k})
        error('V súbore %s nie je premenná %s.', files{k}, need{k});
    end
    S.(need{k}) = tmp.(need{k});
end

% --- Dotypovanie / čistenie dĺžok ---
n = [];
for k = 1:numel(need)
    v = S.(need{k});
    % Premeň na stĺpcový vektor
    S.(need{k}) = v(:);
    if isempty(n), n = numel(S.(need{k})); end
    if numel(S.(need{k})) ~= n
        error('Premenná %s má inú dĺžku (%d) ako ostatné (%d).', need{k}, numel(S.(need{k})), n);
    end
end

% Datum: ak je string -> na datetime
if isstring(S.Datum) || iscellstr(S.Datum)
    S.Datum = datetime(string(S.Datum), 'InputFormat','dd.MM.yyyy');
end
% Cas: ak je string -> na duration
if isstring(S.Cas) || iscellstr(S.Cas)
    s = string(S.Cas);
    try
        S.Cas = duration(s, 'InputFormat','hh:mm:ss');
    catch
        S.Cas = duration(s, 'InputFormat','hh:mm');
    end
end
% Intenzita/Rychlost: ak nie sú numeric -> str2double
if ~isnumeric(S.Intenzita), S.Intenzita = str2double(string(S.Intenzita)); end
if ~isnumeric(S.Rychlost),  S.Rychlost  = str2double(string(S.Rychlost));  end

% --- Zloženie časovej osi a tabuľky ---
ts = S.Datum + S.Cas;               % datetime + duration
ts.Format = 'dd.MM.yyyy HH:mm:ss';

T = table(S.Datum, S.Cas, S.Intenzita, S.Rychlost, ts, ...
          'VariableNames', {'Datum','Cas','Intenzita','Rychlost','ts'});

% --- Zoradenie podľa ts + odstránenie prípadných NaT ---
T = T(~isnat(T.Datum) & ~isnat(T.ts), :);
T = sortrows(T, 'ts');

% --- Uloženie výstupov ---
outDir = inDir; % ukladáme do results/
save(fullfile(outDir, 'combined.mat'), 'T', '-v7.3');

% Pre Excel ulož dátum/čas aj v textovom formáte, aby to vyzeralo rovnako
T_out = T;
T_out.Datum = string(T.Datum, 'dd.MM.yyyy');
T_out.Cas   = string(T.Cas,   'hh:mm:ss');
T_out.ts    = string(T.ts,    'dd.MM.yyyy HH:mm:ss');

writetable(T_out, fullfile(outDir,'combined.xlsx'), 'FileType','spreadsheet');

% --- Náhľad ---
disp('✅ Hotovo: results/combined.mat + results/combined.xlsx');
disp(T(1:min(10,height(T)), :));
