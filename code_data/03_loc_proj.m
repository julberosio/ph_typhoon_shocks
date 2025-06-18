%% Load data
clear; clc;
rng(1,"multFibonacci")
merged = readtable('final_merged.csv');
poverty = readtable('poverty.csv');

%% Merge poverty data
data = outerjoin(merged, poverty, 'Keys', 'province', 'MergeKeys', true);
data.year_month = datetime(data.year_merged, data.month, 1);
data = data(data.year_month >= datetime(2012,4,1) & data.year_month <= datetime(2024,12,1), :);

%% Define poverty split (2018)
poverty_2018 = poverty(poverty.year == 2018, :);
poverty_thresh = median(poverty_2018.poverty, 'omitnan');
data.poverty_group = repmat("low", height(data), 1);

for i = 1:height(poverty_2018)
    p = poverty_2018.province{i};
    if poverty_2018.poverty(i) > poverty_thresh
        data.poverty_group(strcmp(data.province, p)) = "high";
    end
end

%% Parameters
max_horizon = 12;
groups = ["low", "high"];
nboot = 500;
results = struct();

%% Local projections with bootstraps
for g = 1:length(groups)
    grp = groups(g);
    D = data(strcmp(data.poverty_group, grp), :);
    
    betas = nan(max_horizon+1,1);
    boot_all = nan(max_horizon+1, nboot);
    
    for h = 0:max_horizon
        D_h = D;
        D_h.y_lead = NaN(height(D_h),1);
        
        for i = 1:height(D_h)
            t = D_h.year_month(i);
            p = D_h.province{i};
            idx = strcmp(D_h.province, p) & D_h.year_month == t + calmonths(h);
            if any(idx)
                D_h.y_lead(i) = D_h.mean_lights(find(idx,1));
            end
        end

        regdata = D_h(~isnan(D_h.y_lead) & ~isnan(D_h.exposure), :);
        if height(regdata) < 10
            continue
        end

        % Fixed effects
        [~, ~, prov_id] = unique(regdata.province);
        [~, ~, time_id] = unique(regdata.year_month);
        prov_dummies = dummyvar(prov_id); prov_dummies(:,1) = [];
        time_dummies = dummyvar(time_id); time_dummies(:,1) = [];
        X = [regdata.exposure, prov_dummies, time_dummies];
        X = [ones(size(X,1),1), X];
        y = regdata.y_lead;

        b = (X' * X) \ (X' * y);
        betas(h+1) = b(2);

        % Bootstrap
        boots = nan(nboot,1);
        for b_idx = 1:nboot
            if mod(b, 50) == 0
                fprintf('  Bootstrap draw %d/%d\n', b, nboot);
            end

            boot_idx = randsample(height(regdata), height(regdata), true);
            regdata_b = regdata(boot_idx, :);

            [~, ~, prov_id_b] = unique(regdata_b.province);
            [~, ~, time_id_b] = unique(regdata_b.year_month);
            prov_dummies_b = dummyvar(prov_id_b); prov_dummies_b(:,1) = [];
            time_dummies_b = dummyvar(time_id_b); time_dummies_b(:,1) = [];
            Xb = [regdata_b.exposure, prov_dummies_b, time_dummies_b];
            Xb = [ones(size(Xb,1),1), Xb];
            yb = regdata_b.y_lead;

            if rank(Xb) < size(Xb,2)
                continue
            end

            bb = (Xb' * Xb) \ (Xb' * yb);
            boots(b_idx) = bb(2);
        end

        boot_all(h+1,:) = boots;
    end

    results.(grp).beta = betas;
    results.(grp).boot = boot_all;
end

%% Compute gap IRF + bootstrap confidence intervals
gap_irf = results.high.beta - results.low.beta;
gap_boot = results.high.boot - results.low.boot;

ci_gap_90 = nan(max_horizon+1, 2);
ci_gap_68 = nan(max_horizon+1, 2);

