clc; clear;

% ==== پارامترهای شبیه‌سازی ====
dt = 0.05;
T_total = 12;
N = T_total / dt;
t_vec = (0:N-1) * dt;
u = randn(1, N);
x = zeros(3, N);
y = zeros(1, N);

% ==== تعریف ضرایب زمان‌متغیر ====
get_a11 = @(t) (t <= 3) * 0 + (t > 3 & t <= 6) * 0.1 + (t > 6 & t <= 9) * 0 + (t > 9 & t <= 12) * 0.1;
get_a21 = @(t) (t <= 3) * -0.1 + (t > 3 & t <= 6) * 0 + (t > 6 & t <= 9) * 0.1 + (t > 9 & t <= 12) * 0;
get_a31 = @(t) (t <= 3) * 0 + (t > 3 & t <= 6) * -0.2 + (t > 6 & t <= 9) * 0 + (t > 9 & t <= 12) * -0.1;

% ==== ذخیره مقادیر واقعی ضرایب ====
a_true = zeros(3,N);
for t = 1:N
    t_sec = t_vec(t);
    a_true(1,t) = get_a11(t_sec);
    a_true(2,t) = get_a21(t_sec);
    a_true(3,t) = get_a31(t_sec);
end

% ==== شبیه‌سازی سیستم ====
for t = 2:N
    t_sec = t_vec(t);
    A = [get_a11(t_sec), 1, 0;
         get_a21(t_sec), 0, 1;
         get_a31(t_sec), 0, 0];
    B = [1; 0; 2];
    x(:,t) = A * x(:,t-1) + B * u(t-1);
    y(t) = x(1,t);
end

% ==== تخمین پارامترها ====
m = 6;
theta_rls = zeros(m, N);
theta_proj = zeros(m, N);
theta_orth = zeros(m, N);

P_rls = 100 * eye(m);
P_proj = 100 * eye(m);
proj_thresh = 10;

theta_r = zeros(m,1);
theta_p = zeros(m,1);
theta_o = zeros(m,1);

for t = 4:N
    phi = [y(t-1); y(t-2); y(t-3); u(t-1); u(t-2); u(t-3)];
    phit = phi';
   

    % ==== Projection ====
    if norm(phi) <= proj_thresh
        e_p = y(t) - phit * theta_p;
        K_p = (P_proj * phi) / (1 + phit * P_proj * phi);
        theta_p = theta_p + K_p * e_p;
        P_proj = P_proj - K_p * phit * P_proj;
    end
    theta_proj(:,t) = theta_p;

    % ==== Orthogonal Projection ====
    phi_norm2 = phi' * phi;
    if phi_norm2 > 1e-6
        e_o = y(t) - phit * theta_o;
        theta_o = theta_o + phi * (e_o / phi_norm2);
    end
    theta_orth(:,t) = theta_o;
end
    % ==== RLS ====
    e_r = y(t) - phit * theta_r;
    K_r = (P_rls * phi) / (1 + phit * P_rls * phi);
    theta_r = theta_r + K_r * e_r;
    P_rls = P_rls - K_r * phit * P_rls;
    theta_rls(:,t) = theta_r;
    

% ======================
% ==== رسم نتایج =======
% فقط پارامترهای a11, a21, a31 (اندیس 1 تا 3)
labels = {'a11','a21','a31'};
algorithms = { 'Projection', 'Orthogonal Projection'};
estimates = { theta_proj, theta_orth};
colors = { 'r', 'g'};

for alg = 1:2
    figure;
    for i = 1:3
        subplot(3,1,i)
        plot(t_vec, estimates{alg}(i,:), colors{alg}, 'LineWidth', 1.5, 'DisplayName', algorithms{alg}); hold on
        plot(t_vec, a_true(i,:), 'k--', 'LineWidth', 1.2, 'DisplayName', 'True');
        ylabel(['\theta_{', labels{i}, '}']);
        xlabel('Time (s)');
        legend('Location', 'best');
        grid on;
    end
    sgtitle(['تخمین ضرایب a با الگوریتم ', algorithms{alg}])
