%% 0) LAHKÉ ČISTENIE (globálne)
% Predpoklad: T.ts (datetime), T.Intenzita, T.Rychlost

n0 = height(T);

% zoradenie + úplné duplicity
T = sortrows(T,'ts');
T = unique(T,'rows');

% odstrániť riadky s NaN/NaT v kľúčových stĺpcoch
T = T(~(ismissing(T.ts) | isnan(T.Intenzita) | isnan(T.Rychlost)), :);

% veľmi mierne rozsahy (žiadny strop 4000)
INT_LIM = [0 Inf];    % <- nič nerežeme zhora
SPD_LIM = [0 250];

T = T(T.Intenzita >= INT_LIM(1) & T.Intenzita <= INT_LIM(2), :);
T = T(T.Rychlost  >= SPD_LIM(1) & T.Rychlost  <= SPD_LIM(2), :);

% zlúčenie duplicitných časov (priemer)
[tsu,~,~] = unique(T.ts);
if numel(tsu) < height(T)
    G = varfun(@mean, T, 'InputVariables',{'Intenzita','Rychlost'}, ...
                  'GroupingVariables','ts');
    T = table(G.ts, G.mean_Intenzita, G.mean_Rychlost, ...
              'VariableNames',{'ts','Intenzita','Rychlost'});
end

fprintf('Čistenie: %d -> %d riadkov (%.1f %% ostalo)\n', n0, height(T), 100*height(T)/n0);

% workspace directories (nezmenené)
inDirCandidates = { fullfile(pwd,'results'), pwd };
inDir = '';
for c = 1:numel(inDirCandidates)
    if exist(inDirCandidates{c}, 'dir'), inDir = inDirCandidates{c}; break; end
end
if isempty(inDir)
    error('Nenašiel som pracovný priečinok. Skontroluj, že spúšťaš skript z projektu.');
end

%% Graf 1: Porovnanie premávky – august vs. september (hodinové priemery)
Tbl = T;
Tbl.Month = month(T.ts);
Tbl.Hour  = hour(T.ts);

% vyber august a september
MSEL = ismember(Tbl.Month,[8 9]);
G = groupsummary(Tbl(MSEL,:), {'Month','Hour'}, 'mean', {'Intenzita','Rychlost'});
G.Properties.VariableNames = strrep(G.Properties.VariableNames,'mean_','avg_');

h = (0:23).';
I_aug = nan(24,1); V_aug = nan(24,1);
I_sep = nan(24,1); V_sep = nan(24,1);

idx = (G.Month==8);
if any(idx)
    I_aug(G.Hour(idx)+1) = G.avg_Intenzita(idx);
    V_aug(G.Hour(idx)+1) = G.avg_Rychlost(idx);
end

idx = (G.Month==9);
if any(idx)
    I_sep(G.Hour(idx)+1) = G.avg_Intenzita(idx);
    V_sep(G.Hour(idx)+1) = G.avg_Rychlost(idx);
end

% --- Štýlové nastavenie svetlého režimu ---
set(0,'DefaultFigureColor','w');
set(0,'DefaultAxesColor','w');
set(0,'DefaultAxesXColor','k');
set(0,'DefaultAxesYColor','k');
set(0,'DefaultAxesGridColor',[0.4 0.4 0.4]);
set(0,'DefaultAxesMinorGridColor',[0.8 0.8 0.8]);
set(0,'DefaultAxesFontName','Segoe UI');
set(0,'DefaultAxesFontSize',10);

f = figure('Color','w','Name','Porovnanie: august vs september (hodinové priemery)');
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

% Panel 1: Intenzita
nexttile; hold on; grid on; box on;
plot(h, I_aug, '-o', 'LineWidth',1.6, 'MarkerSize',4, 'Color',[0 0.45 0.74], 'DisplayName','August');
plot(h, I_sep, '-o', 'LineWidth',1.6, 'MarkerSize',4, 'Color',[0.85 0.33 0.10], 'DisplayName','September');
xlabel('Hodina dňa','Color','k');
ylabel('Intenzita [vozidlá/h]','Color','k');
title('Hodinové priemery – Intenzita (August vs. September)','Color','k');
xlim([0 23]);
xticks(0:1:23);
lg = legend('Location','best','Box','on','TextColor','k');
lg.Color = [1 1 1];
lg.EdgeColor = [0.7 0.7 0.7];

