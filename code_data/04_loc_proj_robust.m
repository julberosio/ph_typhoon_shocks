%% Load data
clear; clc;
rng(1,"multFibonacci")
merged = readtable('final_merged.csv');
poverty = readtable('poverty.csv');
data = outerjoin(merged, poverty, 'Keys', 'province', 'MergeKeys', true);
data.year_month = datetime(data.year_merged, data.month, 1);
data = data(data.year_month >= datetime(2012,4,1) & data.year_month <= datetime(2024,12,1), :);

%% Parameters
horizons = 0:12;
splits = [10, 20, 30, 40, 50];
nboot = 50;  % Reduce for test runs
H = numel(horizons);
S = numel(splits);

IRF_low_all = nan(H, S, nboot);
IRF_high_all = nan(H, S, nboot);
IRF_gap_mean = nan(H, S);
sig_star = false(H, S);
sig_starstar = false(H, S);

if isempty(gcp('nocreate'))
    parpool('local');  % Adjust if needed
end

%% Main loop for split values
for s = 1:S
    pct = splits(s);
    poverty_2018 = poverty(poverty.year == 2018, :);
    threshold = prctile(poverty_2018.poverty, pct);
    data.poverty_group = repmat("low", height(data), 1);
    for i = 1:height(poverty_2018)
        p = poverty_2018.province{i};
        if poverty_2018.poverty(i) > threshold
            data.poverty_group(strcmp(data.province, p)) = "high";
        end
    end

    for g = ["low", "high"]
        fprintf('\nSplit %d/%d | Group: %s\n', pct, 100 - pct, g);
        D = data(strcmp(data.poverty_group, g), :);
        betas = nan(H, nboot);

        parfor b = 1:nboot
            if mod(b, 20) == 0
                fprintf('  Bootstrap draw %d/%d\n', b, nboot);
            end

            boot_idx = randsample(height(D), height(D), true);
            D_boot = D(boot_idx, :);
            beta_b = nan(H,1);

            for hi = 1:H
                h = horizons(hi);
                lead_tbl = D_boot(:, {'province','year_month','mean_lights'});
                lead_tbl.year_month = lead_tbl.year_month - calmonths(h);
                lead_tbl.Properties.VariableNames{'mean_lights'} = 'y_lead';

                D_h = outerjoin(D_boot, lead_tbl, ...
                    'Keys', {'province','year_month'}, ...
                    'MergeKeys', true, ...
                    'Type', 'left');

                valid = ~isnan(D_h.y_lead) & ~isnan(D_h.exposure);
                if sum(valid) < 10, continue; end

                y = D_h.y_lead(valid);
                % Rebuild dummies inside each bootstrap for size consistency
                [~, ~, prov_id] = unique(D_h.province(valid));
                [~, ~, time_id] = unique(D_h.year_month(valid));
                prov_dummies = dummyvar(prov_id); prov_dummies(:,1) = [];
                time_dummies = dummyvar(time_id); time_dummies(:,1) = [];
                X = [D_h.exposure(valid), prov_dummies, time_dummies];
                X = [ones(size(X,1),1), X];

                if rank(X) < size(X,2), continue; end
                bb = (X' * X) \ (X' * y);
                beta_b(hi) = bb(2);
            end
            betas(:,b) = beta_b;
        end

        if g == "low"
            IRF_low_all(:,s,:) = betas;
        else
            IRF_high_all(:,s,:) = betas;
        end
    end

    % Significance and mean IRF gaps
    gap = squeeze(IRF_high_all(:,s,:) - IRF_low_all(:,s,:));
    IRF_gap_mean(:,s) = mean(gap, 2, 'omitnan');
    CI68 = prctile(gap, [16 84], 2);
    CI90 = prctile(gap, [5 95], 2);
    sig_star(:,s) = CI68(:,1) > 0 | CI68(:,2) < 0;
    sig_starstar(:,s) = CI90(:,1) > 0 | CI90(:,2) < 0;

    fprintf('Done with %d/%d split\n', pct, 100 - pct);
end