end
% ==== رسم نتایج برای RLS معمولی ====
figure;
for i = 1:3
    subplot(3,1,i)
    plot(t_vec, theta_rls(i,:), 'b', 'LineWidth', 1.5, 'DisplayName', 'RLS'); hold on
    plot(t_vec, a_true(i,:), 'k--', 'LineWidth', 1.2, 'DisplayName', 'True');
    ylabel(['\theta_{', labels{i}, '}']);
    xlabel('Time (s)');
    legend('Location', 'best');
    grid on;
    title(['تخمین ', labels{i}, ' با الگوریتم RLS']);
end
sgtitle('مقایسه پارامترهای a با الگوریتم RLS معمولی');


clc; clear;

% ==== پارامترهای شبیه‌سازی ====
dt = 0.05;
T_total = 12;
N = T_total / dt;
t_vec = (0:N-1) * dt;
u = randn(1, N);
x = zeros(3, N);
y = zeros(1, N);

% ==== تعریف ضرایب زمان‌متغیر ====
get_a11 = @(t) (t <= 3) * 0 + (t > 3 & t <= 6) * 0.1 + (t > 6 & t <= 9) * 0 + (t > 9 & t <= 12) * 0.1;
get_a21 = @(t) (t <= 3) * -0.1 + (t > 3 & t <= 6) * 0 + (t > 6 & t <= 9) * 0.1 + (t > 9 & t <= 12) * 0;
get_a31 = @(t) (t <= 3) * 0 + (t > 3 & t <= 6) * -0.2 + (t > 6 & t <= 9) * 0 + (t > 9 & t <= 12) * -0.1;

% ==== ذخیره ضرایب واقعی ====
a_true = zeros(3,N);
for t = 1:N
    t_sec = t_vec(t);
    a_true(1,t) = get_a11(t_sec);
    a_true(2,t) = get_a21(t_sec);
    a_true(3,t) = get_a31(t_sec);
end

% ==== شبیه‌سازی سیستم ====
for t = 2:N
    t_sec = t_vec(t);
    A = [get_a11(t_sec), 1, 0;
         get_a21(t_sec), 0, 1;
         get_a31(t_sec), 0, 0];
    B = [1; 0; 2];
    x(:,t) = A * x(:,t-1) + B * u(t-1);
    y(t) = x(1,t);
end

% ==== پارامترهای اولیه تخمین ====
m = 6;
theta_sel = zeros(m,1);      % Modified RLS با وزن‌دهی Selective
P_sel = 100 * eye(m);
epsilon = 0.01; k1 = 1; k2 = 0.001;

theta_exp = zeros(m,1);      % RLS وزن‌دهی نمایی
P_exp = 100 * eye(m);
lambda = 0.99;               % ضریب فراموشی

theta_rst = zeros(m,1);      % RLS با Reset دوره‌ای
P_rst = 100 * eye(m);
reset_interval = 50;         % تعداد نمونه‌های بین هر Reset

% ماتریس‌ها برای ذخیره تخمین‌ها
theta_history_sel = zeros(m,N);
theta_history_exp = zeros(m,N);
theta_history_rst = zeros(m,N);