% Panel 2: Rýchlosť
nexttile; hold on; grid on; box on;
plot(h, V_aug, '-o', 'LineWidth',1.6, 'MarkerSize',4, 'Color',[0 0.45 0.74], 'DisplayName','August');
plot(h, V_sep, '-o', 'LineWidth',1.6, 'MarkerSize',4, 'Color',[0.85 0.33 0.10], 'DisplayName','September');
xlabel('Hodina dňa','Color','k');
ylabel('Rýchlosť [km/h]','Color','k');
title('Hodinové priemery – Rýchlosť (August vs. September)','Color','k');
xlim([0 23]);
xticks(0:1:23);
lg = legend('Location','best','Box','on','TextColor','k');
lg.Color = [1 1 1];
lg.EdgeColor = [0.7 0.7 0.7];

exportgraphics(f, fullfile(outDir,'porovnanie_aug_sep.png'),'Resolution',150);

%% --- Graf 2: Priama závislosť (scatter) ---
f = figure('Color','w','Name','Vzťah intenzity a rýchlosti');
ax = gca;
ax.Color = [1 1 1];
ax.XColor = [0 0 0];
ax.YColor = [0 0 0];
ax.GridColor = [0.4 0.4 0.4];
ax.MinorGridColor = [0.8 0.8 0.8];
ax.FontName = 'Segoe UI';
ax.FontSize = 10;
box on; grid on; hold on;

I = T.Intenzita(:);
V = T.Rychlost(:);

% odstránime NaN, aby nekazili výpočet
m = ~isnan(I) & ~isnan(V);
I = I(m);
V = V(m);

m = ~isnan(T.Intenzita) & ~isnan(T.Rychlost);
scatter(T.Intenzita(m), T.Rychlost(m), 10, 'filled', ...
    'MarkerFaceColor',[0 0.45 0.74], 'MarkerFaceAlpha',0.3, 'MarkerEdgeColor','none');

xlabel('Intenzita [vozidlá/h]','Color','k');
ylabel('Rýchlosť [km/h]','Color','k');
title('Vzťah medzi intenzitou a rýchlosťou dopravy','Color','k');

% Regresná priamka (trend)
p = polyfit(I, V, 1);
xFit = linspace(min(I), max(I), 100);
yFit = polyval(p, xFit);
plot(xFit, yFit, 'k--', 'LineWidth',1.5, 'DisplayName','Trend');

% Legenda – svetlé pozadie, čierny text
lg = legend('Dáta','Trend','Location','best');
lg.TextColor = 'k';
lg.Color = [1 1 1];
lg.EdgeColor = [0.7 0.7 0.7];  % jemný rámik

exportgraphics(f, fullfile(outDir,'intenzita_vs_rychlost_scatter.png'),'Resolution',150);
% nechaj graf otvorený

%% 3)  === DECEMBER: HEATMAP PRIEMERNEJ INTENZITY (deň × hodina) ===

YR  = mode(year(T.ts));
MON = 12;

% 1) len December
isDec = (year(T.ts) == YR) & (month(T.ts) == MON);
Td    = T(isDec, :);

% 2) zarovnanie času na celé hodiny
Td.ts = dateshift(Td.ts, 'start', 'hour');

% 3) pomocné stĺpce
Td.Day  = day(Td.ts);
Td.Hour = hour(Td.ts);
Td.Dow  = weekday(Td.ts);  % 1=Ne, 2=Po, 3=Ut, ...

% 4) agregácia
Gmean = groupsummary(Td, {'Day','Hour'}, 'mean', 'Intenzita');

% 5) plná mriežka
ndays = eomday(YR, MON);
fullGrid = table(repelem((1:ndays).',24), repmat((0:23).',ndays,1), ...
                 'VariableNames', {'Day','Hour'});

% 6) spojenie a pivot
J = outerjoin(fullGrid, Gmean(:,{'Day','Hour','mean_Intenzita'}), ...
              'Keys',{'Day','Hour'}, 'MergeKeys', true);
J = sortrows(J, {'Day','Hour'});
U = unstack(J, 'mean_Intenzita', 'Hour');
M = U{:,2:end};

% 7) pridanie názvov dní v týždni pre každý deň mesiaca
dayNums = (1:ndays).';
dateList = datetime(YR, MON, dayNums);
dayNamesShort = {'Ne','Po','Ut','St','Št','Pi','So'};
yLabels = arrayfun(@(d,w) sprintf('%d (%s)', d, dayNamesShort{w}), ...
                   dayNums, weekday(dateList), 'UniformOutput', false);

