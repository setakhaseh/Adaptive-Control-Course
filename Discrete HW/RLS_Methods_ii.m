

% .....Modified RLS with Selective Data Weighting.....

clc; clear; close all;

% ===== پارامترهای واقعی =====
A = [0 1 0;
     0.01 0 1;
     0    0 0];
B = [1; 0; 2];
C = [1 0 0];

% ===== تنظیمات =====
T = 200;             % طول زمان
n = 3;               % تعداد حالت‌ها
x = zeros(n, T);     % بردار حالت
y = zeros(1, T);     % خروجی
u = randn(1, T);     % ورودی تصادفی گاوسی

% ===== تولید داده خروجی =====
for t = 2:T
    x(:,t) = A * x(:,t-1) + B * u(t-1);
    y(t) = C * x(:,t);
end

% ===== تنظیمات الگوریتم RLS =====
theta_hat = zeros(6, 1);       % بردار تخمین پارامترها: [a11; a21; a31; b11; b12; b13]
theta_history = zeros(6, T);   % ذخیره تاریخچه پارامترها
P = 100 * eye(6);              % ماتریس کوواریانس اولیه

% ===== پارامترهای وزن‌دهی Selective =====
epsilon = 0.01;
k1 = 1;
k2 = 0.001;

% ===== اجرای الگوریتم  =====
for t = 4:T
    % بردار رگرسیون φ(t-1)
    phi = [y(t-1); y(t-2); y(t-3); u(t-1); u(t-2); u(t-3)];
    phit = phi';

    % بررسی اهمیت داده
    phi_P_phi = phit * P * phi;
    if phi_P_phi >= epsilon
        a = k1;
    else
        a = k2;
    end

    % خطای پیش‌بینی
    e = y(t) - phit * theta_hat;

    % مخرج بهینه‌شده با وزن
    denom = 1 + a * phi_P_phi;

    % آپدیت θ
    theta_hat = theta_hat + a * (P * phi) * (e / denom);

    % آپدیت ماتریس کوواریانس
    P = P - a * (P * phi * phit * P) / denom;

    % ذخیره تخمین‌ها
    theta_history(:,t) = theta_hat;
end

% ===== نمایش خروجی =====
disp('تخمین نهایی پارامترها با Modified RLS (Selective Weighting):')
disp('theta_hat = [a11; a21; a31; b11; b12; b13]')
disp(theta_hat)