for t = 4:N
    phi = [y(t-1); y(t-2); y(t-3); u(t-1); u(t-2); u(t-3)];
    phit = phi';
    y_t = y(t);

    % ===== Modified RLS با وزن‌دهی Selective =====
    phi_P_phi = phit * P_sel * phi;
    if phi_P_phi >= epsilon
        a = k1;
    else
        a = k2;
    end
    e_sel = y_t - phit * theta_sel;
    denom_sel = 1 + a * phi_P_phi;
    theta_sel = theta_sel + a * (P_sel * phi) * (e_sel / denom_sel);
    P_sel = P_sel - a * (P_sel * phi * phit * P_sel) / denom_sel;
    theta_history_sel(:,t) = theta_sel;

    % ===== RLS با وزن‌دهی نمایی =====
    e_exp = y_t - phit * theta_exp;
    K_exp = (P_exp * phi) / (lambda + phit * P_exp * phi);
    theta_exp = theta_exp + K_exp * e_exp;
    P_exp = (P_exp - K_exp * phit * P_exp) / lambda;
    theta_history_exp(:,t) = theta_exp;

    % ===== RLS با Reset دوره‌ای =====
    e_rst = y_t - phit * theta_rst;
    K_rst = (P_rst * phi) / (1 + phit * P_rst * phi);
    theta_rst = theta_rst + K_rst * e_rst;
    P_rst = P_rst - K_rst * phit * P_rst;
    % Reset ماتریس کوواریانس هر reset_interval نمونه
    if mod(t, reset_interval) == 0
        P_rst = 100 * eye(m);
    end
    theta_history_rst(:,t) = theta_rst;
end
labels = {'a11','a21','a31'};

% آرایه تخمین‌ها برای راحتی دسترسی
theta_histories = {theta_history_sel, theta_history_exp, theta_history_rst};
alg_names = {'Modified RLS (Selective Weighting)', 'Exponentially Weighted RLS', 'RLS with Covariance Reset'};

for alg = 1:3
    figure;
    for i = 1:3
        subplot(3,1,i)
        plot(t_vec, theta_histories{alg}(i,:), 'LineWidth', 1.5, 'DisplayName', alg_names{alg}); hold on
        plot(t_vec, a_true(i,:), 'k--', 'LineWidth', 1.2, 'DisplayName', 'True');
        ylabel(['\theta_{', labels{i}, '}']);
        xlabel('Time (s)');
        legend('Location','best');
        grid on;
        title(['تخمین ', labels{i}])
    end
    sgtitle(['مقایسه پارامترهای a با الگوریتم ', alg_names{alg}])
end
% ==== RLS with Covariance Modification ====
theta_covmod = zeros(m,1);
P_covmod = 100 * eye(m);
theta_history_covmod = zeros(m,N);

% پارامترهای Q
q_base = 1e-2;        % مقدار پایه Q
q_gain = 80;          % تقویت Q نسبت به خطا

for t = 4:N
    phi = [y(t-1); y(t-2); y(t-3); u(t-1); u(t-2); u(t-3)];
    phit = phi';
    y_t = y(t);

    % ---- مرحله اول: محاسبه خطا و Ptilda ----
    e_cov = y_t - phit * theta_covmod;
    phi_P_phi = phit * P_covmod * phi;
    denom_cov = 1 + phi_P_phi;

    K_cov = P_covmod * phi / denom_cov;
    theta_covmod = theta_covmod + K_cov * e_cov;

    P_tilda = P_covmod - K_cov * phit * P_covmod;

    % ---- مرحله دوم: تنظیم Q بر اساس بزرگی خطا ----
    % اگر خطا بزرگ بود، Q هم بزرگ بشه
    Q_t = q_base * (1 + q_gain * min(e_cov^2, 100));  % محدودش کردیم تا واگرا نشه
    Q_mat = Q_t * eye(m);

    % ---- مرحله سوم: به‌روزرسانی P ----
    P_covmod = P_tilda + Q_mat;

    % ---- ذخیره تخمین ----
    theta_history_covmod(:,t) = theta_covmod;
end
% ==== رسم نمودار الگوریتم RLS-CovMod ====
figure;
labels = {'a_{11}','a_{21}','a_{31}'};

for i = 1:3
    subplot(3,1,i)
    plot(t_vec, theta_history_covmod(i,:), 'm', 'LineWidth', 1.5); hold on
    plot(t_vec, a_true(i,:), 'k--', 'LineWidth', 1.2);  % مقدار واقعی
    xlabel('Time (s)')
    ylabel(labels{i})
    legend('Estimated (CovMod)', 'True')
    grid on
    title(['تخمین ', labels{i}, ' با RLS + Covariance Modification'])
end

sgtitle('مقایسه پارامترهای a با الگوریتم RLS با اصلاح ماتریس کوواریانس')