% 8) vykreslenie
f = figure('Color','w','Name','December – priemerná intenzita (deň × hodina)');
h = heatmap(0:23, 1:ndays, M);
h.Title  = sprintf('December %d: priemerná intenzita dopravy (deň × hodina)', YR);
h.XLabel = 'Hodina dňa';
h.YLabel = 'Deň v mesiaci';
h.YDisplayLabels = yLabels;   % pridanie názvov dní
h.CellLabelFormat = '%.0f';
h.Colormap = parula;

% chýbajúce dáta
h.MissingDataColor = [0.8 0.8 0.8];
h.MissingDataLabel = 'NaN';
drawnow;
txtNaN = findall(gcf,'Type','Text','String','NaN');
if ~isempty(txtNaN), set(txtNaN,'Color',[0 0 0],'FontWeight','bold'); end

% štýl
ax = struct(h).Axes;
ax.XColor = [0 0 0]; ax.YColor = [0 0 0];
ax.Title.Color = [0 0 0]; ax.XLabel.Color = [0 0 0]; ax.YLabel.Color = [0 0 0];
ax.FontName = 'Segoe UI'; ax.FontSize = 10; ax.FontWeight = 'bold';

cb = struct(h).Colorbar;
cb.Label.String = 'Priemerná intenzita [voz/h]';
cb.Label.Color = [0 0 0];
cb.Color = [0 0 0];
cb.FontSize = 9; cb.FontName = 'Segoe UI';


exportgraphics(f, fullfile(outDir,'december_heatmap.png'), 'Resolution',150);
% nechaj graf otvorený

%% 4) Kĺzavá korelácia intenzita ↔ rýchlosť (30-dňové okno na denných priemeroch)
Td = T;
Td.Day = dateshift(T.ts,'start','day');
Gd = groupsummary(Td, 'Day', 'mean', {'Intenzita','Rychlost'});
Gd.Properties.VariableNames = strrep(Gd.Properties.VariableNames,'mean_','avg_');

I_d = Gd.avg_Intenzita;
V_d = Gd.avg_Rychlost;

win = 30;  % 30-dňové okno
r = NaN(height(Gd),1);

for i = 1:height(Gd)
    a = max(1, i-win+1);
    b = i;
    xi = I_d(a:b);
    yi = V_d(a:b);
    xi = xi(~isnan(xi) & ~isnan(yi));
    yi = yi(~isnan(xi) & ~isnan(yi));
    if numel(xi) >= 5
        % manuálny výpočet korelácie bez toolboxu
        xm = mean(xi);
        ym = mean(yi);
        num = sum((xi - xm) .* (yi - ym));
        den = sqrt(sum((xi - xm).^2) * sum((yi - ym).^2));
        r(i) = num / den;
    end
end

% --- Vykreslenie ---
f = figure('Color','w','Name','Kĺzavá korelácia (30 dní)');
ax = gca;
ax.Color = [1 1 1];
ax.XColor = [0 0 0];
ax.YColor = [0 0 0];
ax.GridColor = [0.4 0.4 0.4];
ax.MinorGridColor = [0.8 0.8 0.8];
ax.FontName = 'Segoe UI';
ax.FontSize = 10;
box on; grid on; hold on;

plot(Gd.Day, r, 'k-', 'LineWidth',1.2);
yline(0,'--','Color',[0.6 0.6 0.6]);
xlabel('Dátum','Color','k');
ylabel('Korelácia (Intenzita vs. Rýchlosť)','Color','k');
title('Kĺzavá korelácia za 30 dní (očakávane záporná)','Color','k');

exportgraphics(f, fullfile(outDir,'rolling_corr_30d.png'), 'Resolution',150);
% nechaj graf otvorený

%% 5) Mesačné a ročné priemery – výpočet a tabuľkový výpis
disp(' ');
disp('=== Mesačné a ročné priemery intenzity a rýchlosti ===');

% --- doplnenie roku a mesiaca ---
T.Year = year(T.ts);
T.Month = month(T.ts);

% --- Mesačné priemery ---
Gm = groupsummary(T, {'Year','Month'}, 'mean', {'Intenzita','Rychlost'});
Gm.Properties.VariableNames = strrep(Gm.Properties.VariableNames,'mean_','avg_');

% --- Ročné priemery ---
Gy = groupsummary(T, {'Year'}, 'mean', {'Intenzita','Rychlost'});
Gy.Properties.VariableNames = strrep(Gy.Properties.VariableNames,'mean_','avg_');