% ===== رسم پارامترهای تخمینی  =====
figure;
plot(theta_history', 'LineWidth', 1.5);
legend({'\theta_1 (a11)', '\theta_2 (a21)', '\theta_3 (a31)', ...
        '\theta_4 (b11)', '\theta_5 (b12)', '\theta_6 (b13)'}, ...
        'Location', 'best');
xlabel('Time Step');
ylabel('\theta estimate');
title('RLS with Selective Data Weighting');
grid on;



%.....modified RLS with exponential data weighting.....
% ===== پارامترهای واقعی =====
A = [0 1 0;
     0.01 0 1;
     0    0 0];
B = [1; 0; 2];
C = [1 0 0];

% ===== تنظیمات =====
T = 300;
n = 3;
x = zeros(n, T);
y = zeros(1, T);
u = randn(1, T);   % ورودی تصادفی

% ===== تولید داده =====
for t = 2:T
    x(:,t) = A * x(:,t-1) + B * u(t-1);
    y(t) = C * x(:,t);
end

% ===== مقداردهی اولیه =====
theta_hat = zeros(6, T);
P = zeros(6, 6, T+1);             % P از -1 تا T-1 → P(:,:,1) ≡ P(-1)
P(:,:,1) = 100 * eye(6);          % P(-1)
alpha = zeros(1, T);
alpha(1) = 0.7;                  % alpha(0)
alpha0 = 0.99;
eps_safe = 1e-6;

% ===== اجرای الگوریتم =====
for t = 1:T-1
    % phi(t-1)  برای t=1 یعنی phi(0)
    if t < 4
        phi = zeros(6,1); % چون y(t-1), y(t-2), y(t-3) نداریم
    else
        phi = [y(t); y(t-1); y(t-2); u(t); u(t-1); u(t-2)];
    end
    phit = phi';

    % مخرج
    denom = alpha(t) + phit * P(:,:,t) * phi;


    % آپدیت P(t)
    P(:,:,t+1) = (1/alpha(t)) * ...
        (P(:,:,t) - (P(:,:,t) * phi * phit * P(:,:,t)) / denom);

    % خطای پیش‌بینی
    y_pred = phit * theta_hat(:,t);
    e = y(t+1) - y_pred;

    % آپدیت θ(t+1)
    theta_hat(:,t+1) = theta_hat(:,t) + (P(:,:,t+1) * phi) * (e / denom);

    % آپدیت α(t+1)
    alpha(t+1) = alpha0 * alpha(t) + (1 - alpha0);
end

% ===== نمایش =====
disp('تخمین نهایی پارامترها با Exp-Weighted RLS :')
disp('theta_hat = [a11; a21; a31; b11; b12; b13]')
disp(theta_hat(:,end)')

% ===== رسم =====
figure;
plot(theta_hat');
xlabel('زمان');
ylabel('تخمین پارامتر');
title('روند همگرایی پارامترها در Exp-Weighted RLS');
legend('\theta_1','\theta_2','\theta_3','\theta_4','\theta_5','\theta_6');
grid on;
%.....modified RLS with covariance resetting.....

% ===== پارامترهای واقعی =====
A = [0 1 0;
     0.01 0 1;
     0    0 0];
B = [1; 0; 2];
C = [1 0 0];

% ===== تنظیمات =====
T = 200;
n = 3;
x = zeros(n, T);
y = zeros(1, T);
u = randn(1, T);   % ورودی تصادفی

% ===== تولید داده =====
for t = 2:T
    x(:,t) = A * x(:,t-1) + B * u(t-1);
    y(t) = C * x(:,t);
end

% ===== تنظیمات الگوریتم =====
theta_hat = zeros(6, T);
P = zeros(6,6,T+1);     % P(:,:,1) ≡ P(-1)
K0 = 1000;              % مقدار اولیه بزرگ
P(:,:,1) = K0 * eye(6); 
reset_period = 30;      % دوره‌ی بازتنظیم کوواریانس

eps_safe = 1e-6;

% ===== اجرای الگوریتم =====
for t = 2:T
    % φ(t-1)
    if t < 4
        phi = zeros(6,1);  % چون داده‌های کافی نداریم
    else
        phi = [y(t-1); y(t-2); y(t-3); u(t-1); u(t-2); u(t-3)];
    end
    phit = phi';

    % استفاده از P(t-2)
    P_prev2 = P(:,:,t-1);
    theta_prev = theta_hat(:,t-1);

    % مخرج
    denom = 1 + phit * P_prev2 * phi;


    % خطای پیش‌بینی
    e = y(t) - phit * theta_prev;

    % آپدیت θ
    theta_hat(:,t) = theta_prev + (P_prev2 * phi) * (e / denom);

    % بازتنظیم کوواریانس در بازه‌های مشخص
    if mod(t, reset_period) == 0
        P(:,:,t) = K0 * eye(6);    % ریست
    else
        P(:,:,t) = P_prev2 - (P_prev2 * phi * phit * P_prev2) / denom;
    end
end

% ===== نمایش خروجی =====
disp('تخمین نهایی پارامترها با RLS (Covariance Resetting):')
disp('theta_hat = [a11; a21; a31; b11; b12; b13]')
disp(theta_hat(:,end)')

% ===== رسم =====
figure;
plot(theta_hat');
xlabel('زمان');
ylabel('تخمین پارامتر');
title('RLS covariance resetting');
legend('\theta_1','\theta_2','\theta_3','\theta_4','\theta_5','\theta_6');
grid on;