for h = 1:max_horizon+1
    dist = gap_boot(h, :);
    dist = dist(~isnan(dist));
    if isempty(dist), continue; end
    ci_gap_90(h,:) = quantile(dist, [0.05 0.95]);
    ci_gap_68(h,:) = quantile(dist, [0.16 0.84]);
end

ci_low_68 = nan(max_horizon+1, 2);
ci_high_68 = nan(max_horizon+1, 2);
for h = 1:max_horizon+1
    ci_low_68(h,:) = quantile(results.low.boot(h, :), [0.16, 0.84]);
    ci_high_68(h,:) = quantile(results.high.boot(h, :), [0.16, 0.84]);
end

%% Plot IRFs: FIGURE 1
h = 0:max_horizon;
figure;

% Determine common y-limits across both plots
all_vals = [results.low.beta; results.high.beta; gap_irf(:); ci_gap_90(:)];
ymin = floor(min(all_vals)*10)/10;
ymax = ceil(max(all_vals)*10)/10;

subplot(1,2,1); hold on;

% Shaded 68% CI for low poverty
fill([h fliplr(h)], [ci_low_68(:,2)' fliplr(ci_low_68(:,1)')], ...
    [0.6 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

% Line for low poverty
plot(h, results.low.beta, 'b-', 'LineWidth', 2);

% Shaded 68% CI for high poverty
fill([h fliplr(h)], [ci_high_68(:,2)' fliplr(ci_high_68(:,1)')], ...
    [1 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

% Line for high poverty
plot(h, results.high.beta, 'r--', 'LineWidth', 2);

% Line for low poverty
low_line = plot(h, results.low.beta, 'b-', 'LineWidth', 2);

% Line for high poverty
high_line = plot(h, results.high.beta, 'r--', 'LineWidth', 2);

% Legend (include only line handles, exclude fills)
legend([low_line, high_line], {'Low Poverty', 'High Poverty'}, 'Location', 'Best');

yline(0, '--', 'HandleVisibility','off');
xlabel('Horizon (months)');
ylabel('Response of Mean Lights');
ylim([ymin, ymax]);
grid off;

% Save figure
set(gcf, 'Units', 'inches');
pos = get(gcf, 'Position');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', pos(3:4));
set(gcf, 'PaperPosition', [0 0 pos(3:4)]);
print(gcf, 'baseline_gap_', '-dpdf', '-painters');

subplot(1,2,2); hold on;
plot(h, gap_irf, 'k-', 'LineWidth', 2);
fill([h fliplr(h)], [ci_gap_90(:,2)' fliplr(ci_gap_90(:,1)')], [0.8 0.8 0.8], ...
    'EdgeColor','none','FaceAlpha',0.3);
yline(0, '--');
xlabel('Horizon (months)'); ylabel('Gap (High - Low)');
ylim([ymin, ymax]);
grid off;

% Save figure
set(gcf, 'Units', 'inches');
pos = get(gcf, 'Position');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', pos(3:4));
set(gcf, 'PaperPosition', [0 0 pos(3:4)]);
print(gcf, 'baseline_gap_', '-dpdf', '-painters');

%% Significance table: TABLE 1
disp('--- Gap IRFs with Significance ---');
table3 = strings(max_horizon+1,1);

for t = 1:max_horizon+1
    gap = gap_irf(t);
    ci90 = ci_gap_90(t,:);
    ci68 = ci_gap_68(t,:);

    if all(ci90 > 0) || all(ci90 < 0)
        star = '**';
    elseif all(ci68 > 0) || all(ci68 < 0)
        star = '*';
    else
        star = '';
    end

    table3(t) = sprintf('%.3f%s', gap, star);
end

fprintf('Horizon\tGap (High - Low)\n');
for t = 1:max_horizon+1
    fprintf('%d\t%s\n', t-1, table3(t));
end