% --- zaokrúhlenie pre prehľadnosť ---
Gm.avg_Intenzita = round(Gm.avg_Intenzita, 1);
Gm.avg_Rychlost  = round(Gm.avg_Rychlost, 1);
Gy.avg_Intenzita = round(Gy.avg_Intenzita, 1);
Gy.avg_Rychlost  = round(Gy.avg_Rychlost, 1);

% --- výpis do konzoly ---
disp(' ');
disp('--- Mesačné priemery (avg_Intenzita [voz/h], avg_Rychlost [km/h]) ---');
disp(Gm(:,{'Year','Month','avg_Intenzita','avg_Rychlost'}));

disp(' ');
disp('--- Ročné priemery (avg_Intenzita [voz/h], avg_Rychlost [km/h]) ---');
disp(Gy(:,{'Year','avg_Intenzita','avg_Rychlost'}));

% --- uloženie do súborov ---
writetable(Gm, fullfile(outDir,'monthly_averages.csv'));
writetable(Gy, fullfile(outDir,'yearly_averages.csv'));
fprintf('\n✅ Uložené: %s a %s\n', ...
    fullfile(outDir,'monthly_averages.csv'), fullfile(outDir,'yearly_averages.csv'));

%% 5b) Rýchle prehľadové štatistiky do konzoly
% Predpoklad: T.ts (datetime), T.Intenzita, T.Rychlost
T.Hour = hour(T.ts);
T.Dow  = weekday(T.ts);         % 1=Ne,2=Po,...,7=So
T.IsWknd = ismember(T.Dow,[1 7]);

% --- definície intervalov (uprav podľa seba) ---
isNight   = T.Hour>=22 | T.Hour<=5;        % 22:00–05:59
isDay     = T.Hour>=6  & T.Hour<=21;       % 06:00–21:59
isAMPeak  = T.Hour>=7  & T.Hour<=9;        % ranná špička
isPMPeak  = T.Hour>=15 & T.Hour<=18;       % popoludňajšia špička
isMidday  = T.Hour>=10 & T.Hour<=14;       % stred dňa
isEvening = T.Hour>=19 & T.Hour<=21;       % večer

% --- helper na bezpečné priemery (ignoruje NaN) ---
m = @(x) mean(x,'omitnan');

% 1) Základné prehľady rýchlosti a intenzity
avgSpeedNight = m(T.Rychlost(isNight));
avgSpeedDay   = m(T.Rychlost(isDay));
avgIntNight   = m(T.Intenzita(isNight));
avgIntDay     = m(T.Intenzita(isDay));

% 2) Špičky
avgIntAMPeak  = m(T.Intenzita(isAMPeak));
avgSpdAMPeak  = m(T.Rychlost(isAMPeak));
avgIntPMPeak  = m(T.Intenzita(isPMPeak));
avgSpdPMPeak  = m(T.Rychlost(isPMPeak));

% 3) Víkend vs. pracovné dni
avgIntWeekday = m(T.Intenzita(~T.IsWknd));
avgIntWeekend = m(T.Intenzita( T.IsWknd));
avgSpdWeekday = m(T.Rychlost(~T.IsWknd));
avgSpdWeekend = m(T.Rychlost( T.IsWknd));

% 4) Najrušnejšie / najtichšie hodiny v priemere (naprieč celým obdobím)
Ghour = groupsummary(T,'Hour','mean',{'Intenzita','Rychlost'});
Ghour.Properties.VariableNames = strrep(Ghour.Properties.VariableNames,'mean_','avg_');
[~,ordBusy]   = sort(Ghour.avg_Intenzita,'descend');
[~,ordQuiet]  = sort(Ghour.avg_Intenzita,'ascend');
topK = 5;   % koľko zobraziť
busyTop  = Ghour(ordBusy(1:min(topK,height(Ghour))),:);
quietTop = Ghour(ordQuiet(1:min(topK,height(Ghour))),:);

% 5) „Free flow" vs. „zahustené" podmienky
thFree  = 1000;   % <1000 voz/h
thCong  = 3000;   % >3000 voz/h
avgSpdFree = m(T.Rychlost(T.Intenzita < thFree));
avgSpdCong = m(T.Rychlost(T.Intenzita > thCong));
shareCong  = mean(T.Intenzita > thCong,'omitnan')*100;