%% Plot 3D IRFs
[X, Y] = meshgrid(horizons, splits);
IRF_low_mean = mean(IRF_low_all, 3, 'omitnan');
IRF_high_mean = mean(IRF_high_all, 3, 'omitnan');

% Get (row, col) positions of significance markers
[row, col] = find(sig_starstar);
x_sig = horizons(row);
y_sig = splits(col);

% Get global axis ranges
x_range = [min(horizons), max(horizons)];
y_range = [min(splits), max(splits)];

% Combine all Z data to find common range
all_z = [IRF_low_mean(:); IRF_high_mean(:); IRF_gap_mean(:)];
zmin = floor(min(all_z)*10)/10;
zmax = ceil(max(all_z)*10)/10;
z_range = [zmin, zmax];

%% Low Poverty IRF plot: FIGURE 2
figure('Name','IRF - Low Poverty');
s = surf(X, Y, IRF_low_mean'); colormap(cool); colorbar;
xlabel('Horizon'); ylabel('Split Percentile'); zlabel('IRF');
%title('IRFs - Low Poverty'); 
hold on;
s.EdgeColor = [0.3 0.3 0.3];  % show mesh
s.FaceAlpha = 0.8;            % slight transparency
z_sig = IRF_low_mean(sub2ind(size(IRF_low_mean), row, col));
scatter3(x_sig, y_sig, z_sig, 20, 'k', 'filled');
xlim(x_range); ylim(y_range); zlim(z_range);

set(gcf, 'Units', 'inches');
pos = get(gcf, 'Position');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', pos(3:4));
set(gcf, 'PaperPosition', [0 0 pos(3:4)]);
print(gcf, 'robust_low', '-dpdf', '-painters');

%% High Poverty IRF plot: FIGURE 3
figure('Name','IRF - High Poverty');
s = surf(X, Y, IRF_high_mean'); colormap(cool); colorbar;
xlabel('Horizon'); ylabel('Split Percentile'); zlabel('IRF');
%title('IRFs - High Poverty'); 
hold on;
s.EdgeColor = [0.3 0.3 0.3];
s.FaceAlpha = 0.8;
z_sig = IRF_high_mean(sub2ind(size(IRF_high_mean), row, col));
scatter3(x_sig, y_sig, z_sig, 20, 'k', 'filled');
xlim(x_range); ylim(y_range); zlim(z_range);

set(gcf, 'Units', 'inches');
pos = get(gcf, 'Position');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', pos(3:4));
set(gcf, 'PaperPosition', [0 0 pos(3:4)]);
print(gcf, 'robust_high', '-dpdf', '-painters');

%% Gap IRF plot: FIGURE 4
figure('Name','IRF Gap (High - Low)');
s = surf(X, Y, IRF_gap_mean'); colormap(gray); colorbar;
xlabel('Horizon'); ylabel('Split Percentile'); zlabel('Gap');
%title('IRF Gap: High - Low'); 
hold on;
s.EdgeColor = [0.3 0.3 0.3];
s.FaceAlpha = 0.8;
z_sig = IRF_gap_mean(sub2ind(size(IRF_gap_mean), row, col));
scatter3(x_sig, y_sig, z_sig, 20, 'k', 'filled');
xlim(x_range); ylim(y_range); zlim(z_range);

set(gcf, 'Units', 'inches');
pos = get(gcf, 'Position');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', pos(3:4));
set(gcf, 'PaperPosition', [0 0 pos(3:4)]);
print(gcf, 'robust_gap', '-dpdf', '-painters');

%% Significance table: TABLE 2
disp('--- Gap IRFs with Significance ---');
fprintf('Horizon\t');
for s = 1:S
    fprintf('%d/%d\t', splits(s), 100 - splits(s));
end
fprintf('\n');
for h = 1:H
    fprintf('%d\t', h-1);
    for s = 1:S
        val = IRF_gap_mean(h,s);
        if sig_starstar(h,s)
            star = '**';
        elseif sig_star(h,s)
            star = '*';
        else
            star = '';
        end
        fprintf('%.3f%s\t', val, star);
    end
    fprintf('\n');
end
