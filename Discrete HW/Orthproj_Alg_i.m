clc; clear;

% ===== پارامترهای واقعی سیستم =====
A = [0 1 0;
     0.01 0 1;
     0    0 0];     % a11 = 0 , a21 = 0.01 , a31 = 0
B = [1; 0; 2];       % b1 = 1 , b2 = 0 , b3 = 2
C = [1 0 0];         

% ===== تنظیمات =====
T = 200;
n = 3;
x = zeros(n, T);
y = zeros(1, T);
u = randn(1, T);  % ورودی تحریک تصادفی

% ===== تولید داده خروجی =====
for t = 2:T
    x(:,t) = A * x(:,t-1) + B * u(t-1);
    y(t) = C * x(:,t);
end

% ===== الگوریتم Orthogonal Projection =====
theta_hat = zeros(6, 1);           % [a11; a21; a31; b1; b2; b3]
theta_history = zeros(6, T);
P =1* eye(6);                        % مقدار اولیه P

Phi_all = zeros(6, T-3);           % برای بررسی تحریک پایدار

for t = 4:T
    phi = [y(t-1); y(t-2); y(t-3); u(t-1); u(t-2); u(t-3)];
    phit = phi';
    denom = phit * P * phi;

    % ذخیره بردار phi برای بررسی رتبه
    Phi_all(:, t-3) = phi;

    if abs(denom) > 1e-6
        e = y(t) - phit * theta_hat;
        theta_hat = theta_hat + (P * phi) * (e / denom);
        P = P - (P * phi * phit * P) / denom;
    end

    theta_history(:,t) = theta_hat;
end

% ===== نمایش نتایج نهایی =====
disp('تخمین نهایی پارامترها با Orthogonal Projection:')
disp('theta_hat = [a11; a21; a31; b1; b2; b3]')
disp(theta_hat)

% ===== بررسی 1: همگرایی پارامترها =====
labels = {'a11','a21','a31','b1','b2','b3'};
theta_real = [0; 0.01; 0; 1; 0; 2];

figure;
for i = 1:6
    subplot(3,2,i)
    plot(1:T, theta_history(i,:), 'b', 'LineWidth', 1.5); hold on
    yline(theta_real(i), 'k--', 'LineWidth', 1.2);
    xlabel('Time step'); ylabel(labels{i});
    legend('Estimated','True'); grid on
    title(['تخمین ', labels{i}])
end
sgtitle('بررسی همگرایی پارامترها - Orthogonal Projection')

% ===== بررسی 2: شرط تحریک پایدار =====
rank_phi = rank(Phi_all);
disp(['رتبه ماتریس Phi_all (برای بررسی تحریک پایدار) = ', num2str(rank_phi)])
if rank_phi == 6
    disp(' شرط تحریک پایدار برقرار است.')
else
    disp(' شرط تحریک پایدار برقرار نیست.')
end

% ===== بررسی 3: محدود بودن تخمین‌ها =====
max_vals = max(abs(theta_history'), [], 1);
disp('بیشترین مقدار مطلق هر پارامتر در طول تخمین:')
disp(array2table(max_vals, 'VariableNames', labels))