% 6) Korelácia intenzita ↔ rýchlosť (Pearson)
valid = ~isnan(T.Intenzita) & ~isnan(T.Rychlost);
x = T.Intenzita(valid);
y = T.Rychlost(valid);
x = x - mean(x, 'omitnan');
y = y - mean(y, 'omitnan');
corrIV = sum(x .* y, 'omitnan') / sqrt(sum(x.^2, 'omitnan') * sum(y.^2, 'omitnan'));

% 7) Najsilnejší a najslabší mesiac (podľa priemernej intenzity)
Gm2 = groupsummary(T,{'Year','Month'},'mean','Intenzita');
Gm2.Properties.VariableNames = strrep(Gm2.Properties.VariableNames,'mean_','avg_');
[~,imax] = max(Gm2.avg_Intenzita);
[~,imin] = min(Gm2.avg_Intenzita);
moNames = {'Jan','Feb','Mar','Apr','Máj','Jún','Júl','Aug','Sep','Okt','Nov','Dec'};

% 8) December – pracovné dni vs. víkend (ak dáta sú)
if any(month(T.ts)==12)
    isDec = month(T.ts)==12;
    Tdec = T(isDec,:);
    dIntWkday = m(Tdec.Intenzita(~Tdec.IsWknd));
    dIntWknd  = m(Tdec.Intenzita( Tdec.IsWknd));
else
    dIntWkday = NaN; dIntWknd = NaN;
end

%% --- Výpisy do konzoly ---
fprintf('\n=== RÝCHLE PREHĽADY (globálne cez celé obdobie) ===\n');
fprintf('• Priemerná rýchlosť v noci (22–05):     %.2f km/h\n', avgSpeedNight);
fprintf('• Priemerná rýchlosť cez deň (06–21):   %.2f km/h\n', avgSpeedDay);
fprintf('• Priemerná intenzita v noci (22–05):   %.0f voz/h\n', avgIntNight);
fprintf('• Priemerná intenzita cez deň (06–21):  %.0f voz/h\n', avgIntDay);

fprintf('\n— Špičky —\n');
fprintf('• Ranná špička (07–09) – intenzita: %.0f, rýchlosť: %.2f km/h\n', avgIntAMPeak, avgSpdAMPeak);
fprintf('• Popoludňajšia špička (15–18) – intenzita: %.0f, rýchlosť: %.2f km/h\n', avgIntPMPeak, avgSpdPMPeak);

fprintf('\n— Pracovné dni vs. víkend —\n');
fprintf('• Pracovné dni – intenzita: %.0f, rýchlosť: %.2f km/h\n', avgIntWeekday, avgSpdWeekday);
fprintf('• Víkend       – intenzita: %.0f, rýchlosť: %.2f km/h\n', avgIntWeekend, avgSpdWeekend);

fprintf('\n— Najrušnejšie hodiny (TOP %d podľa priemernej intenzity) —\n', topK);
disp(busyTop(:,{'Hour','avg_Intenzita','avg_Rychlost'}));

fprintf('— Najtichšie hodiny (TOP %d podľa priemernej intenzity) —\n', topK);
disp(quietTop(:,{'Hour','avg_Intenzita','avg_Rychlost'}));

fprintf('— Režimy prevádzky —\n');
fprintf('• Priemerná rýchlosť pri nízkej intenzite (<%d):  %.2f km/h\n', thFree, avgSpdFree);
fprintf('• Priemerná rýchlosť pri vysokej intenzite (>%d): %.2f km/h\n', thCong, avgSpdCong);
fprintf('• Podiel hodín s vys. intenzitou (>%d):           %.1f %%\n', thCong, shareCong);

fprintf('\n— Vzťah intenzita ↔ rýchlosť —\n');
fprintf('• Pearsonova korelácia: %.3f (záporná znamená, že vyššia intenzita = nižšia rýchlosť)\n', corrIV);

fprintf('\n— Mesiace —\n');
fprintf('• Najsilnejší mesiac: %s %d (%.0f voz/h)\n', moNames{Gm2.Month(imax)}, Gm2.Year(imax), Gm2.avg_Intenzita(imax));
fprintf('• Najslabší  mesiac: %s %d (%.0f voz/h)\n', moNames{Gm2.Month(imin)}, Gm2.Year(imin), Gm2.avg_Intenzita(imin));

fprintf('\n— December —\n');
fprintf('• Priemerná intenzita – pracovné dni: %.0f, víkend: %.0f\n', dIntWkday, dIntWknd);
fprintf('====================================================\n\n');
